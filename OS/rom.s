; minimOS ROM template
; v0.5.1b3, unified with kernel 20160412
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170109-0944

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

sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aV"		; minimOS system volume ID, TBD
	.asc	"****", CR	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5.1 for ", MACHINE_NAME	; system version and machine
	.asc	13, "20170109-1000", 0				; build date and time

	.dsb	sysvol + $F8 - *, $FF				; for ready-to-blow ROM, advance to time/date 
field

	.word	$5000				; time, 09.00
	.word	$4A29				; date, 2017/01/09

romsize	=	$FF00 - ROM_BASE	; compute size! excluding header

;	.word	romsize				; volume size (for future support)
;	.word	0					; ROM size in pages
; FAKE file "size" in order to be LOAD_LINK savvy...
	.word	0, 0				; nothing inside, skip to adjacent header

; *** the GENERIC kernel starts here ***
kernel = * + 256	; skip the header!
#include "kernel.s"

; *** I/O device drivers ***
; should include a standard header here!
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
drv_file:
	BRK
	.asc	"aD"						; driver pack file TBD
	.asc	"****", CR					; flags TBD
	.asc	"drivers", 0				; filename
	.asc	"simple Kowalski I/O", 0	; comment

	.dsb	drv_file + $F8 - *, $FF		; padding

	.word	$5000				; time, 09.00
	.word	$4A29				; date, 2017/01/09

drv_size = drv_end - drv_file - $100	; exclude header

	.word	drv_size
	.word	0

; after header goes the binary blob
#include "drivers/config/DRIVER_PACK.s"
drv_end:		; for easier size computation

; *** include rest of the included software, each with its own header ***
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
#include "../apps/ls.s"
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
#include "../apps/pmap.s"
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
#include "../apps/sigtest.s"
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
#include "../apps/lined.s"

; *** make separate room for firmware ***
	.dsb	FW_BASE - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = FW_BASE						; skip I/O area for firmware

; *** hardware-dependent firmware ***
firmware:
#include "firmware/ARCH.s"
