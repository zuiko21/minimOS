; includes for minimOS drivers
; EMPTY configuration for testing purposes!
; v1.2
; (c) 2016-2022 Carlos J. Santisteban
; last modified 20220322-2343

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#ifndef		KERNEL
#include "usual.h"
.bss

#include "durango_std.h"
#include "../../sysvars.h"
.text
#endif

; *** load appropriate drivers here, currently just the GENERIC firmware console ***
driver0:
#include	"drivers/conio_ni.s"

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

drvrs_ad:
	.word	driver0		; generic list
	.word	0			; ***** TERMINATE LIST ***** (essential since 0.5a2)
