; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20180201-1410

; *** start a 65(C)02-based kernel ***
; no interface needed, uses fw_warm var
; NMOS savvy

	JMP (fw_warm)		; (6)
