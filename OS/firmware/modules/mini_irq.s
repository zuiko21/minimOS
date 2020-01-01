; minimal ISR for minimOS
; v0.6.1a1, should match kernel.s
; (c) 2019-2020 Carlos J. Santisteban
; last modified 20190402-1227

#ifndef	HEADERS
#include "../usual.h"
#endif

; *** this will set the IRQ vector and skip the actual routine! ***
	LDY #<mini_irq		; get supplied routine
	LDA #>mini_irq
	STY fw_isr			; store for firmware (4+4)
	STA fw_isr+1
	JMP mirq_end		; resume boot process!

; ****************************
; *** the minimal ISR code ***
; ****************************
mini_irq:
#ifdef	NMOS
	CLD					; NMOS only (2)
#endif
	PHA					; save registers (3x3)
	_PHX
	_PHY				; not actually needed, but used on debugger stack frame
; then check for BRK
	TSX					; get stack pointer (2)
	LDA $0104, X		; get saved PSR (4)
	AND #$10			; mask out B bit (2)
	BEQ non_brk			; spurious interrupt! (2/3)
; ...this is BRK, thus must emulate NMI stack frame!
		LDA systmp			; save extended state (6x3)
		PHA
		LDA sysptr+1
		PHA
		LDA sysptr
		PHA
; a feasible way would be reusing some 65816 vector pointing to (FW) brk_hndl
		JMP (brk_02)		; reuse some hard vector (will return via NMI end)
; *** continue if no BRK was issued ***
non_brk:
	_PLY				; restore registers (3x4 + 6)
	_PLX
	PLA
	RTI

; **********************************
; *** resume normal installation ***
; **********************************
mirq_end:
