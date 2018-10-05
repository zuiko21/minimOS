; Roñavid driver for minimOS-16
; v0.6a1
; (c) 2018 Carlos J. Santisteban
; last modified 20181005-1816

; 576×448 bitmap version

; ***********************
; *** minimOS headers ***
; ***********************
//#include "../usual.h"
#include "options/chihuahua_plus.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"

* = $200
#include "drivers/roñavid.h"
.text

.(
; *** assembly options and other constants ***
; substitution for undefined chars
#define	SUBST	'?'
; enable char redefining for international support
#define	INTLSUP	_INTLSUP

; *** begins with sub-function addresses table ***
	.byt	160			; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	rv_err		; does not read
	.word	rv_prn		; print N characters
	.word	rv_init		; initialise device, called by POST only
	.word	rv_rts		; no periodic interrupt
	.word	0			; frequency makes no sense
	.word	rv_err		; D_ASYN does nothing
	.word	rv_err		; no config
	.word	rv_err		; no status
	.word	rv_rts		; shutdown procedure will do nothing
	.word	rv_txt		; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
rv_txt:
	.asc	"576x448 RoñaVid card v0.6-16bit", 0

rv_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***

; size definitions for 8*16 font
	L_CHAR	= 72		; chars per line
	L_LINE	= 28		; lines

; ************************
; *** initialise stuff ***
; ************************
rv_init:
; proceed with driver variables
	STZ rv_x		; reset coordinate
	STZ rv_y		; reset coordinate
	_DR_OK			; succeeded

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
rv_prn:
	.xl: REP #$10			; 16-bit index
	LDY #0				; reset index
	LDX bl_siz			; not empty?
	BEQ rv_end
lp_l:
		PHY				; keep these
		PHP
		LDA [bl_ptr], Y		; buffer contents...
		STA io_c			; ...will be sent
		.xs: SEP #$10
		JSR rv_char		; *** print one byte ***
			BCS rv_exit		; any error ends transfer!
		PLP: .xl
		PLY				; restore size and index
		INY					; go for next
		LDX bl_siz			; bytes to go
		DEX					; one less
		STX bl_siz		; update
		BNE lp_l
	BRA rv_end		; until the end
rv_exit:
		PLA
		PLA				; discard saved index, but respect possible error code
rv_end:
	.xs: SEP #$10
rv_rts:
	RTS					; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
rv_char:
; first check whether control char or printable
	LDA io_c			; get char (3)
	CMP #' '			; printable? (2)
	BCS rch_wdd			; it is! skip further comparisons (3)
		CMP #FORMFEED		; clear screen?
		BNE rch_nff
			JMP rv_cls			; clear and return!
rch_nff:
		CMP #LF			; line feed?
		BNE rch_nlf
			JMP rv_lf			; clear and return!
rch_nlf:
		CMP #CR				; newline?
		BNE rch_ncr
			JMP rv_cr			; scrolling perhaps
rch_ncr:
		CMP #HTAB			; tab?
		BNE rch_ntb
			JMP rv_tab			; advance cursor
rch_ntb:
		CMP #BS				; backspace?
		BNE rch_nbs
			JMP rv_bs			; delete last character
rch_nbs:
; non-printable neither accepted control, thus use substitution character
		LDA #SUBST			; unrecognised char
		STA io_c			; store as required
rch_wdd:
; could be delete!
; send char at io_c
#ifndef	INTLSUP
	LDA io_c			; update flags
	BPL rch_ok			; standard ASCII
		LDA #SUBST			; higher chars not supported
lch_ok:
#endif

; advance local cursor position and check for possible wrap/scroll
	INC rv_x			; one more char
	LDA rv_x			; check for EOL
	CMP #L_CHAR
		BEQ rv_cr			; wrapped, thus do CR
	_DR_OK

; *************************
; *** printing routines ***
; *************************

; *** clear the screen ***
rv_cls:
	STZ rv_x		; clear local coordinates
	STZ rv_y

	RTS

; *** new line and line feed ***
rv_cr:
	STZ rv_x		; correct local coordinates
rv_lf:
	INC rv_y
	LDA rv_y		; check whether should scroll
	CMP #L_LINE
	BCC rv_ns		; no scroll
; ** scrolling code, may become routine if makes branches too far **
		LDY #1			; yes, first source line
rv_sc:

		LDX #L_CHAR		; spaces to be printed
; this space-printing loop cannot use regular rv_prn as the last one will invoke CR
rcr_sp:

; ** end of scrolling code **
rv_ns:

; *** tab (4 spaces) ***
rv_tab:
	LDA rv_x		; get column
	AND #%11111000	; modulo 8
	CLC
	ADC #8			; increment to target position (2)
	SEC
	SBC rv_x		; subtract current, these are the needed spaces
	TAX				; will be respected
	LDA #' '		; char to be printed, set once only
	STA io_c
rtab_sp:
		JSR rv_prn		; do print that space, but must respect X
		DEX
		BNE rtab_sp		; until done
; regular print will take care of possible CR
	_DR_OK

; *** backspace ***
rv_bs:
; first get cursor one position back...
	LDA rv_x		; nothing to the left? (4)
	BNE rbs_ok		; something, go back one (3/2)
		_DR_ERR(EMPTY)		; nothing, complain somehow
	DEC rv_x		; one position back (6)
rbs_ok:
; ...then print a space

	_DR_OK			; local cursor was not affected

; ************************
; *** generic routines ***
; ************************


; ********************
; *** several data ***
; ********************

; ** glyph definitions **

.)
