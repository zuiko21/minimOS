; standard NMI handler for minimOS firmware
; v0.6a1
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20170602-0859

; in case of standalone assembly
#ifndef		FIRMWARE
#include "options.h"
#include "macros.h"
.text
#endif

; placeholder, just enable interrupts and return
	TSX				; get current stack pointer
	LDA $010A, X	; in order to get P from the stack (jsr, 4@sysptr, 4regs!)
	AND #%11110011	; remove interrupt mask & decimal mode bits
	STA $010A, X	; ints will be restored upon exit
	RTS				; back to handler end, hopefully everything settled now
