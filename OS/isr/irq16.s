; ISR for minimOS·16
; v0.6b2, should match kernel16.s
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180212-0926

#define		ISR		_ISR

#include "usual.h"

; **********************
; **** the ISR code **** (initial tasks take 28 cycles)
; **********************
	.al: .xl: REP #$38		; status already saved, but save register contents in full (3)
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
; might use firmware call IRQ_SRC for complete generic kernel!
	BIT VIA_J+IFR			; much better than LDA + ASL + BPL! (4)
		BVS periodic			; from T1 (3/2)

; ** generic alternative **
;	ADMIN(IRQ_SRC)			; get source in X
;	JMP (irq_tab, X)		; do as appropriate
;irq_tab:
;	.word	periodic
;	.word	asynchronous

; *********************************
; *** async interrupt otherwise *** (arrives here in 34 cycles if optimised)
; *********************************
; execute D_REQ in drivers (7 if nothing to do, ?+?*number of drivers until one replies, plus inner codes)
asynchronous:
	LDX queue_mx			; get async queue size (4)
	BEQ ir_done				; no drivers to call (2/3)
i_req:
		LDA drv_a_en-2, X	; *** check whether enabled, note offset, new in 0.6 ***
		BPL i_rnx			; *** if disabled, skip this task ***
			PHX						; keep index! (3)
			JSR (drv_asyn-2, X)	; call from table (8+...) expected to return in 8-bit size, at least indexes
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
	LDA VIA_J+T1CL			; acknowledge periodic interrupt!!! (4) *** IRQ_SRC should have done it already, if used

; *** scheduler no longer here, just an optional driver! But could be placed here for maximum performance ***

; execute D_POLL code in drivers
; 7 if nothing to do, typically ? clocks per entry (not 62!) plus inner codes
	LDX queue_mx+1			; get queue size (4)
	BEQ ip_done				; no drivers to call (2/3)
i_poll:
		DEX						; go backwards to be faster! (2+2)
		DEX						; no improvement with offset, all of them will be called anyway
		LDY drv_p_en, X			; *** check whether enabled, new in 0.6 ***
			BPL i_pnx				; *** if disabled, skip this task ***
		.al: REP #$20			; *** 16-bit memory for counters ***
		DEC drv_cnt, X			; otherwise continue with countdown
		BNE i_pnx				; did not expire, do not execute yet
			LDA drv_freq, X			; otherwise get original value...
			STA drv_cnt, X			; ...and reset it! eeeeeeeeeeeeeeek
			.as: .xs: SEP #$30		; make sure...
			PHX						; keep index! (3)
			JSR (drv_poll, X)		; call from table (8...)
; *** here is the return point needed for B_EXEC in order to create the stack frame ***
isr_schd:					; *** take this standard address!!! ***
			PLX						; restore index (4)
i_pnx:
		BNE i_poll				; until zero is done (3/2)
ip_done:
; update uptime, new simpler format is 12b, 14 or 24 cycles!
	.al: REP #$20			; worth switching to 16-bit size (3)
	INC ticks				; increment uptime count, new format 20161006 (8)
		BNE isr_done			; no wrap yet *** revise for load balancing (3/2)
	INC ticks+2				; increment the rest (8)
 	BRA isr_done			; go away (3)

; *******************
; *** BRK handler *** should move this to kernel or rom.s
; *******************
supplied_brk:				; this has a separate handler on FW, ends in RTS
#include "isr/brk16.s"
