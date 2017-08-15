; BRK handler for minimOS·16
; v0.6a1
; (c) 2016-2017 Carlos J. Santisteban
; last modified 20170815-1757

; old handler as a placeholder, should end in RTS
	.as: .xs: SEP #$30		; back to old 8-bit size, just in case
#include "isr/brk.s"
