; KIM-like shell for minimOS, suitable for LED keypad!
; v0.1
; last modified 20200105-1821
; (c) 2020 Carlos J. Santisteban

#ifndef	HEADERS
#include "../usual.h"
#endif

.(
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	iodev	= uz			; standard I/O device ##### minimOS specific #####
		= iodev+1		; storage for launched PID, cursor no longer needed
	buffer	= pid+4			; storage for input line (BUFSIZ chars) ***extra space in order to avoid LOAD_LINK wrap!!!
; ...some stuff goes here, update final label!!!
	__last	= buffer+BUFSIZ	; ##### just for easier size check #####

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
KpadHead:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
KPtitle:
	.asc	"KIMpad 0.1", 0, 0	; file name (mandatory) and empty comment

; advance to end of header
	.dsb	KpadHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$54E0			; time, 10.39
	.word	$4AAB			; date, 2017/5/11

KpadSize	=	KpadEnd - KpadHead - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	KpadSize		; filesize
	.word	0				; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; ****************************
; *** initialise the shell ***
; ****************************
; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_xkp			; enough space
	BEQ go_xkp			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_xkp:
#endif
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<KPtitle		; LSB of window title
	LDA #>KPtitle		; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
#ifdef	C816
	PHK					; current bank eeeeeeek
	PLA					; get it
	STA str_pt+2		; and set parameter
#endif
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_xkp		; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_xkp:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####

; *** begin things *** TO DO TO DO TO DO
main_loop:
	_PANIC("{exit}")	; temporary check

; *** useful routines *** as usual, but needs some hex conversion!

; * print a character in A *
prnChar:
	STA io_c			; store character
	LDY iodev			; get device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print a NULL-terminated string pointed by $AAYY *
prnStr:
	STA str_pt+1		; store MSB
	STY str_pt			; LSB
#ifdef	C816
	PHK					; current bank eeeeeeek
	PLA					; get it
	STA str_pt+2		; and set parameter
#endif
	LDY iodev			; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS

; *** strings and other data ***

xkp_err:
	.asc	" Err!", CR, 0

#ifdef	NOHEAD
KPtitle:
	.asc	"KIMpad", 0	; for headerless builds
#endif

; ***** end of stuff *****
KpadEnd:				; ### for easy size computation ###
.)
