; ISR for minimOS·16
; v0.5.1a1, should match kernel16.s
; features TBD
; (c) 2016 Carlos J. Santisteban
; last modified 20161003-1109

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

; performance for maximum priority async routine = 39 clocks!
; **** the ISR code **** (initial tasks take 18 clocks)
	.al: .xl: REP $30		; status already saved, but save register contents in full (3)
	PHA						; save registers (3x4)
	PHX
	PHY
	.as: .xs: SEP $30		; back to 8-bit size (3)

; *** place here HIGH priority async tasks, if required ***

; check whether jiffy or async (7 if periodic, 6 if async)
	BIT VIA_J+IFR			; much better than LDA + ASL + BPL! (4)
		BVS periodic			; from T1 (3/2)

; *** async interrupt otherwise ***
; execute D_REQ in drivers (7 if nothing to do, 6+22*number of drivers until one replies, plus inner codes)
	LDX dreq_mx				; get queue size (4)
	BEQ ir_done				; no drivers to call (2/3)
i_req:
		PHX						; keep index! (3)
		JSR (drv_async-2, X)	; call from table (6+...) expected to return in 8-bit size, at least indexes
		PLX						; restore index (4)
			BCC isr_done			; driver satisfied, thus go away NOW, BCC instead of BCS 20150320 (2/3)
		DEX						; go backwards to be faster! (2+2)
		DEX						; decrease after processing, negative offset on call, less latency, 20151029
		BNE i_req				; until zero is done (3/2)
ir_done:					; otherwise is spurious, due to separate BRK handler on 65816
isr_done:
	.al: .xl: REP $30		; restore saved registers in full, just in case (3)
	PLY						; restore registers (3x5 + 6)
	PLX
	PLA
	RTI						; this will restore appropriate register size

; routines for indexed driver calling
is_call:
	_JMPX(drv_sec)

; *** here goes the periodic interrupt code *** (4)
periodic:
	LDA VIA_J+T1CL			; acknowledge periodic interrupt!!! (4)

; *** scheduler no longer here, just an optional driver! But could be placed here for maximum performance ***

; execute D_POLL code in drivers
; 7 if nothing to do, typically 6+26 clocks per entry (not 62!) plus inner codes
	LDX dpoll_mx			; get queue size (4)
	BEQ ip_done				; no drivers to call (2/3)
i_poll:
		DEX						; go backwards to be faster! (2+2)
		DEX						; no improvement with offset, all of them will be called anyway
		PHX						; keep index! (3)
		JSR (drv_poll, X)		; call from table (6...)
; *** here is the return point needed for B_EXEC in order to create the stack frame ***
isr_sched_ret:					; *** take this standard address!!! ***
		PLX						; restore index (4)
		BNE i_poll				; until zero is done (3/2)
ip_done:
; update uptime
; new 65816 code is 22+2 bytes, worse case 44+3 clocks, best 17 clocks!
	.al: REP $20			; worth switching to 16-bit size (3)
	DEC ticks				; decrement uptime count (8)
	CMP #$FFFF				; wrapped? (3) is this correct of BNE will suffice???
		BNE isr_done			; no second completed yet *** revise for load balancing (3/2)
	LDA irq_freq			; get whole word (5)
	STA ticks				; jiffy counter lower word updated (5)
	INC ticks+2				; one more second (8)
		BNE second				; no wrap (3/2)
	INC ticks+4				; 64k more seconds (8)

; execute D_SEC code if applies, take it much easier! (7 if none, 5+26*drivers, plus inner codes)
; to be done - balancing into, say, 8 time slots
second:
	.as: SEP $30			; back to 8-bit memory (and indexes, just in case)
	LDX dsec_mx				; get queue size (4)
		BEQ isr_done			; no drivers to call (2/3)
i_sec:
		DEX						; go backwards to be faster! (2x2)
		DEX
		PHX						; keep index! (3)
		JSR (drv_sec, X)		; call from table (6...)
		PLX						; restore index (4)
		BNE i_sec				; until zero is done (3/2)
	BEQ isr_done			; go away, no need for BRA if not called from elsewhere (3)

; *** BRK handler ***
brk_handler:				; this has a separate handler, check compatible label in firmware
#include "isr/brk16.s"


