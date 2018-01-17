; standard NMI handler for minimOS·16 firmware
; v0.6a3
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180117-1339

; in case of standalone assembly
#include "usual.h"

; placeholder, just enable interrupts and return
	TSX				; get current stack pointer
	LDA $010A, X	; in order to get P from the stack (jsr, 4@sysptr, 4regs!)
	AND #%11110011	; remove interrupt mask & decimal mode bits
	STA $010A, X	; ints will be restored upon exit
	RTL				; back to handler end, hopefully everything settled now
; 65816 should use RTL but as long as it is in bank 0, it is OK
; however, as this peeks into stack, a proper 16-bit version is needed
