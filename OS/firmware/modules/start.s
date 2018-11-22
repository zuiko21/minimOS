; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181122-2339

; *** start a 65(C)02-based kernel ***
; no interface needed, uses fw_warm var
; * new, ready for dynamic kernels! *
; NMOS savvy

#ifdef	DYNKERN
	LDY #<sysvars		; note beginning of kernel space
	LDA #>sysvars
	STY sysptr		; store as obscure parameter, just in case
	STA sysptr+1
#endif
	JMP (fw_warm)		; (6)
