; includes for minimOS drivers
; Kowalski simulator specific configuration!
; v0.9b1
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20180404-1339

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#ifndef		HEADERS
#include "../../usual.h"
.bss
#include "kowalski_std.h"
.text
#endif

; *** load appropriate drivers here ***
driver0:
#include	"../drv_kowalski.s"

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

drivers_ad:
	.word	driver0		; generic list
	.word	0			; ***** TERMINATE LIST ***** (essential since 0.5a2)
