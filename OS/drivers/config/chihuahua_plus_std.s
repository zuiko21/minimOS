; includes for minimOS drivers
; Chihuahua PLUS specific configuration!
; v0.6b2
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180404-1328

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
; LED keypad
#include "../drv_led.s"

driver1:
; SS-22 link
;#include "../drv_ss22.s"

driver2:
; ASCII keyboard with LCD
;#include "../drv_ascii_lcd.s"


; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install
; since non LOWRAM systems call directly I/O routines, this is only used during registration

drvrs_ad:
	.word	driver0		; generic list
;	.word	driver1		; generic list
;	.word	driver2		; generic list
;	.word	driver3		; generic list
;	.word	driver4		; generic list

	.word	0		; ***** TERMINATE LIST ***** (essential since 0.5a2)
