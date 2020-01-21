; minimOS basic I/O driver for Kowalski 6502 simulator
; v0.9b2
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20200121-1349

#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa drivers/drv_kowalski.s -DTESTING=1
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
#else
; ** regular assembly **
#include "../usual.h"
#endif
; no specific header for this driver
.text
#endif

; *** begins with sub-function addresses table ***
	.byt	DEV_CNIO	; D_ID, new values 20150323
	.byt	A_BLIN | A_BOUT	; poll, no req., I/O, no 1-sec and neither block transfers, non relocatable (NEWEST HERE)
	.word	kow_cin		; cin, input from keyboard
	.word	kow_cout	; cout, output to display
	.word	kow_rts		; initialize device, called by POST only
	.word	kow_rts		; poll, NOT USED
	.word	0			; irrelevant value as no polled interrupts
	.word	kow_err		; req, this one can't generate IRQs, thus SEC+RTS
	.word	kow_err		; no config
	.word	kow_err		; no status
	.word	kow_rts		; bye, no shutdown procedure
	.word	debug_info	; info string
	.word	0			; reserved for D_MEM

; *** info string ***
debug_info:
	.asc	"Console I/O driver for Kowalski 6502 simulator, v0.9b1", 0

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
	_DR_OK

; *** input ***
kow_cin:
	LDA IO_BASE+4	; get input from I/O window
	BEQ kow_empty	; nothing available
		STA zpar		; store result otherwise
		_DR_OK
kow_empty:
	_DR_ERR(EMPTY)		; nothing yet
kow_err:
	_DR_ERR(UNAVAIL)
