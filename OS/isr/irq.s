; ISR for minimOS
; v0.6rc1, should match kernel.s
; features TBD
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20171031-1052

#define		ISR		_ISR

#include "usual.h"

; **** the ISR code **** (11)
#ifdef	NMOS
	CLD						; NMOS only, 20150316, conditioned 20151029 (2)
#endif
	PHA						; save registers (3x3)
	_PHX
	_PHY

; *** place here HIGH priority async tasks, if required ***

; check whether from VIA, BRK... (7 if periodic, 6 if async)

;	ADMIN(IRQ_SRC)			; check source, **generic way**
;	JMPX(irq_tab)			; do as appropriate
;irq_tab:
;	.word periodic			; standard jiffy
;	.word asyncronous		; async otherwise

; optimised, non-portable code
	BIT VIA+IFR				; much better than LDA + ASL + BPL! (4)
		BVS periodic		; from T1 (3/2)

; *** async interrupt otherwise ***
; execute D_REQ in drivers (7 if nothing to do, 3+28*number of drivers until one replies, plus inner codes)
asynchronous:
	LDX queue_mx	; get queue size (4)
	BEQ ir_done		; no drivers to call (2/3)
i_req:
		LDA drv_a_en-2, X	; *** check whether enabled, note offset, new in 0.6 ***
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
		LDY #PW_SOFT		; BRK otherwise (firmware interface)
		_ADMIN(POWEROFF)
; go away (18 total)
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
			LDA drv_freq, X		; ...or pick original value...
			STA drv_cnt, X		; ...and reset it!
			LDA drv_freq+1, X
			STA drv_cnt+1, X
			_PHX				; keep index! (3)
			JSR ip_call			; call from table (12...)
; *** here is the return point needed for B_EXEC in order to create the stack frame ***
isr_schd:				; *** take this standard address!!! ***
			_PLX				; restore index (4)
i_pnx:
		BNE i_poll			; until zero is done (3/2)
ip_done:
; update uptime, much faster new format
	INC ticks			; increment uptime count (6)
		BNE isr_done			; did not wrap (3/2)
	INC ticks+1			; otherwise carry (6)
		BNE isr_done			; did not wrap (3/2)
	INC ticks+2			; otherwise carry (6)
		BNE isr_done			; did not wrap (3/2)
	INC ticks+3			; otherwise carry (6)
	_BRA isr_done		; go away (3)

; *******************
; *** BRK handler ***
; *******************
; will be called via firmware interface, should be moved to kernel or rom.s

supplied_brk:			; should end in RTS anyway, 20160310
#include "isr/brk.s"
