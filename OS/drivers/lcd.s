; Hitachi LCD for minimOS
; v0.6a1
; (c) 2018 Carlos J. Santisteban
; last modified 20180729-1059

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
	LCD_PB	= $10		; base with E=0 (pulse PB0 via INC/DEC)
	LCD_RS	= %00010010	; set RS (PB1)
	LCD_RD	= %00010100	; read from LCD (PB2)

; ************************
; *** initialise stuff ***
; ************************
lcd_init:
	_DR_OK				; succeeded

; ***************************************
; *** routine for clearing the screen ***
; ***************************************
lcd_cls:
	RTS

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
	BCS vch_prn			; it is! skip further comparisons (3)
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
; set up VIA... for LCD access!
	LDA VIA_U+IORB		; current PB (4)
	AND #L_OTH			; respect PB3 only (2)

	STA VIA_U+IORB		; set command... (4)

; printing is done, now advance current position
; set up VIA... (worth a subroutine)
	JSR lcd_rst		; ready to control CRTC (...)

	_DR_OK

; *** carriage return ***
lcd_cr:

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

; *** generic routines ***
; set up VIA... for LCD settings (exit as X=idle, Y=$FF)
lcd_rst:
	LDA VIA_U+DDRB		; control port... (4)
	ORA #%11110111		; ...with required outputs... (2)
	STA VIA_U+DDRB		; ...just in case (4)
	LDY #$FF			; all outputs... (2)
	STY VIA_U+DDRA		; ...for data port (4)
	LDA VIA_U+IORB		; original PB value on user VIA (new var) (4)
	AND #L_OTH			; clear device, leave PB3 (2)

	RTS

; ********************
; *** several data ***
; ********************


.)
