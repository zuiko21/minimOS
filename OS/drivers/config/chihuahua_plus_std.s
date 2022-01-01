; includes for minimOS drivers
; Chihuahua PLUS specific configuration!
; v0.6b4
; (c) 2015-2022 Carlos J. Santisteban
; last modified 20190215-0959

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
; Hitachi LCD
#include "lcd.s"

driver1:
; ASCII keyboard
#include "../asc_kbd.s"


; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install
; since non LOWRAM systems call directly I/O routines, this is only used during registration

drvrs_ad:
	.word	driver0		; generic list
	.word	driver1		; generic list
;	.word	driver2		; generic list
;	.word	driver3		; generic list
;	.word	driver4		; generic list

	.word	0		; ***** TERMINATE LIST ***** (essential since 0.5a2)
