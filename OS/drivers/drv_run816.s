; minimOS basic I/O driver for run65816 BBC simulator
; v0.9.6b4
; *** new format for mOS 0.6 compatibility *** 16-bit version
; (c) 2017-2020 Carlos J. Santisteban
; last modified 20200118-2251

#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa -w drivers/drv_run816.s -DTESTING=1
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

.(
; *** begins with sub-function addresses table ***
	.byt	DEV_CNIO	; D_ID, new values 20150323
	.byt	A_BLIN | A_BOUT	; I/O only, non relocatable
	.word	kow_blin	; block? input from keyboard
	.word	kow_bout	; block output to display
	.word	kow_rts		; initialise device, does nothing
	.word	kow_rts		; poll, NOT USED
	.word	0			; irrelevant value as no polled interrupts
	.word	kow_err		; req, this one can't generate IRQs, thus SEC+RTS
	.word	kow_err		; no config
	.word	kow_err		; no status
	.word	kow_rts		; bye, no shutdown procedure
	.word	debug_info	; info string
	.word	0			; reserved for D_MEM, this is non-relocatable

; *** info string ***
debug_info:
	.asc	"Console I/O driver for run65816 BBC simulator (16-bit), v0.9.6b3", 0

	.as:.xs				; supposedly called from 8-bit sizes!

; *** output ***
kow_bout:
; all checked, do block output!
	.xl: REP #$10		; worth going 16-bit indexes!!!
	LDY #0				; reset index
	LDX bl_siz			; get full size, could also check for zero!
#ifdef	SAFE
		BEQ kow_rts			; nothing to do then
#endif
kow_cout:
		LDA [bl_ptr], Y		; get char in case is control ***24-bit addressing
		CMP #13				; carriage return?
		BNE kow_ncr			; if so, should generate LF instead
			LDA #10				; LF first (and only)
kow_ncr:
		JSR $c0c2			; print it
		INY					; go for next
		DEX					; one less to go
		BNE kow_cout		; repeat until end
kow_end:
	STX bl_siz				; update remaining size!
kow_rts:
	_DR_OK

; *** input *** will only get one!
kow_blin:
	.xl: REP #$10		; worth going 16-bit indexes!!!
	LDX bl_siz			; get full size, could also check for zero!
#ifdef	SAFE
		BEQ kow_rts			; nothing to do then
#endif
	JSR $c0bf			; will this work???
;	BCS kow_empty		; nothing available
		CMP #LF				; linux-like LF?
		BNE kow_emit		; do not process
			LDA #CR				; or convert to CR
kow_emit:
		STA [bl_ptr]		; store result otherwise ***24-bit addressing
		DEX					; one less
		STX bl_siz			; easier to update parameter
		_DR_OK				; perhaps some special error code...
;kow_empty:
;	DR_ERR(EMPTY)		; nothing yet
kow_err:
	_DR_ERR(UNAVAIL)

	.as:.xs				; make sure everything else assembles OK!
.)
