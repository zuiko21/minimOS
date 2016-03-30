; includes for minimOS drivers
; Kowalski simulator specific configuration!
; v0.9b1
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160330-1247

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#ifndef		KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
#include "drivers/config/DRIVER_PACK.h"	; generic access
.text
#endif

; *** load appropriate drivers here ***
driver0:
#include	"drivers/drv_kowalski.s"

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

drivers_ad:
	.word	driver0		; generic list
	.word	0			; ***** TERMINATE LIST ***** (essential since 0.5a2)
