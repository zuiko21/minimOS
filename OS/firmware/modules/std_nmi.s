; standard NMI handler for minimOS firmware
; v0.5a3
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160309-0954

; in case of standalone assembly
#ifndef		FIRMWARE
#include "options.h"
#include "macros.h"
.text
#endif

; placeholder, just enable interrupts and return
	TSX				; get current stack pointer
	LDA $010A, X	; in order to get P from the stack (jsr, 4@sysptr, 4regs!)
	AND #%11111011	; remove interrupt mask bit
	STA $010A, X	; ints will be restored upon exit
	RTS				; back to handler end, hopefully everything settled now
