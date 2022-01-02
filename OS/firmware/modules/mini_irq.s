; minimal ISR for minimOS
; v0.6.1a2, should match kernel.s
; (c) 2019-2022 Carlos J. Santisteban
; last modified 20211227-1735


.(
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
; ...this is BRK, thus must emulate NMI stack frame -- but in the handler itself!
; a feasible way would be reusing some 65816 vector pointing to (FW) brk_hndl
		JMP (brk_02)	; reuse some hard vector (will return via nmi_end or handler itself)
; *** continue if no BRK was issued ***
+non_brk:				; sort of standard label as used by BRK handler
	_PLY				; restore registers (3x4 + 6)
	_PLX
	PLA
	RTI

; **********************************
; *** resume normal installation ***
; **********************************
mirq_end:
.)
