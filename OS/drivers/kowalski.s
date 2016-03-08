; minimOS basic I/O driver for Kowalski 6502 simulator
; v0.9b1
; (c) 2016 Carlos J. Santisteban
; last modified 20160308-1237

#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
.text
#endif

; *** begins with sub-function addresses table ***
	.byt	DEV_CONIO	; D_ID, new values 20150323
	.byt	A_CIN + A_COUT	; poll, no req., I/O, no 1-sec and neither block transfers, non relocatable (NEWEST HERE)
	.word	kow_rts		; initialize device, called by POST only
	.word	kow_rts		; poll, NOT USED
	.word	kow_rts		; req, this one can't generate IRQs, thus CLC+RTS
	.word	kow_cin		; cin, input from keyboard
	.word	kow_cout	; cout, output to display
	.word	kow_rts		; 1-sec, no need for 1-second interrupt
	.word	kow_rts		; sin, no block input
	.word	kow_rts		; sout, no block output
	.word	kow_rts		; bye, no shutdown procedure
	.word	debug_info	; info string
	.byt	0			; reserved for D_MEM

; *** info string ***
debug_info:
	.asc	"Concsole I/O driver for Kowalski 6502 simulator, v0.9b1", 0

; *** output ***
kow_cout:
	LDA zpar		; get char in case is control
	CMP #13			; carriage return?
	BNE kow_ncr		; if so, should generate CR+LF
		LDA #10			; LF first
		STA IO_BASE+1	; print it
		LDA #13			; back to original CR
kow_ncr:
	STA IO_BASE+1	; print it
kow_rts:
	_EXIT_OK

; *** input ***
kow_cin:
	LDA IO_BASE+4	; get input from I/O window
	BEQ kow_empty	; nothing available
		STA zpar		; store result otherwise
		_EXIT_OK
kow_empty:
	_ERR(EMPTY)		; nothing yet
