; minimal nanoBoot firmware
; (c) 2018 Carlos J. Santisteban
; last modified 20180816-1817

#include "../../OS/macros.h"
#include "nanoboot.h"

; mimimal firmware variables?
* = $0200

fw_isr	.word	0
fw_nmi	.word	0

; *** ROM contents *** 256 bytes will suffice
* = $FF00

.text

; standard 6502 init...
reset:
	CLD
	LDX #$FF
	TXS

; ...followed by code chunks
#include "init.s"
#include "nmi.s"
#include "isr.s"

; vectored interrupt handlers
nmi:
	JMP (fw_nmi)
irq:
	JMP (fw_isr)

; *** standard 6502 vectors ***
* = $FFFA
	.word	nmi
	.word	reset
	.word	irq
