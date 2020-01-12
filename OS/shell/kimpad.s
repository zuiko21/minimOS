; KIM-like shell for minimOS, suitable for LED keypad!
; v0.1a6
; last modified 20200112-1432
; (c) 2020 Carlos J. Santisteban

#ifndef	HEADERS
#ifdef		TESTING
; ** special include set to be assembled via... **
; xa shell/kimpad.s -DTESTING=1
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.text
#else
; ** regular assembly **
#include "../usual.h"
#endif
#endif

.(
; **************************
; *** assembling options ***
; **************************
; KIMSHELL waives all minimOS initialisation, as this is a VERY low-level shell
#define	KIMSHELL	_KIMSHELL
; KIMDEV tries not to ask for an I/O device, using default ID 0 instead
#define	KIMDEV		_KIMDEV
; remove minimOS headers
#define	NOHEAD		_NOHEAD
; use standard debug stack frame, comment if not available from firmware
#define	NMI_SF		_NMI_SF

; *****************************
; *** zeropage declarations ***
; *****************************
; ##### uz is first available zeropage byte, typically 3 on minimOS #####
	iodev	= uz			; standard I/O device ##### minimOS specific #####
	mode	= iodev+1		; 0/+ is address (read) mode, $FF/- is data (write) mode
	value	= mode+1		; storage for typed numbers (word)
	pointer	= value+2		; storage for pointed address (word)
	s_pc	= pointer+2		; saved PC (word), was $EF on KIM
	s_psr	= s_pc+2		; saved P, was $F1
	s_sp	= s_psr+1		; saved S, was $F2
	s_acc	= s_sp+1		; saved A, was $F3
	s_yreg	= s_acc+1		; saved Y, was $F4
	s_xreg	= s_yreg+1		; saved X, was $F5
	__last	= s_xreg+1		; ##### just for easier size check #####

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
KPHead:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
KPtitle:
	.asc	"KIMpad 0.1", 0, 0	; file name (mandatory) and empty comment

; advance to end of header
	.dsb	KPHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4800			; time, 9.00
	.word	$5028			; date, 2020/1/8

KPSize	=	KPEnd - KPHead - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	KPSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; ****************************
; *** initialise the shell ***
; ****************************

; ##### minimOS specific stuff ##### not really needed as this is VERY low-level!
#ifndef	KIMSHELL
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
; ### remaining specific code may be omitted in case default (#0) devs are used ###
#ifndef	KIMDEV
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
	BCC open_kp			; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_kp:
#else
	LDY #0				; ### default kernel device for KIMDEV option ###
#endif
	STY iodev			; ### store device... or just assume zero! ###
#endif
; ##### end of minimOS specific stuff #####

	_STZA mode			; starts on address mode (!)
	_STZA value			; clear entry buffer
	_STZA value+1
; anything else? may put splash screen here

; **********************************************
; *** install interrupt (NMI & BRK) handlers ***
; **********************************************
	LDY #<kp_isr		; point to ISR
	LDA #>kp_isr
#ifdef	NMI_SF
	STY ex_pt			; eeeeeeeek (may directly poke the firmware vector instead...)
	STA ex_pt+1
	_ADMIN(SET_NMI)		; ### install debuggers ###
	_ADMIN(SET_DBG)
#else
	STY fw_nmi			; set specific interrupt indirect vectors
	STA fw_nmi+1
	STY fw_dbg
	STA fw_dbg+1
#endif

; **************************
; *** proceed with shell ***
; **************************
	TSX
	STX s_sp			; at least, keep SP as will be altered upon execution!
; it's nice to have a little splash screen on startup
	LDY #<KPtitle
	LDA #>KPtitle
	JSR prnStr			; splash screen
	JSR newline			; newline for convenience
	_BRA kp_start		; if not from interrupt, register values are meaningless

; *********************************
; *** *** INTERRUPT HANDLER *** ***
; *********************************
kp_isr:
#ifndef	NMI_SF
; direct register saving, in case firmware does not do it
	STA s_acc			; save registers as usual
	PLA					; top of stack after interrupt is P
	STA s_psr
kp_jsr:					; * in case of entry via JSR *
	PLA					; pull LSB
	STA s_pc
	STA pointer			; just in case
	PLA					; ditto for MSB
	STA s_pc+1
	STA pointer+1
	STY s_yreg
	STX s_xreg
#else
; ### take saved register values from standard minimOS stack frame ###
	.asc "NUj*"			; magic string for minimOS firmware handler (inocuous execution!) 
	PLA					; discard extended state...
	PLA
	PLA
	PLA					; stored Y
	STA s_yreg
	PLA					; stored X
	STA s_xreg
	PLA					; stored A
	STA s_acc
	PLA					; stored PSR
	STA s_psr
kp_jsr:
	PLA					; stored PC.L
	STA s_pc
	STA s_pointer
	PLA					; stored PC.H
	STA s_pc+1
	STA s_pointer+1
; stack is empty already, SP is like it was before interrupt
#endif
	TSX					; save stack pointer too
	STX s_sp
	CLI					; enable interrupts for the display!
; ***************************************************
; *** *** ...and fall into main loop (no RTI) *** ***
; ***************************************************

kp_start:
; anything else?

; *****************
; *** main loop ***
; *****************
kp_mloop:
		JSR readChar			; read key in A, letters are uppercase (generic)

; **************************
; *** command processing ***
; **************************
; VALID COMMANDS:
; ?		($3F)		goes into address mode (AD key on KIM)
; -		($2D)		goes into data (write) mode (DA key on KIM)
; CR  =	($0D/$3D)	updates display with data (ending dot if in data mode)
; Esc *	($1B/$2A)	updates display with address after CR (ending dot if in data mode)
; I		($49/$69)	shows stored Program Counter (PC key on KIM)
; +		($2B)		advances address (like KIM)
; G		($47/$67)	executes code (GO key on KIM, but only allowed on address mode)
; **************************

; ** select address mode (?) **
		CMP #'?'
		BNE kp_nad
			JSR kp_chk		; update pending values
			_STZX mode		; zero (or plus) is address mode
			LDA #'?'		; prompt (might be changed if desired)
			BNE kp_echo		; show prompt and keep reading (was BRA)
kp_nad:

; ** select data entry mode (-) **
		CMP #'-'
		BNE kp_nda
			JSR kp_chk		; update pending values
			LDX #$FF		; $FF (or negative) is data entry mode
			STX mode
kp_dot:
			LDA #'.'		; dot means write mode, best for LED keypad
			BNE kp_echo		; was BRA
kp_nda:

; ** advance address (+) **
		CMP #'+'
		BNE kp_nplus
			JSR kp_naw		; check for pending data only!
			INC pointer		; next address
			BNE kp_pnw
				INC pointer+1
kp_pnw:
; print address-dot-data, plus another dot if in write mode
			JSR kp_crad		; print CR + address
			JSR kp_data		; print dot + data byte
			_BRA kp_wdot	; add final dot if in write mode
kp_nplus:

; ** execution (G) **
		CMP #'G'
		BNE kp_ngo
			JSR kp_chk		; update pending values
			BIT mode		; was it writing?
			BMI kp_go2		; notify error if so!
; should I prepare anything else before execution...?
				LDY #<kp_run	; get pointer to run string
				LDA #>kp_run
				JSR prnStr
; ...for instance, preload registers
				LDX s_sp		; worth it?
				TXS
				LDX s_xreg
				LDY s_yreg
				LDA s_psr		; P will be loaded last...
				PHA				; ...from stack
				LDA s_acc
				PLP				; status updated!
				JMP (pointer)	; execute!
; if not ready to execute, print error
kp_go2:
			JSR kp_nex		; print error message
			_BRA kp_mloop

; ****************************
; *** echo and loop return ***
kp_echo:
		JSR prnChar
kp_nhex:				; ignore wrong key
		_BRA kp_mloop
; ***** actual  loop end *****
; ****************************

kp_ngo:

; ** display updated address (Esc or *) **
		CMP #ESC
			BEQ kp_ua
		CMP #'*'
		BNE kp_nua
kp_ua:
; must print new address, plus dot if in data mode
			JSR kp_crad		; print address after CR
kp_wdot:
			BIT mode		; is it writing?
				BMI kp_dot		; yeah, print dot and exit
			JMP kp_mloop	; otherwise stay with address on display
kp_nua:

; ** display updated data (CR or =) **
		CMP #CR
			BEQ kp_ud
		CMP #'='
		BNE kp_nud
kp_ud:
; must print pointed data (and dot if in data entry mode)
			JSR kp_data		; print data
			_BRA kp_wdot	; ...and a dot if in write mode
kp_nud:

; ** retrieve PC contents (I) **
		CMP #'I'
		BNE kp_npc
; must copy PC as address, then print as usual
			JSR kp_chk		; update pending values
			LDY s_pc		; get saved PC
			LDA s_pc+1
			STY pointer		; store as new address
			STA pointer+1
			_BRA kp_ua		; print address
kp_npc:

; ** lastly, look for a valid hex digit, needs uppercase! **
		CMP #'F'
			BCS kp_nhex			; >F, no number
		CMP #'0'
			BCC kp_nhex			; <0, no number
		CMP #$3A
			BCC kp_hex			; <=9 is OK
		CMP #'A'
			BCC kp_nhex			; <A is not
kp_hex:
		SEC
		SBC #'0'			; ASCII to value, if number
		CMP #10				; or is it a letter? must be uppercase!
		BCC kp_hnum
			SBC #7				; convert letter to value, C is set
kp_hnum:
		ASL value			; 2 times previous value
		ROL value+1
		ASL value			; 4 times previous value
		ROL value+1
		ASL value			; 8 times previous value
		ROL value+1
		ASL value			; 16 times previous value
		ROL value+1
		ORA value			; add new cipher
		STA value
		LDA io_c			; recover raw char for echo ###
; echo desired char in A and continue
		_BRA kp_echo

; *************************
; *** business routines ***
; *************************
; * check and update pending data *
kp_chk:
	BIT mode		; was it entering address?
	BMI kp_naw		; update pointer if so
		LDY value		; get recent 16-bit number
		LDA value+1
		STY pointer		; store into address pointer
		STA pointer+1
kp_naw:				; check only pending data from here
	BIT mode		; was it writing?
	BPL kp_ndw
		LDA value		; get recent 8-bit number
		_STAY(pointer)	; store into pointed address
kp_ndw:
	_STZA value			; clear entry buffer, is this the right place?
	_STZA value+1
	RTS

; * print address after CR *
kp_crad:
	JSR newline
; print address word
	LDA pointer+1	; get MSB
	JSR kp_byte
	LDA pointer		; get LSB...
	_BRA kp_byte	; ...and print it, will return

; * print data after dot *
kp_data:
	LDA #'.'
	JSR prnChar		; separating dot
; print data
	_LDAY(pointer)	; get current contents
; * print A as two hex ciphers *
kp_byte:
	PHA				; save for later
	LSR				; shift MSNibble into position
	LSR
	LSR
	LSR
	JSR kp_nib		; print MSNibble
	PLA				; retrieve full byte, only LSNibble will remain
kp_nib:
	AND #$0F		; supress high nibble
	CMP #10			; should use letter?
	BCC kp_num
		ADC #6			; carry was set! now is clear
kp_num:
	ADC #'0'		; carry was clear, now is ASCII
; ...and fall into prnChar below! Will return (JMP otherwise)

; ***************************
; *** useful I/O routines ***
; ***************************
; * print a character in A *
prnChar:
	STA io_c			; store character
	LDY iodev			; get device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print CR *
newline:
	LDA #CR
	BNE prnChar			; no need for BRA

; *** print error message ***
kp_nex:
	LDY #<kp_err		; get pointer to error string
	LDA #>kp_err
; ...and fall into prnStr below! (will return)

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

; * read key into A (locking) *
readChar:
	LDY iodev			; get char from standard device ###
	_KERNEL(CIN)
	BCC kp_rcv			; some received!
		CPY #EMPTY			; just waiting?
		BEQ kp_mloop
			_PANIC("{dev}")		; device failed!
kp_rcv:
	LDA io_c			; read what was pressed ###
	CMP #'a'			; is it lowercase?
	BCC kp_nlc
		AND # %11011111			; convert to uppercase (letters only)
kp_nlc:
;	STA io_c			; store for echo if not using OS
	RTS

; ******************************
; *** strings and other data ***
; ******************************
kp_err:
	.asc	" Err!", CR, 0

kp_run:
	.asc	CR, "Run", CR, 0

#ifdef	NOHEAD
KPtitle:
	.asc	"KIMpad 0.1", 0	; for headerless builds
#endif

; ***** end of stuff *****
KPEnd:					; ### for easy size computation ###
.)
