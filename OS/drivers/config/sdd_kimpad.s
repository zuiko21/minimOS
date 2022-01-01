; includes for minimOS drivers
; SDd with LED keypad specific configuration!
; v0.6.1a1
; (c) 2015-2022 Carlos J. Santisteban
; last modified 20200110-1049

#define		DRIVERS		1

; in case of standalone assembly
#ifndef		HEADERS
#include "../../usual.h"
.bss
#include "chihuahua_plus_std.h"
.text
#endif

; *** load appropriate drivers here ***
; place them between generic labels

driver0:
; *** standard drivers ***
; LED keypad
#include "../drv_led.s"

; no more for this demo...

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install
; since non LOWRAM systems call directly I/O routines, this is only used during registration

drvrs_ad:
	.word	driver0		; generic list, actually a single driver

	.word	0		; ***** TERMINATE LIST ***** (essential since 0.5a2)
