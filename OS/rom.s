; minimOS ROM template
; v0.5.1b2, unified with kernel 20160412
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170107-1842

; avoid further standalone definitions
#define		ROM		_ROM

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
; do not include as current (0.5.1) LOAD_LINK will not recognise it!
; should be included from somewhere else! but ONLY makes sense with filesystem

#ifdef	FILESYSTEM
sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aV"		; minimOS system volume ID, TBD
	.asc	"****", 13	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5.1 for ", MACHINE_NAME		; system version and machine
	.asc	13, "20170107-1810", 0				; build date and time

	.dsb	sysvol + $F8 - *, $FF			; for ready-to-blow ROM, advance to time/date 
field

	.word	$9000				; time, 18.00
	.word	$4A27				; date, 2017/01/07

romsize	=	$FF00 - ROM_BASE	; compute size! excluding header

	.byt	0, >romsize, 0, 0		; ROM size in pages
#endif

; *** the GENERIC kernel starts here ***
#include "kernel.s"

; *** I/O device drivers ***
; should include a standard header here!
drv_file:
	BRK
	.asc	"aD"	; driver pack file TBD
	.asc	"****", 13	; flags TBD
	.asc	"drivers", 0, 0	; filename & empty comment

	.dsb	drv_file + $F8 - *, $FF	; padding

	.word	$9000		; time, 18.00
	.word	$4A27		; date, 2017/01/07

drv_size = drv_end - drv_file - $100	; exclude header

	.word	drv_size
	.word	0

; after header goes the binary blob
#include "drivers/config/DRIVER_PACK.s"
drv_end:		; for easier size computation

; *** include rest of the included software, each with its own header ***
#include "../apps/ls.s"
#include "../apps/pmap.s"
#include "../apps/SIGtest.s"
#include "../apps/lined.s"

; *** make separate room for firmware ***
	.dsb	FW_BASE - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = FW_BASE						; skip I/O area for firmware

; *** hardware-dependent firmware ***
firmware:
#include "firmware/ARCH.s"
