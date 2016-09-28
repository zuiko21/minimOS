; DEBUG bus-sniffer driver for minimOS
; v0.9.2
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20150605-1411
; revised 20160928-1054 FOR NEW INTERFACE

#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
.text
#endif

; *** begins with sub-function addresses table ***
	.byt	DEV_DEBUG					; D_ID, new values 20150323
	.byt	A_POLL + A_CIN + A_COUT		; poll, no req., I/O, no 1-sec and neither block transfers, non relocatable (NEWEST HERE)
	.word	dled_reset	; initialize device and appropiate systmps, called by POST only
	.word	dled_get	; poll, read keypad into buffer (called by ISR)
	.word	ledg_rts	; req, this one can't generate IRQs, thus CLC+RTS
	.word	dled_cin	; cin, input from buffer
	.word	dled_cout	; cout, output to display
	.word	ledg_rts	; NEW, 1-sec, no need for 1-second interrupt
	.word	ledg_rts	; NEW, sin, no block input
	.word	ledg_rts	; NEW, sout, no block output
	.word	ledg_rts	; NEWER, bye, no shutdown procedure
	.word	debug_info	; NEWEST info string
	.byt	0			; reserved for D_MEM

; *** info string ***
debug_info:
	.asc	"DEBUG VIAport driver v0.9.1", 0

; *** output ***
dled_cout:
	LDA z2			; get char in case is control
	CMP #13			; carriage return? (shouldn't just clear, but wait for next char instead...)
	BNE no_blank	; if so, clear LED display
	STZ VIA+IORA
	STZ VIA+IORB
	BEQ dled_end	; no need for BRA, otherwise much like 150323
no_blank:
	LDX VIA+IORA	; take last char
	STX VIA+IORB	; scroll to the left
	STA VIA+IORA	; 'print' character
dled_end:
	_DR_OK

; *** input ***
dled_cin:
	_DR_ERR(EMPTY)	; mild error, so far

; *** poll ***
dled_get:
	INC systmp		; interrupt counter, every 1.28 seconds
	BNE dled_end		; not much to do in the while
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
	_STZA systmp	; some more odd init code
	_DR_OK
