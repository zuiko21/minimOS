; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181210-1013

; *** relocate a 65(C)02-based kernel ***
; interface TBD
; * new, ready for dynamic kernels! *

#ifdef	DYNKERN
	LDY #<sysvars		; note beginning of kernel space
	LDA #>sysvars
	STY sysptr			; store as obscure parameter, just in case
	STA sysptr+1
#endif
	JMP (fw_warm)		; (6)
