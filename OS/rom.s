; minimOS ROM template for SDm
; v0.5a5
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160310

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
#include "firmware/arch/ARCH.h"

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

; *** auto-bankswitching routine (not yet implemented) ***
#ifdef		AUTOBANK
#include "autobank.s"
	.dsb	ROM_BASE + 256 - *, $FF		; for ready-to-blow ROM, advance to next 'sector'
#endif

; *** minimOS volume header, new 20150604 ***
; should be included from somewhere else!
sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aV"		; minimOS system volume ID, TBD
	.asc	"****", 13	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5a5 for ", MACHINE_NAME		; system version and machine
	.asc	"20160310-1100", 0				; build date and time

	.dsb	sysvol + $F4 - *, $FF			; for ready-to-blow ROM, advance to time/date field

	.asc	$80, $48			; time, 09.04.00 *** correct!
	.asc	$C4, $46			; date, 2015/06/04
	.asc	128, 0, 0, 0		; length, 32 KiB ROM (128 pages)
	.asc	$FF, $FF, $FF, $FF	; link, final item (appendable)

; *** the GENERIC kernel starts here ***
kernel:
#include "kernel.s"				; new filename

; *** I/O device drivers ***
drivers:
#include "drivers/config/DRIVER_PACK.s"

; *** make separate room for firmware ***
	.dsb	$E000-*, $FF		; for ready-to-blow ROM, skip to firmware area
* = FW_BASE		; *** reserve the last 8 kiB for firmware, skip SDm I/O area!!! change if appropriate in options.h 20160310

; *** hardware-dependent firmware ***
firmware:
#include "firmware/arch/ARCH.s"
