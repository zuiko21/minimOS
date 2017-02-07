; minimOS ROM template
; v0.5.1b6, unified with kernel 20160412
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170207-0834

; avoid further standalone definitions
#define		ROM		_ROM

; *** include files ***
; *** options.h is machine-dependent, copy or link appropriate file from options/ ***
#include "usual.h"

; *** ROM contents ***
.text
* = ROM_BASE		; as defined in options.h

; *** minimOS volume header, new 20150604 ***
; not final as current (0.5.1) LOAD_LINK will not recognise it!
; might use NOHEAD option for systems without any filesystem, but current LOAD_LINK needs it

#ifndef	NOHEAD
sysvol:
	BRK					; don't enter here! NUL marks beginning of header
	.asc	"aV"		; minimOS system volume ID, TBD
	.asc	"****", CR	; some flags TBD
	.asc	"sys", 0	; volume name (mandatory)
; *** ROM identification string as comment (highly recommended) ***
version:
	.asc	"minimOS 0.5.1 for ", MACHINE_NAME	; system version and machine
	.asc	13, "20170207-0830", 0				; build date and time

	.dsb	sysvol + $F8 - *, $FF				; for ready-to-blow ROM, advance to time/date field

	.word	$43C0				; time, 08.30
	.word	$4A47				; date, 2017/02/07

;romsize	=	$FF00 - ROM_BASE	; compute size! excluding header

;	.word	romsize				; volume size (for future support)
;	.word	0					; ROM size in pages
; FAKE file "size" in order to be LOAD_LINK savvy...
	.word	0, 0				; nothing inside, skip to adjacent header
#endif

; *** the GENERIC kernel starts here ***
kernel = * + 256	; skip the header!
#ifndef	C816
#include "kernel.s"
#else
#include "kernel16.s"
#endif

; *** I/O device drivers ***
; should include a standard header here!
	.dsb	$100 - (* & $FF), $FF		; page alignment!!! eeeeek
drv_file:
	BRK
	.asc	"aD"						; driver pack file TBD
	.asc	"****", CR					; flags TBD
	.asc	"drivers", 0				; filename
	.asc	"driver package", 0			; comment

	.dsb	drv_file + $F8 - *, $FF		; padding

	.word	$5000						; time, 09.00
	.word	$4A29						; date, 2017/01/09

drv_size = drv_end - drv_file - $100	; exclude header

	.word	drv_size
	.word	0

; after header goes the binary blob
#include "drivers/config/DRIVER_PACK.s"
drv_end:		; for easier size computation

; *** include rest of the included software, each with its own header ***
; these must be page aligned!!!
#include "../apps/ls.s"
#include "../apps/pmap16.s"
#include "../apps/lined.s"

; *** skip I/O area for more ***
; ##### empty header #####
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
empty_head:
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"aS****", CR	; just reserved system space
	.asc	"[I/O]", 0, 0	; file name (mandatory) and empty comment
; advance to end of header
	.dsb	empty_head + $FC - *, $FF	; for ready-to-blow ROM, advance to size
; *** no valid date & time ***
emptySize	=	afterIO - empty_head -256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	emptySize		; filesize
	.word	0				; 64K space does not use upper 16-bit
; ##### end of minimOS executable header #####

afterIO = $E000
	.dsb	afterIO - *, $FF	; skip I/O and page alignment!!!

;* = afterIO
; more software
#include "shell/miniMoDA.s"
#include "shell/monitor.s"
#include "../apps/sigtest.s"
; ...could add more software up to $F800

; *** make separate room for firmware ***
	.dsb	FW_BASE - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = FW_BASE						; skip I/O area for firmware

; *** hardware-dependent firmware ***
firmware:
#include "firmware/ARCH.s"
