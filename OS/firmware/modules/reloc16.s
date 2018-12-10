; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20181210-1013

; *** start a 65816-based kernel ***
; interface TBD
; * new, ready for dynamic kernels! *

#ifdef	DYNKERN
	.al: REP #$20		; save a couple bytes by going 16-bit again
	LDA #sysvars		; beginning of kernel space
	STA sysptr		; obscure parameter, just in case
#endif
	SEC					; emulation mode for a moment (2+2)
	XCE
	.as
	JMP (fw_warm)		; any 16-bit kernel should get back into NATIVE mode (5)
