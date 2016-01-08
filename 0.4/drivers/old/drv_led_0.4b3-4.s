; minimOS 0.4b4 LED Keypad driver, 6502 SDx
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.05.06

#define _kp_size	1
#define _led_digits	4

; *** begins with sub-function addresses table ***
	.word	led_reset	; initialize device and appropiate sysvars, called by POST only
	.word	led_get		; poll, read keypad into buffer (called by ISR)
	.word	ledg_rts	; req, his one can't generate IRQs, thus SEC+RTS
	.word	led_cin		; cin, input from buffer
	.word	led_cout	; cout, output to display
	.word	ledg_rts	; NEW, 1-sec, no need for 1-second interrupt
	.word	ledg_rts	; NEW, sin, no block input
	.word	ledg_rts	; NEW, sout, no block output
	.word	ledg_rts	; NEWER, bye, no shutdown procedure
	.byt	%10110000	; poll, no req., I/O, no 1-sec and neither block transfers, non relocatable (NEWEST HERE)
	.byt	0		; reserved for new 20-byte block

; *** output ***
led_cout:
	LDA z2			; get char in case is control
	CMP #13			; carriage return? (shouldn't just clear, but wait for next char instead...)
	BEQ led_blank		; if so, clear LED display
	CMP #10			; LF clears too
	BEQ led_blank
	CMP #12			; FF clears too
	BNE led_no_clear	; else, do print
led_blank:
	LDX led_len		; display size
led_clear:
	DEX
	_STZA led_buf, X
	BNE led_clear		; loops until all clear
	_STZA led_pos		; STZ, reset cursor -- not STA
	_EXIT_OK
led_no_clear:
	CMP #8			; backspace?
	BNE led_no_bs
	LDX led_pos		; gets cursor position
	BEQ led_end		; nothing to delete
	DEX			; else, backs off one place
	_STZA led_buf, X	; clear position, STZ for CMOS
	STX led_pos		; update cursor position
led_end:
	_EXIT_OK
led_no_bs:
	CMP #'.'		; may add dot to previous char
	BNE led_no_dot
	LDX led_pos		; gets cursor position
	BEQ led_no_dot		; nothing before
	DEX				; go to previous character
	LDA led_buf, X		; previous char. bitmap
	LSR			; check LSB for decimal point
	BCS led_no_dot		; already has dot, go away
	INC led_buf, X		; add decimal point
	_EXIT_OK
led_no_dot:
	CMP #' '		; check whether is non-printable
	BPL led_print		; OK to print
	LDA #' '		; put a space instead (or another char?)
	STA z2			; modify parameter!
led_print:
	LDA led_pos		; cursor position
	CMP led_len		; is display full?
	BMI led_no_scroll	; else, don't scroll
	LDX #1			; reset index
led_scroll:
	LDA led_buf, X		; get from second character
	STA led_buf-1, X	; copy it before
	INX			; get next character
	CPX led_len		; until screen ends
	BNE led_scroll
	DEX			; back off one place
	STX led_pos		; cursor *after* digit
led_no_scroll:
	LDX z2			; get the ASCII code
	LDA font-32, X		; get that character's bitmap (beware of NMOS page boundary!)
	LDX led_pos		; get cursor position
	STA led_buf, X		; store bitmap
	INC led_pos		; move cursor
	_EXIT_OK

; *** input ***
led_cin:
	LDX buf_cont	; number of characters in buffer
	BNE ledi_some	; not empty
	_ERR(_empty)	; mild error otherwise
ledi_some:
	LDX buf_read	; position to be read from buffer
	CPX buf_size	; just past the end?
	BNE ledi_no_wrap
	LDX #0		; wrap around
ledi_no_wrap:
	LDA buffer, X	; gets char stored at buffer
	STA z2		; output value
	INX		; advance to next position
	STX buf_read	; update pointer
	DEC buf_cont	; one less
	_EXIT_OK

; *** poll ***
led_get:
	LDX led_mux			; currently displayed digit
	_STZA _VIA+_iorb	; disable digit
	LDA _VIA+_iora		; get current cathode mask
	TAY					; save input bits
	AND #$F0			; only the output bits
	ASL					; shift to the next (left), INC if decoded
	BCC led_nw			; should it wrap? BNE/BMI after a CMP, if decoded
	LDA #$10			; begin from the right
	LDX #_led_digits	; should be 4, though
led_nw:
	STA _VIA+_iora		; update mask
	DEX					; go to "previous" char
	STX led_mux			; update displayed position
	LDA led_buf, X		; get bitmap to display -- better *after* the new cathode is enabled
	STA _VIA+_iorb		; put it on PB to show the digit
	TYA					; restore input bits
	AND #$0F			; mask input bits, keep PA0...PA3 only
	STA lkb_mat, X		; store current column
	CPX #0				; four columns processed?
	BEQ ledg_go			; decode it!
