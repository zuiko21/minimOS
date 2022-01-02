; firmware module for minimOS·65
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20220102-1721

; *** vectored call to IRQ handler ***
; NMOS and 65816 savvy
; no interface needed

	JMP (fw_isr)		; vectored ISR (6)
