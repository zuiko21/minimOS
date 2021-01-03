; includes for minimOS drivers
; EMPTY configuration for testing purposes!
; v1.0
; (c) 2016-2021 Carlos J. Santisteban
; last modified 20180405-1401

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#ifndef		KERNEL
#include "usual.h"
.bss
; sample firmware for testing purposes
#include "chihuahua_plus_std.h"
#include "../../sysvars.h"
.text
#endif

; *** load appropriate drivers here, currently just the multitasking option ***
driver0:
#ifdef	MULTITASK
#ifdef	C816
#include	"../multitask16.s"
#else
#include	"../multitask.s"
#endif
#endif

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

drivers_ad:
#ifdef	MULTITASK
	.word	driver0		; generic list
#endif
	.word	0			; ***** TERMINATE LIST ***** (essential since 0.5a2)
