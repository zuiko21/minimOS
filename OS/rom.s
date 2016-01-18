; minimOS ROM template for SDm
; v0.5a4
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20150615-1410
; revised 20160115 for commit with new filenames

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
#include "firmware/firmware.h"

; generic system variables
sysvars:
#include "sysvars.h"

; driver-specific system variables, label is new 20150128
dr_vars:
#include "drivers.h"

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
sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aK"		; minimOS system volume ID, TBD
	.asc	"****", 13	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5a4 for ", _MACHINE_NAME		; system version and machine
	.asc	"20150615-1409", 0				; build date and time

	.dsb	sysvol + $F4 - *, $FF			; for ready-to-blow ROM, advance to time/date field

	.asc	$80, $48			; time, 09.04.00
	.asc	$C4, $46			; date, 2015/06/04
	.asc	128, 0, 0, 0		; length, 32 KiB ROM (128 pages)
	.asc	$FF, $FF, $FF, $FF	; link, final item (appendable)

; *** the GENERIC kernel starts here ***
kernel:
#include "kernel.s"				; new filename

; *** I/O device drivers ***
drivers:
#include "drivers.s"

; *** make separate room for firmware ***
	.dsb	$E000-*, $FF		; for ready-to-blow ROM, skip to firmware area
* = $E000		; *** reserve the last 8 kiB for firmware, skip SDm I/O area!!! change if appropriate *** 20150605

; *** hardware-dependent firmware ***
firmware:
#include "firmware/template.s"
