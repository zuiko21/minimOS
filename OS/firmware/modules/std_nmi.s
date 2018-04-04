; standard NMI handler for minimOS firmware
; v0.6a3
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180404-1358

; in case of standalone assembly
#ifndef	HEADERS
#include "../usual.h"
#endif

; placeholder, just enable interrupts and return
	TSX				; get current stack pointer
	LDA $010A, X	; in order to get P from the stack (jsr, 4@sysptr, 4regs!)
	AND #%11110011	; remove interrupt mask & decimal mode bits
	STA $010A, X	; ints will be restored upon exit
	RTS				; back to handler end, hopefully everything settled now
; as all 6502 code runs from bank 0, RTS is OK thru 65816 firmware...
; however, as this peeks into stack, this is only 8-bit FW compatible
