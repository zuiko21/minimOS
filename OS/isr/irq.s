; ISR for minimOS
; v0.5b4, should match kernel.s
; features TBD
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160412-0952

#define		ISR		_ISR

; in case of standalone assembly from 'xa isr/irq.s'
#ifndef		KERNEL
#define		KERNEL	_IRQ
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"	; generic filename
#include "sysvars.h"
.text
* = ROM_BASE
#endif

; *** interrupt service routine performance ***
; _minimum_ overhead for periodic interrupt with no drivers in queue is 62 clocks, or 107 each second
; fastest asynchronous interrupt is reached in 42 clocks
; BRK is handled within 37 clocks, and spurious interrupts take 35, all if no drivers in async queue
; *********************************************

; **** the ISR code **** (11)
#ifdef	NMOS
	CLD						; NMOS only, 20150316, conditioned 20151029 (2)
#endif
	PHA						; save registers (3x3)
	_PHX
	_PHY

; *** place here HIGH priority async tasks, if required ***

; check whether from VIA, BRK... (7 if periodic, 6 if async)
	BIT VIA+IFR				; much better than LDA + ASL + BPL! (4)
		BVS periodic		; from T1 (3/2)

; *** async interrupt otherwise ***
; execute D_REQ in drivers (7 if nothing to do, 3+28*number of drivers until one replies, plus inner codes)
	LDX dreq_mx		; get queue size (4)
	BEQ ir_done		; no drivers to call (2/3)
i_req:
		_PHX				; keep index! (3)
		JSR ir_call			; call from table (12...)
		_PLX				; restore index (4)
			BCC isr_done		; driver satisfied, thus go away NOW, BCC instead of BCS 20150320 (2/3)
		DEX					; go backwards to be faster! (2+2)
		DEX					; decrease after processing, negative offset on call, less latency, 20151029
		BNE i_req			; until zero is done (3/2)
ir_done:
; lastly, check for BRK (11 if spurious, 13+BRK handler if requested)
	TSX					; get stack pointer (2)
	LDA $0104, X		; get saved PSR (4)
	AND #$10			; mask out B bit (2)
	BEQ isr_done		; spurious interrupt! (2/3)
		JSR brk_handler		; BRK otherwise (6/0)
; go away (18 total)
isr_done:
	_PLY	; restore registers (3x4 + 6)
	_PLX
	PLA
	RTI

; routines for indexed driver calling
ir_call:
	_JMPX(drv_async-2)	; address already computed, no return here, new offset 20151029
ip_call:
	_JMPX(drv_poll)
is_call:
	_JMPX(drv_sec)

; *** here goes the periodic interrupt code *** (4)
periodic:
	LDA VIA+T1CL		; acknowledge periodic interrupt!!! (4)

; *** scheduler no longer here, just an optional driver! But could be placed here for maximum performance ***

; execute D_POLL code in drivers
; 7 if nothing to do, typically 6+26 clocks per entry (not 62!) plus inner codes
	LDX dpoll_mx		; get queue size (4)
	BEQ ip_done			; no drivers to call (2/3)
i_poll:
		DEX					; go backwards to be faster! (2+2)
		DEX					; no improvement with offset, all of them will be called anyway
		_PHX				; keep index! (3)
		JSR ip_call			; call from table (12...)
; *** here is the return point needed for B_EXEC in order to create the stack frame ***
isr_sched_ret:				; *** take this standard address!!! ***
		_PLX				; restore index (4)
		BNE i_poll			; until zero is done (3/2)
ip_done:
; update uptime (usually 15 up to 29, each second will be 53...66)
	DEC ticks			; decrease uptime count (6)
	LDA ticks			; get for comparison (4)
	CMP #$FF			; wrapped? (2)
		BNE isr_done		; no second completed yet *** revise for load balancing (3/2)
	DEC ticks+1			; decrease MSB (6)
	LDA ticks+1			; compare it (4)
	CMP #$FF			; wrapped? (2)
		BNE isr_done		; no second completed yet *** revise for load balancing (3/2)
	LDY irq_freq		; get final value (4)
	LDA irq_freq+1		; same for MSB (4)
	STY ticks			; set values (4+4)
	STA ticks+1
	INC ticks+2			; one more second (6)
		BNE second			; no wrap (3/2)
	INC ticks+3			; 256 more seconds (6)
		BNE second			; no wrap (3/2)
	INC ticks+4			; 64k more seconds (6)
; execute D_SEC code if applies, take it much easier! (7 if none, 5+26*drivers, plus inner codes)
; to be done - balancing into, say, 8 time slots
second:
	LDX dsec_mx			; get queue size (4)
		BEQ isr_done		; no drivers to call (2/3)
i_sec:
		DEX					; go backwards to be faster! (2x2)
		DEX
		_PHX				; keep index! (3)
		JSR is_call			; call from table (12...)
		_PLX				; restore index (4)
		BNE i_sec			; until zero is done (3/2)
	BEQ isr_done		; go away, no need for BRA if not called from elsewhere (3)

; *** BRK handler ***
brk_handler:			; should end in RTS anyway, 20160310
#include "isr/brk.s"


