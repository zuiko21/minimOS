; firmware module for minimOS·16
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20180201-1411

; *** vectored call to IRQ handler ***
; 65816 version, long addressing
; no interface needed

-irq:
	JMP [fw_isr]		; 24-bit vectored ISR (6)
