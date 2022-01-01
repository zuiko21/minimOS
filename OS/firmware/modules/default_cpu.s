; firmware module for minimOS·65
; (c) 2017-2022 Carlos J. Santisteban
; last modified 20171221-1324

; *** set default CPU type ***
; NMOS and 65816 savvy
; alters fw_cpu

	LDA #CPU_TYPE		; from options.h (2)
	STA fw_cpu			; store variable (4)
