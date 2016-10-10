; BRK handler for minimOS·16
; v0.5.1a1
; (c) 2016 Carlos J. Santisteban
; last modified 20161010-1320

; old handler as a placeholder, should end in RTS
	.as: .xs: SEP #$30		; back to old 8-bit size, just in case
#include "isr/brk.s"
