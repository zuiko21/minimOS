; SS-22 driver for minimOS
; v0.5b1
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20150323-1102
; revised 20160928

; in case of standalone assembly via 'xa drivers/drv_ss22.s'
#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
; specific header for this driver
#include "drivers/drv_ss22.h"
.text
#endif

; *** begins with sub-function addresses table ***
	.byt	DEV_SS22					; D_ID, new format 20150323, TBD
	.byt	A_REQ + A_CIN + A_COUT		; no poll, by request, I/O, no 1-sec nor block transfers, non-relocatable (NEW)
	.word	ss_init	; initialize VIA and appropiate sysvars, called by POST only
	.word	ss_full	; nothing periodic to do
	.word	ss_rcp	; IRQ whenever Tx wants to send (start receiving) OR a character fully arrived (put it into buffer)
	.word	ss_cin	; input from buffer
	.word	ss_cout	; output via SS-22 (unbuffered)
	.word	ss_full	; NEW, no need for 1-second interrupt
	.word	ss_full	; NEW, no block input
	.word	ss_full	; NEW, no block output
	.word	ss_bye	; shutdown procedure, new 20150305
	.word	ss_info	; D_INFO string
	.byt	0		; D_MEM reserved

; *** info string ***
ss_info:
	.asc	"SS-22 driver v0.5b1", 0

; *** initialise ***
; new code, taken from async version 20150304
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
	LDA #$81		; enable CA2 interrupt ONLY (unlike the async version)
	STA VIA+IER
	_DR_OK			; won't fail, but strict kernel needs this

; *** output ***
ss_cout:
; ** ensure PB7 is hi to make it silent **
	LDA VIA+IORB	; get current value
	ORA #$80		; set bit 7
	STA VIA+IORB	; alter output
; wait for no operations in progress (?)
	LDX #91		; load timeout counter (91x11 = 1 ms @ 1 MHz)
ss_time:
		LDA ss_stat		; check availability (4)
			BEQ ss_free		; proceed if available (2/3)
		DEX				; apply timeout (2)
		BNE ss_time		; not expired yet (3/2)
	_DR_ERR(TIMEOUT)	; no timely reply
ss_free:
	DEC ss_stat		; sending in progress
; put byte into SR and that clears flag
	LDA zpar		; get char to be sent
	STA VIA+SR		; put into register
; set appropriate mode
	LDA VIA+ACR		; get previous state
	ORA #$1C		; SR bits are all ones
	STA VIA+ACR		; shift-out under external clock
; pulse out CA2 and wait
	LDA VIA+PCR		; get previous state
	TAX				; store for later, slight optimization 20150305
	AND #$F1		; mask out CA2 bits
	ORA #%1100		; CA2 low
	STA VIA+PCR		; will go for 6 clocks
	ORA #%1110		; CA2 hi, could use %0010 as well
	STA VIA+PCR		; CA2 is pulsed
	TXA				; get previous PCR
	STA VIA+PCR
; peace of mind approach
	LDX #77		; load timeout counter (77x13 = 1 ms @ 1 MHz)
ss_comp:
		LDA VIA+IFR		; check availability (4)
		AND #$04		; IFR2, already shifted (2)
			BNE ss_done		; exit if finished (2/3)
		DEX				; apply timeout (2)
		BNE ss_comp		; not expired yet (3/2)
	_DR_ERR(TIMEOUT)	; no timely reply
ss_done:
; turn off SR and we're done
	LDA VIA+ACR		; get previous state
	AND #$E7		; mask out SR bits
	STA VIA+ACR		; shift register disabled
	_STZA ss_stat	; operation finished (4)
	_DR_OK

; *** input ***
ss_cin:
	LDX ss_cont		; number of characters in buffer
	BNE ss_some		; not empty
		_DR_ERR(EMPTY)		; mild error otherwise
ss_some:
	LDA ss_read		; position to be read from buffer
	AND #$0F		; modulo-16, new 20150211
	TAX
	LDA ss_buf, X	; gets char stored at buffer
	STA zpar		; output value
	INC ss_read		; advance to next position, same time, saves one byte
	DEC ss_cont		; one less
	LDA ss_cont		; check current size
	CMP #15			; room for one at last?
	BMI	ss_ok		; nothing pending, I hope
		LDA ss_stat		; check if anything in progress
	BEQ ss_ok		; nothing pending
	BMI ss_ok		; sending anyway
		JSR ss_get2		; otherwise, do receive at last!
		CLI				; enable interrupts after that! **** always???
ss_ok:
	_DR_OK

; *** request ***
ss_rcp:
; check whether the IRQ comes from CA2 (something to receive), SR is ignored here
	LDA VIA+IFR		; interrupt flags (4)
	LSR				; get IFR0 (CA2) on C (2)
	BCS ss_sent		; something TO BE received (2/3)
ss_end:	; **** is this really needed???
		_NEXT			; go away otherwise, new format
ss_sent:
; wait for no operations in progress (?)
	LDX #91			; load timeout counter (91x11 = 1 ms @ 1 MHz)
	CLI				; enable interrupts for a moment ***** revise
ss_hold:
		LDA ss_stat		; check availability (4)
			BEQ ss_get		; proceed if available (2/3)
		DEX				; apply timeout (2)
		BNE ss_hold		; not expired yet (3/2)
	_BRA ss_full	; go away for now
ss_get:
	INC ss_stat		; reception in progress (6)
ss_get2:
	SEI				; back to normal
	LDX ss_cont		; number of characters in buffer (4)
	CPX #16			; already full? might check against a lower value (2)
		BPL ss_full		; (2/3)
; clear flags
	LDA #$05		; clear IFR0 (CA2) and IFR2 (SR) (2)
	STA VIA+IFR		; set 1 to _clear_ (4)
; get ready to receive
	LDA ss_speed	; get speed value
	STA VIA+T2CL
	LDA VIA+ACR		; get previous state (4)
	AND #$E7		; mask out SR bits (2)
	ORA #$08		; shift-in under T2 (2+4)
	STA VIA+ACR		; start shifting!
; busy wait approach
ss_wait:
		LDA VIA+IFR		; check availability (4)
		AND #$04		; IFR2, already shifted (2)
		BEQ ss_wait		; no need for BRA (3/2) slight optimization 20150304
ss_into: 
; get received character and store it into buffer
	LDA ss_write	; position to be written on buffer (4)
	AND #$0F		; modulo-16, new 20150211 (2+2)
	TAX
	LDA VIA+SR		; load received value (4)
	STA ss_buf, X	; store char from A into buffer (4)
	INC ss_write	; advance to next position (6)
	INC ss_cont		; one more (6)
; turn off SR and we're done
ss_off:
	LDA VIA+ACR		; get previous state
	AND #$E7		; mask out SR bits
	STA VIA+ACR		; shift register disabled
	_STZA ss_stat	; operation finished (4)
ss_full:
	_DR_OK			; driver satisfied, new format

; *** shutdown ***
ss_bye:
	LDA #$05		; disable CA2 and SR interrupts
	STA VIA+IER
	STA VIA+IFR		; clear IFR2 (SR) and IFR0 (CA2) flags, just in case
	BNE ss_off		; no need for BRA, disable SR and go away
