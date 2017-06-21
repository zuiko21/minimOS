; ISR for minimOS·16
; v0.6a2, should match kernel16.s
; (c) 2016-2017 Carlos J. Santisteban
; last modified 20170621-1401

#define		ISR		_ISR

#include "usual.h"

; fastest async routine runs after 53 clocks!
; **********************
; **** the ISR code **** (initial tasks take 21 clocks)
; **********************
	.al: .xl: REP #$30		; status already saved, but save register contents in full (3)
	PHA						; save registers (3x4)
	PHX
	PHY
	PHB						; eeeeeeeeeeeeeek (3)
	.as: .xs: SEP #$30		; back to 8-bit size (3)
; should preset DBR !!! (7)
	PHK						; zero into the stack (3)
	PLB						; no other way to set it (4)
; *** place here HIGH priority async tasks, if required ***

; check whether jiffy or async (7 if periodic, 6 if async)
; might use (future) firmware call IRQ_SOURCE for complete generic kernel!
BIT VIA_J+IFR			; much better than LDA + ASL + BPL! (4)
		BVS periodic			; from T1 (3/2)

; *********************************
; *** async interrupt otherwise *** (arrives here in 36 clocks)
; *********************************
; execute D_REQ in drivers (7 if nothing to do, ?+?*number of drivers until one replies, plus inner codes)
	LDX queues_mx			; get async queue size (4)
	BEQ ir_done				; no drivers to call (2/3)
i_req:
		LDA drv_r_en-2, X	; *** check whether enabled, note offset, new in 0.6 ***
		BPL i_rnx			; *** if disabled, skip this task ***
			PHX						; keep index! (3)
			JSR (drv_async-2, X)	; call from table (8+...) expected to return in 8-bit size, at least indexes
			PLX						; restore index (4)
				BCC isr_done			; driver satisfied, thus go away NOW (2/3)
i_rnx:
		DEX						; go backwards to be faster! (2+2)
		DEX						; decrease after processing
		BNE i_req				; until done (3/2)
ir_done:					; otherwise is spurious, due to separate BRK handler on 65816
isr_done:
	.al: .xl: REP #$30		; restore saved registers in full, just in case (3)
	PLB						; eeeeeeeeek (4)
	PLY						; restore registers (3x5 + 6)
	PLX
	PLA
	RTI						; this will restore appropriate register size

; *********************************************
; *** here goes the periodic interrupt code *** (4)
; *********************************************
periodic:
	LDA VIA_J+T1CL			; acknowledge periodic interrupt!!! (4) *** IRQ_SOURCE should have done it already, if used

; *** scheduler no longer here, just an optional driver! But could be placed here for maximum performance ***

; execute D_POLL code in drivers
; 7 if nothing to do, typically ? clocks per entry (not 62!) plus inner codes
	LDX queues_mx+1			; get queue size (4)
	BEQ ip_done				; no drivers to call (2/3)
i_poll:
		DEX						; go backwards to be faster! (2+2)
		DEX						; no improvement with offset, all of them will be called anyway
		LDY drv_p_en, X			; *** check whether enabled, new in 0.6 ***
			BPL i_pnx				; *** if disabled, skip this task ***
		.al: REP #$20			; *** 16-bit memory for counters ***
		DEC drv_count, X		; otherwise continue with countdown
		BNE i_pnx				; did not expire, do not execute yet
			LDA drv_freq, X			; otherwise get original value...
			STA drv_count, X		; ...and reset it! eeeeeeeeeeeeeeek
			.as: .xs: SEP #$30		; make sure...
			PHX						; keep index! (3)
			JSR (drv_poll, X)		; call from table (8...)
; *** here is the return point needed for B_EXEC in order to create the stack frame ***
isr_sched_ret:					; *** take this standard address!!! ***
			PLX						; restore index (4)
i_pnx:
		BNE i_poll				; until zero is done (3/2)
ip_done:
; update uptime
; new 65816 code was 22+2 bytes, worst case 44+3 clocks, best 17 clocks!
; now is 21+3 bytes, worst case 41+3 clocks, but best 19 clocks
	.al: REP #$20			; worth switching to 16-bit size (3)
	INC ticks				; increment uptime count, new format 20161006 (8)
	CMP irq_freq				; wrapped? (5)
		BCC isr_done			; no second completed yet *** revise for load balancing (3/2)
	STZ ticks				; jiffy counter lower word reset (5)
	INC ticks+2				; one more second (8)
		BNE isr_done			; no wrap (3/2)
	INC ticks+4				; 64k more seconds (8)
	BRA isr_done			; go away (3)

; *** BRK handler *** REVISE
brk_handler:				; this has a separate handler, check compatible label in firmware
#include "isr/brk16.s"
