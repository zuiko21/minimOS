; Hitachi LCD for minimOS
; v0.6a1
; (c) 2018 Carlos J. Santisteban
; last modified 20180729-1555

; new VIA-connected device ID is $10-17, will go into PB
; VIA bit functions (data goes thru PA)
; E	= PB0 (easier pulsing)
; RS	= PB1
; R/W	= PB2
; should it respect PB3? Just in case...

; ***********************
; *** minimOS headers ***
; ***********************
#include "../usual.h"

.(
; *** begins with sub-function addresses table ***
	.byt	144			; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	lcd_err		; does not read
	.word	lcd_prn		; print N characters
	.word	lcd_init	; initialise device, called by POST only
	.word	lcd_rts		; no periodic interrupt
	.word	0			; frequency makes no sense
	.word	lcd_err		; D_ASYN does nothing
	.word	lcd_err		; no config
	.word	lcd_err		; no status
	.word	lcd_shut	; shutdown procedure will disable display
	.word	lcd_text	; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
srs_info:
	.asc	"20x4 char LCD 0.6a1", 0

lcd_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	L_OTH	= %00001000	; bits to be kept, PB3 only
	L_NOTH	= %11110111	; required PB outputs (inverse of L_OTH)
	LCD_PB	= %00010000	; base with E=0 (pulse PB0 via INC/DEC)
	LCD_RS	= %00010010	; set RS for printing & CG (PB1)
	LCD_RD	= %00010100	; read from LCD (PB2)
	LCD_RM	= %00010110	; read DDRAM/CGRAM (PB2+PB1)

; size definitions for other size LCDs
	L_CHAR	= 20		; chars per line
	L_LINE	= 4		; lines

; ************************
; *** initialise stuff ***
; ************************
lcd_init:
	JSR lcd_rst		; set VIA ready for LCD command
; follow standard LCD init procedure
	LDX #2			; wait values [0..2]
ld_loop:
		LDA wait_c, X	; get delay (in 100us units)
		JSR l_delay
		LDA #$30		; standard init value
		STA VIA_U+IORA	; ...on data port
		INC VIA_U+IORB	; pulse E on LCD!
		DEC VIA_U+IORB
		DEX				; next delay
		BPL ld_loop
; set LCD parameters
	LDX #4			; will send 5 commands
li_loop:
		JSR l_busy		; wait for LCD availability
		LDA l_set, X		; get config command
		STA VIA_U+IORA	; ...on data port
		INC VIA_U+IORB	; pulse E on LCD!
		DEC VIA_U+IORB
		DEX				; next command
		BPL li_loop
	_DR_OK				; succeeded

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
lcd_prn:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
lp_l:
		_PHY				; keep this
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		JSR lcd_char		; *** print one byte ***
			BCS lcd_exit		; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		DEC bl_siz			; one less to go
			BNE lp_l			; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ lcd_end			; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA lp_l
lcd_exit:
	PLA					; discard saved index
lcd_end:
	PLA					; get saved MSB...
	STA bl_ptr+1		; ...and restore it
lcd_rts:
	RTS					; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
lcd_char:
; first check whether control char or printable
	LDA io_c			; get char (3)
	CMP #' '			; printable? (2)
	BCS lcd_prn			; it is! skip further comparisons (3)
		CMP #FORMFEED		; clear screen?
		BNE lch_nff
			JMP lcd_cls			; clear and return!
lcd_nff:
		CMP #CR				; newline?
		BNE lch_ncr
			JMP lcd_cr			; modify pointers (scrolling perhaps) and return
lcd_ncr:
		CMP #HTAB			; tab?
		BNE lch_ntb
			JMP lcd_tab			; advance cursor
lcd_ntb:
		CMP #BS				; backspace?
		BNE lch_nbs
			JMP lcd_bs			; delete last character
lcd_nbs:
/*
		CMP #14				; shift out?
		BNE lch_nso
			LDA #$FF			; mask for reverse video
			_BRA lcd_xor		; set mask and finish
vch_nso:
		CMP #15				; shift in?
		BNE lch_nsi
			LDA #$FF			; mask for true video
vso_xor:
			STA vdu_xor			; set new mask
			RTS					; all done for this setting
vdu_nsi:
*/
; non-printable neither accepted control, thus use substitution character
		LDA #'?'			; unrecognised char
		STA io_c			; store as required
lcd_prn:
; set up VIA for LCD print
	LDA VIA_U+IORB		; current PB (4)
	AND #L_OTH			; respect PB3 only (2)
	ORA #LCD_RS
	STA VIA_U+IORB		; set command... (4)

; printing is done, now advance current position
; set up VIA... (worth a subroutine)
	JSR lcd_rst		; ready to control CRTC (...)

	_DR_OK

; *************************
; *** printing routines ***
; *************************

; *** clear the screen ***
lcd_cls:
	_STZA lcd_x		; clear local coordinates
	_STZA lcd_y
	JSR l_busy		; wait for LCD availability
	LDA #1			; command = clear display
; * issue command on A, assume cmd output set *
l_issue:
	STA VIA_U+IORB
l_pulse:
	INC VIA_U+IORB		; pulse E on LCD!
	DEC VIA_U+IORB
	RTS

; *** carriage return ***
lcd_cr:
	JSR l_busy		; ready for several commands
	_STZA lcd_x		; correct local coordinates
	INC lcd_y
	LDA lcd_y		; check whether should scroll
	CMP #L_LINE
	BCC lcr_ns		; no scroll
		LDY #1			; yes, first source line
lcr_sc:
			STY lcd_y		; will be loop variable
			LDA l_addr, Y	; address of this line
			ORA #%10000000	; set DDRAM address
			JSR l_issue
			LDX #0			; loop variable
lcr_scr:
				JSR l_avail		; wait for DDRAM access
				LDA #LCD_RM		; will read
				JSR l_issue
				LDA VIA_U+IORA	; get byte and advance pointer
				STA l_buff, X	; store temporarily
				INX
				CPX #L_CHAR		; until 20 chars done
				BNE lcr_scl
; one 20 char line in buffer, copy back on line above
			LDY lcd_y		; back one line
			DEY
			LDA l_addr, Y	; address of this line
			ORA #%10000000	; set DDRAM address
			JSR l_issue
			LDX #0			; loop variable
lcr_scw:
				
				LDA l_buff, X	; retrieve from buffer
				INX
				CPX #L_CHAR		; until 20 chars done
				BNE lcr_scw
; proceed until three lines have been moved
			LDY lcd_y		; advance one line
			INY
			CPY #L_LINE		; all done?
			BNE lcr_sc
		STY lcd_y		; restore as maximum
; before exit, should clear bottom line! TO DO
lcr_ns:
	LDX lcd_y		; index for y
	LDA l_addr, X	; current line address
	ORA #%10000000	; set DDRAM address
	BNE l_issue		; issue command and return (no need for BRA)

; *** tab (4 spaces) ***
lcd_tab:
	; get LSB

	AND #%11111100		; modulo 4
	CLC
	ADC #4				; increment position (2)
	_DR_OK				; yes, all done

; *** backspace ***
lcd_bs:
; first get cursor one position back...
	JSR lbs_bk			; will call it again at the end (...)
; ...then print a space, the regular way...
	LDA #' '			; code of space (2)
	STA io_c			; store as single char... (3)
	JSR lcd_prn			; print whatever is in io_c (...)
; ...and back again!
lbs_bk:
	DEC lcd_cur			; one position back (6)
	LDA lcd_cur		; check for carry (4)
	CMP #$FF			; did it wrap? (2)
	BNE lcd_end			; no, return or end function (3/2)
; really ought to check for possible scroll-UP...
; at least, avoid being outside feasible values

			PLA					; discard return address, as nothing to print (4+4)
			PLA
			_DR_ERR(EMPTY)		; try to complain, just in case
lbs_end:
	_DR_OK				; all done, CLC will not harm at first call

; ************************
; *** generic routines ***
; ************************

; *** set up VIA for LCD commands ***
lcd_rst:
	LDA VIA_U+DDRB		; control port... (4)
	ORA #L_NOTH		; ...with required outputs... (2)
	STA VIA_U+DDRB		; ...just in case (4)
; *** faster command output ***
lcd_out:
	LDA #$FF			; all outputs... (2)
	STA VIA_U+DDRA		; ...as uses 8-bit mode (4)
; *** even faster command issue ***
lcd_cmd:
	LDA VIA_U+IORB		; original PB value on user VIA (4)
	AND #L_OTH			; leave PB3 (2)
	ORA #LCD_PB		; E=RS=0, ready for commands
	STA VIA_U+IORB		; just waiting for E to send LCD command in PA (4)
	RTS

; *** routine for waiting A×100 uS *** for 1 MHz
wait_c:
	TAY					; will respect X, affects Y & A
; base 100uS delay
w100us:
		LDA #14			; 97+5uS delay @ 1 MHz, change or compute if needed
w_loop:
			SEC				; (2)
			SBC #1			; (2)
			BNE w_loop		; (3)
		DEY				; another 100uS
		BNE w100us
	RTS

; *** wait command completion *** respects X
l_busy:
	JSR _wait		; generic busy check
	AND #L_OTH			; respect bits (A returns PB)
	ORA #LCD_PB			; ready for command
	STA VIA_U+IORB
	DEC VIA_U+DDRA		; set back outputs
	RTS

; *** wait for sending chars***
l_avail:
	JSR l_wait		; cannot optimise as JMP, in case of timeout
	RTS

; ** generic availability check **
l_wait:
	_STZA VIA_U+DDRA	; set input!
	LDA VIA_U+IORB		; original PB
	AND #L_OTH			; respect bits
	ORA #LCD_RD			; will read status
	STA VIA_U+IORB
	LDY #200			; for 2.2 ms timeout (96 if pulse is inside loop)
	INC VIA_U+IORB		; pulse E on LCD! inside loop if flag not updated
	DEC VIA_U+IORB
lb_loop:
; is busy flag updated without pulsing E?
; MUST implement some timeout, or will hang if disconnected!!
		DEY
			BEQ l_tout			; timeout expired!
		BIT VIA_U+IORA		; read status (respect A)
		BMI lb_loop			; until available
	RTS
; ** timeout handler **
l_tout:
	PLA					; discard both return addresses
	PLA
	PLA
	PLA
	_DR_ERR(TIMEOUT)

; ********************
; *** several data ***
; ********************

; initialisation delays (reversed)
l_delay:
	.byt	1, 41, 150	; 15ms, 4.1ms & 100us

; initialisation commands (reversed)
l_set:
	.byt	%00001110	; enable display & cursor
	.byt	%00000110	; entry set = increment, do not shift
	.byt	%00000001	; display clear
	.byt	%00001000	; display off
	.byt	%00111000	; 8-bit, 2 lines, 5x8 font

; line adresses
l_addr:
	.byt	0, $40, $14, $54	; start address of each line

.)
