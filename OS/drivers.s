; includes for minimOS drivers
; v0.5a4
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20150930-1428
; revised 20160115 for commit with new filenames

#define		DRIVERS		_DRIVERS

; in case of standalone assembly
#ifndef		KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
#include "drivers.h"
.text
#endif

#ifndef		FINAL
	.asc	"<drvr>"	; for easier debugging
#endif

; *** load appropriate drivers here ***
; place them between generic labels

driver0:
; optional multitasking as a driver!!! new 20150324
; next driver's address would repeat on list... current (0.5a9) kernel would reject duplicates anyway
#ifdef	MULTITASK
#include	"drivers/multitask.s"
#endif

driver1:
; optional filesystem as a driver! new 20150309
; same as above, if disabled
#ifdef	FILESYSTEM
#include	"drivers/filesystem.s"
#endif

; *** standard drivers ***
; LED keypad
#include "drivers/drv_led.s"

driver2:
; SS-22 link
#include "drivers/drv_ss22.s"

driver3:
; ASCII keyboard with LCD
;#include "drivers/drv_ascii_lcd.s"

; *** interfaces for SDx and later ***
driver4:
; serial port
#include "drivers/drv_acia.s"

driver5:
; Hitachi LCD
;#include "drivers/drv_lcd.s"

; up to 16 drivers, undefined ones point to dummy driver
driver6:
driver7:
driver8:
driver9:
driverA:
driverB:
driverC:
driverD:
driverE:
driverF:

-drv_dummy:
; *** make undefined drivers point here ***
; *** dummy driver, fake addresses ***
; to be placed after all actually defined drivers, new name 20150128
#include "drivers/dummy.s"

; *** driver list in ROM ***
; only the addresses, in no particular order (watch out undefined drivers!)
; this might be generated in RAM in the future, allowing on-the-fly driver install

#ifndef		FINAL
	.asc	"<addr>"	; for easier debugging
#endif

drivers_ad:
	.word	driver0		; generic list
	.word	driver1		; generic list
	.word	driver2		; generic list
	.word	driver3		; generic list
	.word	driver4		; generic list
	.word	driver5		; generic list
	.word	driver6		; generic list
	.word	driver7		; generic list
	.word	driver8		; generic list
	.word	driver9		; generic list
	.word	driverA		; generic list
	.word	driverB		; generic list
	.word	driverC		; generic list
	.word	driverD		; generic list
	.word	driverE		; generic list
	.word	driverF		; generic list

	.word	0		; ***** TERMINATE LIST ***** (essential since 0.5a2)
