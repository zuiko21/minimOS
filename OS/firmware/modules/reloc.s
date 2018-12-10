; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181210-1042

; *** relocate a 65(C)02-based kernel ***
; interface TBD
; * new, ready for dynamic kernels! *

#ifdef	DYNKERN
	LDY #<sysvars		; note beginning of kernel space
	LDA #>sysvars
	STY 			; store as parameter
	STA +1
#endif
