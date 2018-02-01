; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180201-1335

; *** set 65816 as standard CPU ***
; no interface needed!

	LDA #'V'			; 65816 only (2)
	STA fw_cpu			; store variable (4)
