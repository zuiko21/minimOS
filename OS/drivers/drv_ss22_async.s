; SS-22 *asynchronous* driver for minimOS
; v0.5a2, seems OBSOLETE since 2016
; (c) 2012-2022 Carlos J. Santisteban
; last modified 20200121-1414
; revised 20160928

#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa drivers/drv_ss22_async.s -I drivers/ -DTESTING=1
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
#else
; ** regular assembly **
#include "../usual.h"
#endif
; specific header for this driver
.bss
#include "drv_ss22.h"
.text
#endif


	.word	ss_cin	; input from buffer
	.word	ss_cout	; output via SS-22 (unbuffered)
	.word	ss_init	; initialize VIA and appropiate sysvars, called by POST only
	.word	ss_full	; nothing periodic to do
	.word	$FF		; irrelevant value as nothing periodic
	.word	ss_rcp	; IRQ whenever Tx wants to send (start receiving) OR a character fully arrived (put it into buffer)
	.word	ss_full	; no config
	.word	ss_full	; no status
	.word	ss_bye	; shutdown procedure, new 20150305
	.word	ss_info	; D_INFO string
	.word	0		; D_MEM reserved

; *** begins with sub-function addresses table ***
	.byt	DEV_SS22					; D_ID shared with synchronous version, TBD
	.byt	A_REQ | A_BLIN | A_BOUT		; no poll, by request, I/O, no 1-sec nor block transfers, non-relocatable (NEW)
	.word	ss_cin	; input from buffer
	.word	ss_cout	; output via SS-22 (unbuffered)
	.word	ss_init	; initialize VIA and appropiate sysvars, called by POST only
	.word	ss_end	; nothing periodic to do
	.word	$FF		; irrelevant value as nothing periodic
	.word	ss_rcp	; IRQ whenever Tx wants to send (start receiving) OR a character fully arrived (put it into buffer)
	.word	ss_full	; no config
	.word	ss_full	; no status
	.word	ss_bye	; NEW 20150213 shutdown procedure
	.word	ss_info	; NEW 20150323 info string
	.word	0		; reserved for D_MEM

; *** info string ***
ss_info:
	.asc	"SS-22 asynchronous driver v0.5a2", 0

; *** initialise ***
ss_init:
	LDA #$05		; disable CA2 and SR interrupts
	STA VIA+IER
	_STZA ss_write	; init SS-22 buffer variables
	_STZA ss_read
	_STZA ss_cont
	_STZA ss_stat	; no pending operations
	LDA #SS_SPEED	; get initial value for 15625 bps
	STA ss_speed	; will be read upon reception
; stay disabled until actually needed!
	LDA VIA+ACR		; get previous state
	AND #$E7		; mask out SR bits
	STA VIA+ACR		; shift register disabled
; activate ints
	LDA #$85		; enable CA2 and SR interrupts
	STA VIA+IER
	_DR_OK			; called during boot, needs to signal OK!

; *** output ***
ss_cout:
; ** ensure PB7 is high to make it silent **
	LDA VIA+IORB	; get current value
	ORA #$80		; set bit 7
	STA VIA+IORB	; modify output
; wait for no operations in progress
	LDX #91		; load timeout counter (91x11 = 1 ms @ 1 MHz)
ss_time:
		LDA ss_stat		; check availability (4)
			BEQ ss_free		; proceed if available (2/3)
		DEX				; apply timeout (2)
		BNE ss_time		; not expired yet (3/2)
	_DR_ERR(TIMEOUT)	; no timely reply
; put byte into SR and that clears flag
ss_free:
	DEC ss_stat		; sending in progress
; set appropriate mode
	LDA VIA+ACR		; get previous state
	ORA #$1C		; SR bits are all ones
	STA VIA+ACR		; shift-out under external clock
; put character
	LDA zpar		; get char to be sent
	STA VIA+VSR		; put into register
; pulse out CA2 and we're done
	LDA VIA+PCR		; get previous state
	PHA				; store for later
	AND #$F1		; mask out CA2 bits
	ORA #%1100		; CA2 low
	STA VIA+PCR		; will go for 6 clocks
	ORA #%1110		; CA2 hi, could use %0010 as well
	STA VIA+PCR		; CA2 is pulsed
	PLA				; get previous PCR
	STA VIA+PCR		; restore it
	_DR_OK

