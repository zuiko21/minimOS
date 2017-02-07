; Pseudo-file executor shell for minimOS!
; v0.5b8
; last modified 20170123-0934
; (c) 2016-2017 Carlos J. Santisteban

#include "usual.h"
.(
; *** constant definitions ***
#define	BUFSIZ		32

; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	iodev	= uz			; standard I/O device ##### minimOS specific #####
	pid		= iodev+1		; storage for launched PID, cursor no longer needed
	buffer	= pid+1			; storage for input line (BUFSIZ chars)
; ...some stuff goes here, update final label!!!
	__last	= buffer+BUFSIZ	; ##### just for easier size check #####

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100 - (* & $FF), $FF	; page alignment!!! eeeeek
shellHead:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
title:
	.asc	"miniShell", 0, 0	; file name (mandatory) and empty comment

; advance to end of header
	.dsb	shellHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$5000			; time, 10.00
	.word	$4A2C			; date, 2017/1/12

shellSize	=	shellEnd - shellHead - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	shellSize		; filesize
	.word	0				; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; ****************************
; *** initialise the shell ***
; ****************************
mshell:
; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_xsh			; enough space
	BEQ go_xsh			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_xsh:
#endif
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<title			; LSB of window title
	LDA #>title			; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_xsh		; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_xsh:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####

; initialise stuff
;	LDA #>splash		; address of splash message
;	LDY #<splash
;	JSR prnStr			; print the string!
; *** begin things ***
main_loop:
		LDA #>prompt		; address of prompt message (currently fixed)
		LDY #<prompt
		JSR prnStr			; print the prompt! (/sys/_)
		JSR getLine			; input a line
		LDA buffer			; check whether empty line
			BEQ main_loop		; if so, just repeat entry
; in an over-simplistic way, just tell this 'filename' to LOAD_LINK and let it do...
		LDY #<buffer		; just to make sure it is the LSB only
		LDA #>buffer		; in zeropage, all MSBs are zero
		STY str_pt			; set parameter
		STA str_pt+1
		STA str_pt+2		; ready for 24-bit
		_KERNEL(LOAD_LINK)	; look for that file!
		BCC xsh_ok			; it was found, thus go execute it
			CPY #INVALID		; found but not compatible?
			BNE ms_nf
				LDY #<xsh_err		; get incompatible message pointer
				LDA #>xsh_err
				BNE ms_err			; and print error, no need for BRA
ms_nf:
			LDY #<xsh_not		; get not found message pointer
			LDA #>xsh_not
ms_err:
			JSR prnStr			; print it!
			_BRA main_loop		; and try another
xsh_ok:
; something is ready to run, but set its default I/O first!!!
		LDY iodev
		STY def_io
		STY def_io+1
		_KERNEL(B_FORK)		; get a free braid
		TYA					; check PID at Y, what to do if none available?
		BEQ xsh_single		; no multitasking, execute and restore status!
			STY pid			; save as will look for it later
			_KERNEL(B_EXEC)		; run on that braid
xsh_wait:
				_KERNEL(B_YIELD)	; do not waste CPU time!
				LDY pid				; retrieve launched PID
				_KERNEL(B_STATUS)	; check its current state
				CPY #BR_FREE		; until ended (relies on B_STATUS hiding BR_END!!!)
				BNE xsh_wait		; do not interact until ended (no '&' yet)
			BEQ main_loop		; then continue asking for more
xsh_single:
	_KERNEL(B_EXEC)		; execute anyway...
	JMP mshell			; ...but reset shell environment! should not arrive here

; *** useful routines ***

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
	LDY iodev			; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS

; * get input line from device at fixed-address buffer *
; now using the one built-in into API
getLine:
	LDY #<buffer		; get buffer address in zp
	LDA #>buffer		; MSB, should be zero already!
	STY str_pt			; set kernel parameter
	STA str_pt+1		; clear MSB, no need for STZ
	_STZA str_pt+2		; also mandatory 24-bit addressing
	LDX #BUFSIZ-1		; maximum offset
	STX ln_siz
	LDY iodev			; use standard device
	_KERNEL(READLN)		; get string
	RTS					; and all done!


; *** strings and other data ***

splash:
;	.asc	"minimOS 0.5.1 shell", CR
;	.asc	"(c) 2016-2017 Carlos J. Santisteban", CR, 0

prompt:
	.asc	CR, "/sys/", 0

xsh_err:
	.asc	"*** NOT executable ***", CR, 0

xsh_not:
	.asc	"Not found", CR, 0

; ***** end of stuff *****
shellEnd:				; ### for easy size computation ###
.)
