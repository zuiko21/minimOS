; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20180906-1707

; *** generic BRK handler for 65(C)02 ***
; **** preliminary, 65816-like code ****
; NMOS-savvy

-brk_hndl:				; label from vector list
.(
#ifdef	NMOS
	CLD					; eeeeeeeeeeeeeeeek
#endif
tsx
lda$103,x:jsr debug_hex
lda$102,x:jsr debug_hex
lda$101,x:jsr debug_hex

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
; common code ending from FW NMI handler!
	JMP nmi_end
; *** entry point, assume std return address on stack ***
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return
.)
