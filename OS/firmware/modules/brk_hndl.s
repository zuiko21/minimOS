; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181222-2154

; *** generic BRK handler for 65(C)02 ***
; NMOS-savvy

-brk_hndl:
.(
#ifdef	NMOS
	CLD					; eeeeeeeeeeeeeeeek
#endif

; much like the ISR start
	PHA					; save registers (3x3)
	_PHX
	_PHY
; *** now creates NMI-like stack frame, much easier on debuggers ***
	LDA sysptr			; save reserved stuff
	PHA
	LDA sysptr+1
	PHA
	LDA systmp
	PHA
; must use some new indirect jump, as set by new SET_BRK
; if managed from IRQ ISR, should it arrive here?
	JSR brk_call		; indirect jump will return here
; *** restore reserved vars since 20180811 ***
; common code ending from FW NMI handler!
	JMP nmi_end
; *** entry point, assume std return address on stack ***
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return
.)
