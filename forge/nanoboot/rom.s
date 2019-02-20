; minimal nanoBoot firmware
; v0.2a3
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190220-1042

; already NMOS-savvy
#define	SAFE	_SAFE
#define	TIMEBOOT	_TIMEBOOT
;#define	SETOVER	_SETOVER

#include "../../OS/macros.h"
#include "nanoboot.h"

; mimimal firmware variables?
; these should NOT go into zeropage, even if saving a few bytes
.bss
* = $0200
fw_isr	.word	0
fw_nmi	.word	0
.text

; *** ROM contents *** 128 bytes will suffice!
* = $FF80

; standard 6502 init... NOT NEEDED
; * no adds or subtractions, thus decimal mode irrelevant
; * stack can be anywhere into page 1

reset:
#ifdef	SETOVER
nb_irq:
#endif
;	CLD
;	LDX #$FF
;	TXS

; ...followed by code chunks
#include "init.s"
#ifndef	SETOVER
#include "nmi.s"
#include "isr.s"
#else
#include "so_nmi.s"
#endif

; vectored interrupt handlers
nmi:
	JMP (fw_nmi)
irq:
	JMP (fw_isr)

; *** filling for ROM-ready files ***
	.dsb	$FFFA-*, $FF

; *****************************
; *** standard 6502 vectors ***
; *****************************
* = $FFFA
	.word	nmi
	.word	reset
	.word	irq
