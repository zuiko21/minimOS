; KIM-like shell for minimOS, suitable for LED keypad!
; v0.1a1
; last modified 20200106-2203
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
	BCC go_kp			; enough space
	BEQ go_kp			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_kp:
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
	BCC open_kp		; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_kp:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####

; *** begin things ***
; must initialise thing first... TO DO
	_STZA kp_mode		; starts on address mode
kp_mloop:
		LDY iodev		; get char from standard device
		_KERNEL(CIN)
		BCC kp_rcv		; some received!
			CPY #EMPTY		; just waiting?
			BEQ kp_mloop
				_PANIC("{dev}")		; device failed!
kp_rcv:
		LDA io_c		; read what was pressed
; *** VALID COMMANDS ***
; ? ($3F) goes into address mode (AD key on KIM)
; - ($2D) goes into data (write) mode (DA key on KIM)
; CR/= ($0D/$3D) updates display with data (ending in period if in data mode)
; I ($49/$69) updates display with address after CR (ending in period if in data mode)
; ESC/* ($1B/$2A) shows stored Program Counter (PC key on KIM)
; + ($2B) advances address (like KIM)
; G ($47/$67) executes code (GO key on KIM, but only allowed on address mode)
; **********************
; check address mode selection
		CMP #'?'
		BNE kp_nad
			BIT kp_mode		; was it writing?
			BPL kp_ad
				JSR kp_dwr		; update byte if so
				LDA io_c		; retrieve char!
kp_ad:
			_STZX  kp_mode		; zero (or plus) is address mode
			JMP kp_echo
kp_nad:
; check data mode selection
		CMP #'-'
		BNE kp_nda
			BIT kp_mode		; was it entering address?
			BMI kp_da
				JSR kp_awr		; update pointer if so
kp_da:
			LDX #$FF		; $FF (or negative) is data entry mode
			STX kp_mode
			LDA #'.'		; dot means will write
			JMP kp_echo
kp_nda:
; check address advance
		CMP #'+'
		BNE kp_nplus
			BIT kp_mode		; was it writing?
			BPL kp_plus
				JSR kp_dwr		; update byte if so
kp_plus:
			INC kp_ptr		; next
			BNE kp_pnw
				INC kp_ptr+1
kp_pnw:
; must print CR, new address (and dot if in data mode) TO DO
			
			JMP kp_echo
kp_nplus:
; check execution
		CMP #'G'
			BEQ kp_go
		CMP #'g'
		BNE kp_ngo
kp_go:
			BIT kp_mode		; was it writing?
			BPL kp_go2
				JSR kp_dwr		; update byte if so
				JMP kp_gda		; and notify error!
kp_go2:
; should I prepare anything before execution?
			JMP (kp_ptr)		; execute!
kp_ngo:
; check a*** mode selection
		CMP #'?'
		BNE kp_nad
			BIT kp_mode		; was it writing?
			BPL kp_ad
				JSR kp_dwr		; update byte if so
				LDA io_c		; retrieve char!
kp_ad:
			_STZX  kp_mode
			JMP kp_echo

; look for a valid hex digit
		CMP #'0'

; echo desired char in A and continue
kp_echo:
		JSR prnChar
		JMP kp_mloop

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