ledg_end:
	_EXIT_OK
; decode depressed key
ledg_go:
	LDA lkb_mat, X		; get stored column
	LDY #4				; number of rows per column
ledg_row:
	LSR					; shift right, get PA0...PA3
	BCS ledg_kpr		; abort if pressed
	DEY					; next row
	BNE ledg_row
	INX					; next column
	CPX #_led_digits	; until last
	BNE ledg_go
ledg_kpr:
	BCS ledg_scan	; key was actually pressed?
	_STZA lkb_new	; no longer pressed, reset previous scancode
	RTS				; ...and go away, there was no error
ledg_scan:
	STY sysvar		; save row (1-4) number
	TXA				; column number
	ASL				; multiply by four
	ASL
	CLC				; ORA no longer possible with 1-4 row numbers!
	ADC sysvar		; add row to 4*column
	CMP lkb_new		; new scancode?
	BEQ led_end		; if the same, do nothing
	STA lkb_new		; update register
	TAX				; scancode (1-16) as index
	DEX				; no 0-scancode in the table!
	LDA kptable, X	; get ASCII from scancode table
; *** should use generic FIFO from 0.4.1! ***
	JSR ledg_push	; put decoded character from A into buffer
ledg_rts:
	RTS				; actual exit point, with preloaded error codes...
; *** should use generic FIFO from 0.4.1! ***
ledg_push:
	LDX buf_cont	; number of characters in buffer
	CPX buf_size	; already full?
	BEQ ledg_full
	LDX buf_write	; position to be written on buffer
	CPX buf_size	; just past the end?
	BNE ledg_no_wrap
	LDX #0		; wrap around
ledg_no_wrap:
	STA buffer, X	; store char from A into buffer
	INX		; advance to next position
	STX buf_write	; update pointer
	INC buf_cont	; one more
ledg_full:
	_ERR(_full)	; no room

; *** initialise ***
; check some new values...
led_reset:
	LDY #%11110000		; bits PA4...7 for output
	STY _VIA+_ddra		; easier with unprotected I/O, it's within kernel code anyway
	LDY #$FF			; PB is all output
	STY _VIA+_ddrb		; easier with unprotected I/O, it's within kernel code anyway

; *** this will change in 0.4.1 with generic FIFO ***
	LDA #_kp_size		; keyboard buffer size, 1 should do fine w/o multitasking
	STA buf_size		; first byte of the pack
	CLC					; let's make a counter for the bytes to be cleared
	ADC #3				; cont+read+write (+ the buffer itself)
	TAX					; set counter as offset (won't reach first byte)
	LDA #0				; there's STZ on CMOS, but NMOS macros are worse here
led_bufclr:
	STA buf_size, X		; clear variable... but may be protected in future?
	DEX					; previous
	BNE led_bufclr		; won't reach offset 0, where the size is stored!
	
	LDA #_led_digits	; display size
	STA led_len			; first byte of the pack
	CLC					; let's make a counter for the bytes to be cleared
	ADC #2				; mux+pos (+ the buffer itself)
	TAX					; set counter as offset (won't reach first byte)
	LDA #0				; there's STZ on CMOS, but NMOS macros are worse here
led_dispcl:
	STA led_len, X		; clear variable
	DEX					; previous
	BNE led_dispcl		; won't reach offset 0, where the size is stored!

	_STZA lkb_new		; clear variable
	LDA _VIA+_pcr		; easier with unprotected I/O
	AND #%00011111		; keep other PCR bits
	ORA #%11000000		; CB2 low (display enable)
	STA _VIA+_pcr		; instead of the rest
	_EXIT_OK

; **** data tables ****

kptable:		; ascii values
	.asc 13, 27, "-+"	; rightmost column, bottom to top
	.asc "?369"
	.asc ".258"
	.asc "0147"		; leftmost column, bottom to top

; **** place bitmap here (minus non-printable chars)
font:
	.byt $00, $61, $44, $7E, $B4, $4B, $3C, $04, $9C, $F0, $6C, $62, $08, $02, $01, $4A
	.byt $FC, $60, $DA, $F2, $66, $B6, $BE, $E0, $FE, $F6, $41, $50, $18, $12, $30, $CA
	.byt $F8, $EE, $3E, $9C, $7A, $9E, $8E, $BC, $6E, $0C, $78, $0E, $1C, $EC, $2A, $FC
	.byt $CE, $FD, $DA, $B6, $1E, $38, $4E, $7C, $92, $76, $D8, $9C, $26, $F0, $C0, $10
	.byt $40, $FA, $3E, $1A, $7A, $DE, $8E, $F6, $2E, $08, $70, $0E, $1C, $EC, $2A, $3A
	.byt $CE, $E6, $0A, $32, $1E, $38, $4D, $7C, $92, $76, $D8, $9C, $20, $F0, $80, $00

