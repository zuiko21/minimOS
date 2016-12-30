; minimOS ROM template for SDm
; v0.5.1b1, unified with kernel 20160412
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20161230-2247

; avoid further standalone definitions
#define		ROM		_ROM
#define		KERNEL	_KERNEL
;#define		HEADERS	_HEADERS

; *** include files ***
; *** options.h is machine-dependent, copy or link appropriate file from options/ ***
#include "usual.h"

; driver-specific system variables, label is new 20150128
dr_vars:
#include "drivers/config/DRIVER_PACK.h"

; points to the beginning of free SRAM
-user_sram:

; *** ROM contents ***
.text
* = ROM_BASE		; as defined in options.h

; * autobank no longer supported *
; *** minimOS volume header, new 20150604 ***
; should be included from somewhere else! but ONLY makes sense with filesystem

#ifdef	FILESYSTEM
sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aV"		; minimOS system volume ID, TBD
	.asc	"****", 13	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5b4 for ", MACHINE_NAME		; system version and machine
	.asc	13, "20160412-0945", 0				; build date and time

	.dsb	sysvol + $F4 - *, $FF			; for ready-to-blow ROM, advance to time/date field

	.word	$4D80				; time, 09.45
	.word	$488C				; date, 2016/04/12
	
romsize	=	$10000 - ROM_BASE	; compute size!

	.byt	romsize/256			; ROM size in pages
	.byt	0, 0, 0
	.byt	$FF, $FF, $FF, $FF	; link, final item (appendable)
#endif

; *** the GENERIC kernel starts here ***
-kernel:
#include "kernel.s"

; *** I/O device drivers ***
drivers:
#include "drivers/config/DRIVER_PACK.s"

; *** make separate room for firmware ***
	.dsb	FW_BASE - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = FW_BASE						; skip I/O area for firmware

; *** hardware-dependent firmware ***
firmware:
#include "firmware/ARCH.s"
