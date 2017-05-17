; minimOS basic I/O driver for run65816 BBC simulator
; v0.9.6a1
; *** new format for mOS 0.6 compatibility ***
; (c) 2017 Carlos J. Santisteban
; last modified 20170517-1215

#include	"usual.h"
.(
; *** begins with sub-function addresses table ***
	.byt	DEV_CONIO	; D_ID, new values 20150323
	.byt	A_CIN | A_COUT	; character I/O only, non relocatable
	.word	kow_rts		; initialize device, called by POST only
	.word	kow_rts		; poll, NOT USED
	.word	kow_rts		; req, this one can't generate IRQs, thus CLC+RTS
	.word	kow_cin		; cin, input from keyboard
	.word	kow_cout	; cout, output to display
	.word	1			; irrelevant value as no polled interrupts
	.word	kow_rts		; sin, no block input
	.word	kow_rts		; sout, no block output
	.word	kow_rts		; bye, no shutdown procedure
	.word	debug_info	; info string
	.word	0			; reserved for D_MEM, this is non-relocatable

; *** info string ***
debug_info:
	.asc	"Console I/O driver for run65816 BBC simulator, v0.9.6a1", 0

; *** output ***
kow_cout:
	LDA io_c		; get char in case is control
	CMP #13			; carriage return?
	BNE kow_ncr		; if so, should generate CR+LF
		LDA #10			; LF first (and only)
kow_ncr:
	JSR $c0c2		; print it
kow_rts:
	_DR_OK

; *** input ***
kow_cin:
	JSR $c0bf		; will this work???
;	BCS kow_empty	; nothing available
		CMP #LF			; linux-like LF?
		BNE kow_emit	; do not process
			LDA #CR			; or convert to CR
kow_emit:
		STA io_c		; store result otherwise
		_DR_OK
;kow_empty:
;	_DR_ERR(EMPTY)		; nothing yet
).
