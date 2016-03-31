; minimOS ROM template for SDm
; v0.5a6
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160331-1316

; avoid further standalone definitions
#define		ROM		_ROM
#define		KERNEL	_KERNEL

; *** include files ***
; *** options.h is machine-dependent, copy or link appropriate file from options/ ***
; generic definitions
#include "options.h"
#include "macros.h"
#include "abi.h"	; new filename

; *** label definitions ***
.zero

; zeropage
#include "zeropage.h"

.bss

; firmware specific variables, usually from $0200
* = SYSRAM		; as defined in options.h
sysram:
#include "firmware/ARCH.h"

; generic system variables
sysvars:
#include "sysvars.h"

; driver-specific system variables, label is new 20150128
dr_vars:
#include "drivers/config/DRIVER_PACK.h"

; points to the beginning of free SRAM
user_sram:

; *** ROM contents ***
.text
* = ROM_BASE		; as defined in options.h

; * autobank no longer supported *
; *** minimOS volume header, new 20150604 ***
; should be included from somewhere else!
sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aV"		; minimOS system volume ID, TBD
	.asc	"****", 13	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5a6 for ", MACHINE_NAME		; system version and machine
	.asc	13, "20160331-1445", 0				; build date and time

	.dsb	sysvol + $F4 - *, $FF			; for ready-to-blow ROM, advance to time/date field

	.word	$75A0				; time, 14.45
	.word	$487F				; date, 2016/03/31
	
romsize	=	$10000 - ROM_BASE	; compute size!

	.byt	romsize/256			; ROM size in pages
	.byt	0, 0, 0
	.byt	$FF, $FF, $FF, $FF	; link, final item (appendable)

; *** the GENERIC kernel starts here ***
kernel:
#include "kernel.s"				; new filename

; *** I/O device drivers ***
drivers:
#include "drivers/config/DRIVER_PACK.s"

; *** make separate room for firmware ***
	.dsb	FW_BASE - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = FW_BASE						; skip I/O area for firmware

; *** hardware-dependent firmware ***
firmware:
#include "firmware/ARCH.s"
