; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20180811-1258

; *** generic BRK handler for 65(C)02 ***
; **** preliminary, 65816-like code ****
; NMOS-savvy

-brk_hndl:				; label from vector list
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
	JSR brk_call		; indirect jump will return here
; *** restore reserved vars since 20180811 ***
	PLA
	STA systmp
	PLA
	STA sysptr+1
	PLA
	STA sysptr
; restore full status and exit
	_PLY				; restore status and return (3x4)
	_PLX
	PLA
	RTI
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return
.)