; *** input ***
ss_cin:
	LDX ss_cont		; number of characters in buffer
	BNE ss_some		; not empty
		_ERR(EMPTY)		; mild error otherwise
ss_some:
	LDA ss_read		; position to be read from buffer
	AND #$0F		; modulo-16, new 20150211
	TAX
	LDA ss_buf, X	; gets char stored at buffer
	STA zpar		; output value
	INX				; advance to next position
	STX ss_read		; update pointer
	DEC ss_cont		; one less
	LDA ss_cont		; check current size
	CMP #15			; room for one, at last?
	BMI	ss_ok		; nothing pending, I hope
		LDA ss_stat		; check if there was an operation in progress
			BEQ ss_ok		; nothing in progress
			BPL ss_shift	; get the pending byte, if receiving
ss_ok:
ss_full:
	_DR_OK

; *** request ***
ss_rcp:
; check whether the IRQ comes from CA2 (something to receive) or SR (shift completed)
	LDA VIA+IFR		; interrupt flags (4)
	LSR				; get IFR0 (CA2) on C (2)
		BCS ss_get		; something TO BE received (2/3 + 2*2)
	LSR
	LSR
		BCC ss_end	; no shift completed, nothing to do (2/3)
; shift completed
; clear SR flag
	LDA #$04		; clear IFR2 (SR) (2)
	STA VIA+IFR		; set 1 to _clear_ (4)
	LDA ss_stat		; was sending or receiving? (4)
	BMI ss_sent		; sending, nothing more to do (2/3)
; get received character and store it into buffer
		LDA ss_write	; position to be written on buffer (4)
		AND #$0F		; modulo-16, new 20150211 (2+2)
		TAX
		LDA VIA+VSR		; load received value (4)
		STA ss_buf, X	; store char from A into buffer (4)
		INX				; advance to next position (2)
		STX ss_write	; update pointer (4)
		INC ss_cont		; one more (6)
ss_sent:
; turn off SR, new 20150213
	LDA VIA+ACR		; get previous state
	AND #$E7		; mask out SR bits
	STA VIA+ACR		; shift register disabled
	_STZA ss_stat	; operation finished (4)
; ******* this has to be revised for the new macros ***********
ss_err:
	SEC				; C=1 means driver satisfied (2)
ss_end:
	RTS				; C=0 means go for next driver in queue (6)
ss_get:
; clear CA2 flag
	LDA #$01		; clear IFR0 (CA2) (2)
	STA VIA+IFR		; set 1 to _clear_ (4)
; wait for no operations in progress
	LDX #91			; load timeout counter (91x11 = 1 ms @ 1 MHz) (2)
	CLI				; enable interrupts _within_ the ISR (2)
ss_wait:
		LDA ss_stat		; check availability (4)
			BEQ ss_rdy		; proceed if available (2/3)
		DEX				; apply timeout (2)
		BNE ss_wait		; not expired yet (3/2)
; ******* revise *********
	SEC				; no timely reply (2)
	RTS				; C=1 means driver satisfied (6)
ss_rdy
	INC ss_stat		; something to be received (6)
	LDX ss_cont		; number of characters in buffer (4)
	CPX #16			; already full? (2)
		BPL ss_err		; no room (2/3)
ss_shift:
; the reception itself
	LDA ss_speed	; get speed value
	STA VIA+T2CL
	LDA VIA+ACR		; get previous state (4)
	AND #$E7		; mask out SR bits (2)
	ORA #$08		; shift-in under T2 (2+4)
	STA VIA+ACR		; start shifting!
	BNE ss_err		; no need for BRA, but wait for the shifting to end!

; *** shutdown ***
ss_bye:
	LDA #$05		; disable CA2 and SR interrupts
	STA VIA+IER
	STA VIA+IFR		; clear IFR2 (SR) and IFR0 (CA2) flags, just in case
	_BRA ss_sent	; disable SR and go away
