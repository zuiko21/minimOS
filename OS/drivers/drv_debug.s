; DEBUG bus-sniffer driver for minimOS
; v0.9.3b2, makeshift single-byte size version
; 0.6 API version 20170831
; (c) 2012-2021 Carlos J. Santisteban
; last modified 20200121-1342

#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa drivers/drv_debug.s -DTESTING=1
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
	.byt	DEV_DBG		; D_ID, new values 20150323
	.byt	A_POLL | A_BOUT	; poll, no async., Output only, no config/status, non relocatable (NEWEST HERE)
	.word	dled_err	; no input
	.word	dled_cout	; output N to display
	.word	dled_reset	; initialize device and appropiate systmps, called by POST only
	.word	dled_get	; poll, read keypad into buffer (called by ISR)
	.word	250			; will actually toggle CB2 each ~1 sec
	.word	dled_err	; req, this one can't generate IRQs, must at least set C
	.word	dled_err	; no config
	.word	dled_err	; no status
	.word	ledg_rts	; bye, no shutdown procedure
	.word	debug_info	; info string
	.word	0			; reserved for D_MEM

; *** info string ***
debug_info:
	.asc	"DEBUG VIAport driver v0.9.3", 0

; *** output ***
dled_blout:
; placeholder version, admits no more than 255 chars!!!
	LDA bl_siz	; check size
	BEQ ledg_rts	; nothing to print
	LDY #0		; reset index
dled_cout:
	LDA (bl_ptr), Y		; get char in case is control
	CMP #13			; carriage return? (shouldn't just clear, but wait for next char instead...)
	BNE no_blank	; if so, clear LED display
	_STZA VIA+IORA
	_STZA VIA+IORB
	BEQ dled_end	; no need for BRA, otherwise much like 150323
no_blank:
	LDX VIA+IORA	; take last char
	STX VIA+IORB	; scroll to the left
	STA VIA+IORA	; 'print' character
dled_end:
	INY		; go for next
	DEC bl_siz	; one less
	BNE dled_cout	; continue until done
	_DR_OK

; *** input not implemented ***
dled_err:
	_DR_ERR(UNAVAIL)	; mild error, so far

; *** poll ***
dled_get:
	LDA VIA+PCR	; get CB2 status
	EOR #%00100000	; toggle CB2
	STA VIA+PCR	; set CB2 status
ledg_rts:
	_DR_OK

; *** initialise ***
dled_reset:
	_STZA VIA+IORA	; clear digits
	_STZA VIA+IORB	; clear digits
	LDA #$FF		; all output
	STA VIA+DDRA	; set direction
	STA VIA+DDRB
	_DR_OK
