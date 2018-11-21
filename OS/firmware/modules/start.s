; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181121-1750

; *** start a 65(C)02-based kernel ***
; no interface needed, uses fw_warm var
; * new, ready for dynamic kernels! *
; NMOS savvy

	LDY #<sysvars		; note beginning of kernel space
	LDA #>sysvars
	STY sysptr		; store as obscure parameter, just in case
	STA sysptr+1
	JMP (fw_warm)		; (6)
