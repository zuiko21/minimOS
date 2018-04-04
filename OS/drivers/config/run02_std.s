; includes for minimOS drivers
; run65816 BBC simulator specific configuration!
; 8-bit version
; v0.9b2
; (c) 2017-2018 Carlos J. Santisteban
; last modified 20180404-1343

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#ifndef	HEADERS
#include	"../../usual.h"
#endif

; *** load appropriate drivers here ***
driver0:
#include	"../drv_run02.s"

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

drvrs_ad:
	.word	driver0		; generic list
	.word	0			; ***** TERMINATE LIST ***** (essential since 0.5a2)
