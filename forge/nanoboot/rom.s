; minimal nanoBoot firmware
; v0.4a1
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20210202-1937

; already NMOS-savvy

; *********************
; *** configuration ***
; *********************
; extra header checking
#define	SAFE	_SAFE

; timeout routines, will abort in ~0.9s @ 1 MHz
#define	TIMEBOOT	_TIMEBOOT

; alternate version using /SO pin
;#define	SETOVER	_SETOVER

; progress display in LTC4622
#define	DISPLAY	_DISPLAY

; *************************************
; *** includes and system variables ***
; *************************************
#include "../../OS/macros.h"
#include "nanoboot.h"

; mimimal firmware variables!
; these should NOT go into zeropage, even if saving a few bytes
.bss
* = $0200
fw_isr	.word	0
fw_nmi	.word	0

.text
; *************************
; *** boot ROM contents ***
; *************************
#ifndef	DISPLAY
* = $FF80					; 128 bytes will suffice, even with timeout!
#else
* = $FF00					; display routines need much more space, but one page seems enough
#endif

reset:
; standard 6502 init... NOT NEEDED
; * no adds or subtractions, thus decimal mode irrelevant
; * stack can be anywhere into page 1
;	CLD
;	LDX #$FF
;	TXS

; ...followed by code chunks
#include "init.s"
; as this simple bootloader has nothing else to do, just lock (Z known to be clear)
	BNE *

; *** nanoBoot interrupt service routines ***
#ifndef	SETOVER
; regular version
#include "nmi.s"
#include "isr.s"
#else
; /SO version
#include "so_nmi.s"
#endif

; *** vectored interrupt handlers ***
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
