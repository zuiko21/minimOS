; firmware module for minimOS·65
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20180201-1403

; *** vectored call to IRQ handler ***
; NMOS and 65816 savvy
; no interface needed

-irq:
	JMP (fw_isr)		; vectored ISR (6)
