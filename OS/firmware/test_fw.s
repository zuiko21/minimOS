; minimal firmware for minimOS (testing!)
; v1.0
; (c)2016 Carlos J. Santisteban
; last modified 20161220-1212

; common headers
#ifndef	HEADERS
#include "usual.h"
kernel = ROM_BASE		; placeholder
#endif

* = FW_BASE			; this will be page-aligned!

; ***** start of simple firmware *****
reset:
	SEI					; cold boot, best assume nothing (2)
	CLD					; just in case, a must for NMOS (2)
; assume 65816 is in emulation mode!
	LDA #CPU_TYPE		; constant from options.h (2)
	STA fw_cpu			; store variable (4)
	LDY #<kernel		; get warm start pointer
	LDA #>kernel
	STY fw_warm			; store word
	STA fw_warm+1
	JMP (fw_warm)		; startup!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; ***** 64-byte standard block *****
; *** minimOS function call primitive ($FFC0) ***
* = kernel_call
	_JMPX(fw_table)		; macro for NMOS compatibility (6)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	_JMPX(fw_admin)		; takes 6 clocks with CMOS

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = lock
	SEC					; unified procedure 20150410, was CLV
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC
	NOP					; padding for reserved C816 vectors

; *** vectored IRQ handler ***
; since this will not be actually used, this location is safe for 65816 too
irq:
	JMP (fw_isr)		; vectored ISR (6)
nmi:
	JMP (fw_nmi)		; placeholder

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	$FFFA-*, $FF
#endif

; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; NMI	@ $FFFA
	.word	reset		; RST	@ $FFFC
	.word	irq			; IRQ	@ $FFFE
