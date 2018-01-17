; standard NMI handler for minimOS·16 firmware
; v0.6a3
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180117-1339

; in case of standalone assembly
#include "usual.h"

; placeholder, just enable interrupts and return
	TSX				; get current stack pointer
	LDA $010E, X	; in order to get P from the stack (proper 16-bit stackframe)
	AND #%11110011	; remove interrupt mask & decimal mode bits
	STA $010E, X	; ints will be restored upon exit
	RTL				; back to handler end, hopefully everything settled now
; 65816 should use RTL but as long as it is in bank 0, it is OK
; however, as this peeks into stack, a proper 16-bit version is needed
