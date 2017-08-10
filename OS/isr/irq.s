; ISR for minimOS
; v0.6a3, should match kernel.s
; features TBD
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20170810-1428

#define		ISR		_ISR

#include "usual.h"

; *** interrupt service routine performance ***
; _minimum_ overhead for periodic interrupt with no drivers in queue is * clocks, or * each second
; fastest asynchronous interrupt is reached in * clocks
; BRK is handled within * clocks, and spurious interrupts take *, all if no drivers in async queue
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
	LDX queues_mx	; get queue size (4)
	BEQ ir_done		; no drivers to call (2/3)
i_req:
		LDA drv_r_en-2, X	; *** check whether enabled, note offset, new in 0.6 ***
		BPL i_rnx			; *** if disabled, skip this task ***
			_PHX				; keep index! (3)
			JSR ir_call			; call from table (12...)
			_PLX				; restore index (4)
				BCC isr_done		; driver satisfied, thus go away NOW, BCC instead of BCS 20150320 (2/3)
i_rnx:
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
second:
isr_done:
	_PLY	; restore registers (3x4 + 6)
	_PLX
	PLA
	RTI

; routines for indexed driver calling
ir_call:
	_JMPX(drv_asyn-2)	; address already computed, no return here, new offset 20151029
ip_call:
	_JMPX(drv_poll)

; *** here goes the periodic interrupt code *** (4)
periodic:
	LDA VIA+T1CL		; acknowledge periodic interrupt!!! (4)

; *** scheduler no longer here, just an optional driver! But could be placed here for maximum performance ***

; execute D_POLL code in drivers
; 7 if nothing to do, typically ? clocks per entry (not 62!) plus inner codes
	LDX queue_mx+1		; get queue size (4)
	BEQ ip_done			; no drivers to call (2/3)
i_poll:
		DEX					; go backwards to be faster! (2+2)
		DEX					; no improvement with offset, all of them will be called anyway
		LDA drv_p_en, X		; *** check whether enabled, new in 0.6 ***
			BPL i_pnx			; *** if disabled, skip this task ***
		DEC drv_cnt, X		; otherwise continue with countdown
			BNE i_pnx			; LSB did not expire, do not execute yet
		DEC drv_cnt+1, X	; check now MSB, note value should be ONE more!
		BNE i_pnx			; keep waiting...
			LDY drv_freq, X		; ...or pick original value...
			LDA drv_freq+1, X
			STY drv_cnt, X		; ...and reset it!
			STA drv_cnt+1, X
			_PHX				; keep index! (3)
			JSR ip_call			; call from table (12...)
	; *** here is the return point needed for B_EXEC in order to create the stack frame ***
isr_schd:				; *** take this standard address!!! ***
			_PLX				; restore index (4)
i_pnx:
		BNE i_poll			; until zero is done (3/2)
ip_done:
; update uptime was usually 15 up to 29, each second will be 53...66, 45 bytes
; new format 20161006 makes it 20-35, each second will be 51...64, but 43 bytes
	INC ticks			; decrease uptime count (6)
	BNE isr_nw			; did not wrap (3/2)
		INC ticks+1			; otherwise carry (6)
isr_nw:
	LDA ticks			; check LSB first (4)
	CMP irq_freq		; possible end? (4)
		BNE isr_done		; no second completed yet *** revise for load balancing (3/2)
	LDA ticks+1			; go for MSB (4)
	CMP irq_freq+1		; second completed? (4)
		BNE isr_done		; no second completed yet *** revise for load balancing (3/2)
	_STZA ticks			; otherwise reset values (4+4)
	_STZA ticks+1
	INC ticks+2			; one more second (6)
		BNE second			; no wrap (3/2)
	INC ticks+3			; 256 more seconds (6)
		BNE second			; no wrap (3/2)
	INC ticks+4			; 64k more seconds (6)
	_BRA isr_done		; go away (3)

; *** BRK handler ***
brk_handler:			; should end in RTS anyway, 20160310
; ********** should use new firmware interface  ***********
#include "isr/brk.s"


