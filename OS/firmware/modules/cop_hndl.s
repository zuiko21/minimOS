; firmware module for minimOS·16
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180201-1417

; *** vectored call to COP handler, kernel entry point ***
; 65816 version, long addressing
; X holds function number, as usual
; C flag must be clear!

-cop_hndl:				; label from vector list
	.as: .xs: SEP #$30	; standard sizes
	JMP (fw_table, X)	; the old fashioned way
