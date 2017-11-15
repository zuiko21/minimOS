; includes for minimOS drivers
; run65816 BBC simulator specific configuration!
; 8-bit version
; v0.9b2
; (c) 2017 Carlos J. Santisteban
; last modified 20171115-1319

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#include	"usual.h"

; *** load appropriate drivers here ***
driver0:
#include	"drivers/drv_run02.s"

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

drvrs_ad:
	.word	driver0		; generic list
	.word	0			; ***** TERMINATE LIST ***** (essential since 0.5a2)
