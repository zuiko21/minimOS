; firmware module for minimOS·65
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20181210-1014

; *** start a 65(C)02-based kernel ***
; no interface needed, uses fw_warm var
; NMOS savvy

	JMP (fw_warm)		; (6)
