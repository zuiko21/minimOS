; memory map for minimOS! KLUDGE
; v0.5a1
; last modified 20161227-1547
; (c) 2016 Carlos J. Santisteban

#include "usual.h"

; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	iodev	= uz			; standard I/O device ##### minimOS specific #####
	cursor	= iodev+1		; storage for X offset
	buffer	= cursor+1		; storage for input line (BUFSIZ chars)
; ...some stuff goes here, update final label!!!
	__last	= buffer+BUFSIZ	; ##### just for easier size check #####

; ##### include minimOS headers and some other stuff #####
shellHead:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m"				; minimOS app!
#ifdef	NMOS
	.asc	"N"				; NMOS version
#else
	.asc	"B"				; basic CMOS version
#endif
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
	.asc	"miniShell", 0	; file name (mandatory)

	.asc	0				; empty comment

; advance to end of header
	.dsb	shellHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4800			; time, 09.00
	.word	$4990			; date, 2016/12/16

shellSize	=	shellEnd - shellHead -256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.byt	<shellSize		; filesize LSB
	.byt	>shellSize		; filesize MSB
	.word	0				; 64K space does not use upper 16-bit
; ##### end of minimOS executable header #####

; ****************************
; *** initialise the shell ***
; ****************************
-shell:
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
	LDA #>splash		; address of splash message
	LDY #<splash
	JSR prnStr			; print the string!
; *** begin things ***
main_loop:
		LDA #>prompt		; address of prompt message (currently fixed)
		LDY #<prompt
		JSR prnStr			; print the prompt! (/sys/_)
		JSR getLine			; input a line
; in an over-simplistic way, just tell this 'filename' to LOAD_LINK and let it do...
		LDY #<buffer		; just to make sure it is the LSB only
		LDA #>buffer		; in zeropage, all MSBs are zero
		STY str_pt			; set parameter
		STA str_pt+1
		_KERNEL(LOAD_LINK)	; look for that file!
		BCC xsh_ok			; it was found, thus go execute it
			LDY #<xsh_err		; get error message pointer
			LDA #>xsh_err
			JSR prnStr			; print it!
			_BRA main_loop		; and try another
xsh_ok:
		_KERNEL(B_FORK)		; get a free braid
		CPY #0				; what to do if none available?
			BEQ xsh_single		; no multitasking, execute and restore status!
		_KERNEL(B_EXEC)		; run on that braid
		_BRA main_loop		; and continue asking for more
xsh_single:
	_KERNEL(B_EXEC)		; execute anyway...
	_BRA shell			; ...but reset shell environment all the way!

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
; minimOS should have one of these in API...
getLine:
	_STZX cursor			; reset variable
gl_l:
		LDY iodev			; use device
		_KERNEL(CIN)		; get one character #####
			BCS gl_l			; wait for something
		LDA io_c			; get received
		LDX cursor			; retrieve index
		CMP #CR				; hit CR?
			BEQ gl_cr			; all done then
		CMP #BS				; is it backspace?
		BNE gl_nbs			; delete then
			CPX #0				; already 0?
				BEQ gl_l			; ignore if so
			DEC cursor			; reduce index
			_BRA gl_echo		; resume operation
gl_nbs:
		CPX #BUFSIZ-1		; overflow?
			BCS gl_l			; ignore if so
		STA buffer, X		; store into buffer
		INC	cursor			; update index
gl_echo:
		JSR prnChar			; echo!
		_BRA gl_l			; and continue
gl_cr:
	JSR prnChar			; newline
	LDX cursor			; retrieve cursor!!!!!
	_STZA buffer, X		; terminate string
	RTS					; and all done!


; *** strings and other data ***
title:
	.asc	"miniShell", 0

splash:
	.asc	"minimOS 0.5 shell", CR
	.asc	" (c) 2016 Carlos J. Santisteban", CR, 0

prompt:
	.asc	CR, "/sys/", 0

xsh_err:
	.asc	CR, "*** NOT executable ***", CR, 0

; ***** end of stuff *****
shellEnd:				; ### for easy size computation ###
