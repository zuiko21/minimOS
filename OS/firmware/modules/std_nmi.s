; standard NMI handler for minimOS firmware
; v0.5a2
; (c) 2015 Carlos J. Santisteban
; last modified 20150216-1406

; in case of standalone assembly
#ifndef		FIRMWARE
#include "options.h"
#include "macros.h"
.text
#endif

-std_nmi:
	TSX				; get actual stack pointer
	LDA $0104, X	; in order to get P from the stack
	AND #%11111011	; remove interrupt mask bit
	STA $0104, X	; ints will be restored upon exit
	_PLY			; restore regs NEW
	_PLX
	PLA
	RTI				; go away, hopefully everything settled now
