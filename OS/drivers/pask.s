; 40-key simple ASCII keyboard for minimOS!
; v0.6a2
; (c) 2019-2020 Carlos J. Santisteban
; last modified 20190417-2121

; ***********************
; *** minimOS headers ***
; ***********************
#include "usual.h"
.(
; ******************************
; *** standard minimOS stuff ***
; ******************************

; *** begins with sub-function addresses table ***
	.byt	145			; physical driver number D_ID (TBD)
	.byt	A_BLIN		; input driver, non interrupt-driven
	.word	pk_read		; read from input buffer
	.word	pk_err		; no output
	.word	pk_init		; initialise 'device', called by POST only
	.word	pk_err		; no periodic interrupt...
	.word	0			; N/A
	.word	pk_nreq		; D_ASYN does nothing
	.word	pk_err		; no config
	.word	pk_err		; no status
	.word	pk_exit		; shutdown procedure, not much to do...
	.word	pk_info		; points to descriptor string
	.word	0			; non-relocatable, D_MEM

; *** driver description ***
pk_info:
	.asc	"Port-A Simple Keyboard v0.6", 0

; ****************************************
; *** read from buffer to output block *** usual mandatory loop
; ****************************************
; this might be simplified as will never get more than one character
pk_read:
	LDA bl_ptr+1		; save pointer MSB
	PHA
	LDY #0				; reset index
pk_rloop:
		LDA bl_siz			; check remaining
		ORA bl_siz+1
			BEQ blck_end		; nothing to do
; inlined code to get one char in A
		PHY
#include "../firmware/modules/pask_read.s"
; should check events here
		BCS pk_nev		; skip event polling if nothing picked
			_KERNEL(B_EVENT)
pk_nev:
		TYA					; take possible key or error
		PLY
; standard loop follows
			BCS blck_end		; any error ends transfer!
		STA (bl_ptr),Y		; ...goes into buffer
		INY					; next byte, check carry
		BNE pk_nw
			INC bl_ptr+1
pk_nw:
		DEC bl_siz			; one less to go
		LDA bl_siz			; check whether wrapped
		CMP #$FF
		BNE blck_end		; no wrap, all done
			LDA bl_siz+1		; any page remaining?
		BEQ blck_end		; no, exit
			DEC bl_siz+1		; ...or one page less
		_BRA pk_rloop
blck_end:
	TAY					; retrieve error code, if any
	PLA					; restore MSB
	STA bl_ptr+1
	RTS					; respect whatever error code

pk_err:
	_DR_ERR(NO_RSRC)	; cannot do this

; ************************
; *** initialise stuff *** taken from firmware
; ************************
pk_init:
#include "../firmware/modules/pask_init.s"
pk_exit:				; placeholder
	_DR_OK				; succeeded


ak_get:
	LDX ak_fo			; get output position
	CPX ak_fi			; is it empty?
	BNE ak_some			; no, do extract
		_DR_ERR(EMPTY)		; yes, do nothing
ak_some:
	LDA ak_buff, X		; extract char
	INX					; this is no more
	CPX #AF_SIZ			; wrapped?
	BNE ak_rnw			; no
		LDX #0				; or yes, back to zero
ak_rnw:
	STX ak_fo			; eeeeeeeeeek
	_DR_OK

; *** misc ***
ak_nreq:
	_NXT_ISR			; in case gets called, exit ASAP

.)
