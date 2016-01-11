; minimOS 0.4b2 LED Keypad driver, 6502 SDx
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.19

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
	CMP #_cr		; carriage return?
	BEQ led_blank		; if so, clear LED display
	CMP #_lf		; LF clears too
	BEQ led_blank
	CMP #_ff		; FF clears too
	BNE led_no_clear	; else, do print
led_blank:
	LDX led_len		; display size
led_clear:
	DEX
	_STZA led_buf, X
	BNE led_clear		; loops until all clear
	STA led_pos		; STZ, reset cursor
	_EXIT_OK
led_no_clear:
	CMP #_bs		; backspace?
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
	LDA #' '		; put a space instead
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
	STX led_pos		; cursor at last digit
led_no_scroll:
	LDX z2			; get the ASCII code
	LDA font-32, X		; get that character's bitmap
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
	_STZA _VIA+_iorb	; disable digit - should really do s_poke()
	LDX led_mux	; currently displayed digit
	INX		; next digit
	CPX led_len	; until it goes thru the whole cycle
	BNE ledg_nwr
	LDX #0		; wrap whenever needed
ledg_nwr:
	STX led_mux	; update displayed position
	LDA led_buf, X	; get bitmap to display
	STA _VIA+_iorb	; put it on PB, should do s_poke()
	LDA rowmask, X	; appropiate cathode-enabling masks for PA = 128, 64, 32, 16
	STA _VIA+_iora	; ...or s_poke()
	LDA _VIA+_iora	; get input bits from PA, maybe s_peek()?
	ORA #$0F	; mask bits, keep PA0...PA3 only
	TAY		; save input bits
	LDA lkb_mat, X	; check whether already pressed something at that column
	BNE ledg_nuk	; no need to update
	LDA #$80	; a new key has been pressed
	STA lkb_new	; mark flag
	TYA		; restore bit pattern
	STA lkb_mat, X	; store updated pattern
ledg_nuk:
	INX		; won't use anymore
	CPX led_len	; last column?
	BNE ledg_go	; don't decode yet
	LDA lkb_new	; check for something new, BIT should work as well
	BEQ ledg_go
; decode depressed key(s)
	LDX #0
ledg_col:
	LDA lkb_mat, X	; get stored column
	LDY #4		; number of rows per column
ledg_row:
	LSR		; shift right, get PA0...PA3
	BCS ledg_kpr	; abort if pressed
	DEY		; next row
	BNE ledg_row
	INX		; next column
	CPX #4		; until last
	BNE ledg_col
ledg_kpr:
	BCC ledg_yet	; no key was pressed, no error
	DEY		; row number 0...3
	STY sysvar	; save row number
	TXA		; column number
	CLC		; clear carry, or only for ROL?
	ASL		; multiply by four
	ASL
	ORA sysvar	; add row to 4*column
	TAX		; scancode as index
	LDA kptable, X	; get ASCII from scancode table
	JSR ledg_push	; put decoded character from A into buffer
ledg_yet:
	_STZA lkb_new	; key has been decoded and stored, don't keep processing it
ledg_rts:
	RTS		; actual exit point, with preloaded error codes...
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
ledg_go:
	_EXIT_OK
ledg_full:
	_ERR(_full)	; no room

; *** initialise ***
led_reset:
	LDA #$F0	; bits PA4...7 for output
	STA _VIA+_ddra	; Eeeek! Should be thru s_poke(), really...
	LDA #$FF	; all PB for output
	STA _VIA+_ddrb	; ditto...
	LDA #1		; whatever size for the 'keyboard' buffer -- 1 should do fine without multitasking
	STA buf_size
	_STZA buf_write	; init keypad buffer variables
	_STZA buf_read
	_STZA buf_cont
	LDX #6		; +4 digits + display position + cursor position
ledr_init:
	_STZA led_len, X	; pointer to the first of seven bytes
	DEX
	BNE ledr_init	; clears everything except...
	LDA #4		; number of digits
	STA led_len
	LDA _VIA+_pcr	; negate CB2 for display enable
	AND #$1F	; keep other PCR bits
	ORA #$C0	; CB2 low
	STA _VIA+_pcr	; enable display
	_EXIT_OK

; **** data tables ****
rowmask:		; mask for keypad decoding
	.byt 128, 64, 32, 16

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

