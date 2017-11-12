; includes for minimOS drivers
; SDd with emulated serial specific configuration!
; ***** Jornada HackLabAlmería en El Ejido 2017 *****
; v0.6a1
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20171112-1147

#define		DRIVERS		1

; in case of standalone assembly
#ifndef		KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/chihuahua.h"
#include "sysvars.h"
#include "drivers/config/sdd_serial.h"
.text
#endif

; *** load appropriate drivers here ***
; place them between generic labels

driver0:
; *** standard drivers ***
; Emulated serial
#include "drivers/soft_232.s"

; no more for this demo...

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install
; since non LOWRAM systems call directly I/O routines, this is only used during registration

drivers_ad:
	.word	driver0		; generic list, actually a single driver

	.word	0		; ***** TERMINATE LIST ***** (essential since 0.5a2)
