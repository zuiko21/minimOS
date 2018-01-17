; standard NMI handler for minimOS·16 firmware
; v0.6a4
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180117-1440

; in case of standalone assembly
#include "usual.h"

; placeholder, just enable interrupts and return
	.xl: REP #$10		; *** 16-bit index ***
	TSX					; get current stack pointer, full 16-bit
	LDA $E, X			; in order to get P from the stack (proper 16-bit stackframe)
	AND #%11110011		; remove interrupt mask & decimal mode bits
	STA $E, X			; ints will be restored upon exit
	RTL					; back to handler end, hopefully everything settled now
; 65816 should use RTL but as long as it is in bank 0, it is OK
; however, as this peeks into stack, a proper 16-bit version is needed
