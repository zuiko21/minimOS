; BRK handler for minimOS·16
; v0.6a2
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180404-1410

; old handler as a placeholder, should end in RTS
; RTL is the proper ending for 65816 BRK handlers,
; but as long as it is in bank 0, no problem
	.as: .xs		; already set in 8-bit sizes
#include "brk.s"
