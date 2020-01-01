; minimOS basic I/O driver for run65816 BBC simulator
; v0.9.6b5
; *** new format for mOS 0.6 compatibility *** 8-bit version
; (c) 2017-2020 Carlos J. Santisteban
; last modified 20181114-0849

#include	"../usual.h"

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
	.asc	"Console I/O driver for run65816 BBC simulator (8-bit), v0.9.6b2", 0

; *** output ***
kow_bout:
#ifdef	SAFE
	LDA bl_siz			; check size in case is zero
	ORA bl_siz+1
		BEQ kow_rts			; nothing to do then
#endif
	LDX bl_ptr+1		; save pointer MSB...
; all checked, do block output!
	LDY #0				; reset index
kow_cout:
		LDA (bl_ptr), Y		; get char in case is control
		CMP #13				; carriage return?
		BNE kow_ncr			; if so, should generate LF instead
			LDA #10			; LF first (and only)
kow_ncr:
		JSR $c0c2			; print it
		DEC bl_siz			; one less to go
		BNE kow_blk			; go for next
			LDA bl_siz+1		; are we done?
				BEQ kow_end			; yeah!
			DEC bl_siz+1		; or one page less
kow_blk:
		INY					; point to next
		BNE kow_cout		; did not wrap EEEEEEEEEK
			INC bl_ptr+1		; or update MSB
		_BRA kow_cout		; and continue EEEEEEEEEEEK
kow_end:
	STX bl_ptr+1		;  retrieve saved MSB
kow_rts:
	_DR_OK

; *** input ***
kow_blin:
	LDA bl_siz			; check size in case is zero
	ORA bl_siz+1
		BEQ kow_rts			; nothing to do then
	JSR $c0bf			; will this work???
	TAX
	BEQ kow_empty		; nothing available *** perhaps BEQ
		CMP #LF				; linux-like LF?
		BNE kow_emit		; do not process
			LDA #CR				; or convert to CR
kow_emit:
		_STAY(bl_ptr)		; store result otherwise
		DEC bl_siz			; one less
		LDA bl_siz
		CMP #$FF			; will it wrap?
		BNE kow_cont		; not *** should NOT just return, but try to get some more!
			LDA bl_siz+1		; any more?
		BEQ kow_rts			; not, just finished!
			DEC bl_siz+1		; or update MSB
kow_cont:
		INC bl_ptr			; go for next
		BNE kow_blin
			INC bl_ptr+1
		BNE kow_blin		; BRA
kow_empty:
	_DR_ERR(EMPTY)		; nothing yet
kow_err:
	_DR_ERR(UNAVAIL)
.)
