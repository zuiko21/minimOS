; Monitor shell for minimOS (simple version)
; v0.5rc13
; last modified 20170123-1339
; (c) 2016-2017 Carlos J. Santisteban

#include "usual.h"

.(
; *** uncomment for narrow (20-char) displays ***
;#define	NARROW	_NARROW

; *** constant definitions ***
#define	BUFSIZ		16
; bytes per line in dumps 4 or 8/16
#ifdef	NARROW
#define		PERLINE		4
#else
#define		PERLINE		8
#endif

; ##### include minimOS headers and some other stuff #####
mon_head:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
	.asc	"monitor", 0, 0	; file name (mandatory) and empty comment

; advance to end of header
	.dsb	mon_head + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6800		; time, 13.00
	.word	$4A37		; date, 2017/1/23

	monSize	=	mon_end - mon_head - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	monSize		; filesize
	.word	0			; 64K space does not use upper 16-bit
; ##### end of minimOS executable header #####


; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	ptr		= uz		; current address pointer
	siz		= ptr+2		; number of bytes to copy or transfer ('n')
	lines	= siz+2		; lines to dump ('u')
	_pc		= lines+1	; PC, would be filled by NMI/BRK handler
	_a		= _pc+2		; A register
	_x		= _a+1		; X register
	_y		= _x+1		; Y register
	_sp		= _y+1		; stack pointer
	_psr	= _sp+1		; status register
	cursor	= _psr+1	; storage for X offset
	buffer	= cursor+1		; storage for input line (BUFSIZ chars)
	tmp		= buffer+BUFSIZ	; temporary storage
	tmp2	= tmp+2		; for hex dumps
	iodev	= tmp2+2	; standard I/O ##### minimOS specific #####

	__last	= iodev+1	; ##### just for easier size check #####

; *** initialise the monitor ***

; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_mon			; enough space
	BEQ go_mon			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_mon:
#endif
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<title			; LSB of window title
	LDA #>title			; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_mon		; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_mon:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####

; global variables
	LDA #>user_sram		; initial address ##### provided by rom.s, but may be changed #####
	LDY #<user_sram
	STY ptr				; store LSB
	STA ptr+1			; and MSB
	LDA #4				; standard number of lines
	STA lines			; set variable
	STA siz				; also default transfer size
	_STZA siz+1			; clear copy/transfer size MSB
	LDA #>splash		; address of splash message
	LDY #<splash
	JSR prnStr			; print the string!

; *** store current stack pointer as it will be restored upon JSR/JMP ***
; hopefully the remaining registers will be stored by NMI/BRK handler, especially PC!
get_sp:
	TSX					; get current stack pointer
	STX _sp				; store original value

; *** begin things ***
main_loop:
; put current address before prompt
		LDA ptr+1			; MSB goes first
		JSR prnHex			; print it
		LDA ptr				; same for LSB
		JSR prnHex
		LDA #'>'		; prompt character
		JSR prnChar			; print it
		JSR getLine			; input a line
		LDX #$FF			; getNextChar will advance it to zero!
		JSR gnc_do			; get first character on string, without the variable
		TAY					; just in case...
			BEQ main_loop		; ignore blank lines! 
;		CMP #'.'			; command introducer (not used nor accepted if monitor only)
;			BNE not_mcmd		; not a monitor command
;		JSR gnc_do			; get into command byte otherwise
		STX cursor			; save cursor!
		CMP #'Z'+1			; past last command?
			BCS bad_cmd			; unrecognised
		SBC #'A'-1			; first available command (had borrow)
			BCC bad_cmd			; cannot be lower
		ASL					; times two to make it index
		TAX					; use as index
		JSR call_mcmd		; call monitor command
		_BRA main_loop		; continue forever
;not_mcmd:
;	LDA #>err_mmod		; address of error message
;	LDY #<err_mmod
;	_BRA d_error		; display error
bad_cmd:
	LDA #>err_bad		; address of error message
	LDY #<err_bad
d_error:
	JSR prnStr			; display error
	_BRA main_loop		; continue

; *** call command routine ***
call_mcmd:
	_JMPX(cmd_ptr)		; indexed jump macro

; *** command routines, named as per pointer table ***
set_A:
	JSR fetch_byte		; get operand in A
	STA _a				; set accumulator
	RTS

store_byte:
	JSR fetch_byte		; get operand in A
	_STAY(ptr)			; set byte in memory
	INC ptr				; advance pointer
	BNE sb_end			; all done if no wrap
		INC ptr+1			; increase MSB otherwise
sb_end:
	RTS

call_address:
	JSR fetch_word		; get operand address
; now ignoring operand errors!
; restore stack pointer... and forget return address (will jump anyway)
;	LDX _sp				; get stored value
;	TXS					; set new pointer...
; SP restored
	JSR do_call			; set regs and jump!
; ** should record actual registers here **
	STA _a
	STX _x
	STY _y
	PHP					; get current status
	PLA					; A was already saved
	STA _psr
;	PLA					; discard main loop return address EEEEEEEEK
;	PLA
;	JMP get_sp			; hopefully context is OK
	RTS

jump_address:
	JSR fetch_word		; get operand address
; now ignoring operand errors!
; restore stack pointer...
	LDX _sp				; get stored value
	TXS					; set new pointer...
; SP restored
; restore registers and jump
do_call:
	LDX _x				; retrieve registers
	LDY _y
	LDA _psr			; status is different
	PHA					; will be set via PLP
	LDA _a				; lastly retrieve accumulator
	PLP					; restore status
	JMP (tmp)			; go! might return somewhere else

examine:
	JSR fetch_word		; get address
	LDY tmp				; save tmp elsewhere
	LDA tmp+1
	STY tmp2
	STA tmp2+1
	LDX lines			; get counter
ex_l:
		_PHX				; save counters
		LDA tmp2+1			; address MSB
		JSR prnHex			; print it
		LDA tmp2			; same for LSB
		JSR prnHex
		LDA #>dump_in		; address of separator
		LDY #<dump_in
		JSR prnStr			; print it
		; loop for 4/8 hex bytes
		LDY #0				; reset offset
ex_h:
			_PHY				; save offset
; space only when wider than 20 char AND if not the first
#ifndef	NARROW
			BEQ ex_ns			; no space if the first one
				_PHY				; please keep Y!
				LDA #' '			; print space, not in 20-char
				JSR prnChar
				_PLY				; retrieve Y!
ex_ns:
#endif
			LDA (tmp2), Y		; get byte
			JSR prnHex			; print it in hex
			_PLY				; retrieve index
			INY					; next byte
			CPY #PERLINE		; bytes per line (8 if not 20-char)
			BNE ex_h			; continue line
		LDA #>dump_out		; address of separator
		LDY #<dump_out
		JSR prnStr			; print it
		; loop for 4/8 ASCII
		LDY #0				; reset offset
ex_a:
			_PHY				; save offset BEFORE!
			LDA (tmp2), Y		; get byte
			CMP #127			; check whether printable
				BCS ex_np
			CMP #' '
				BCC ex_np
			_BRA ex_pr			; it is printable
ex_np:
				LDA #'.'			; substitute
ex_pr:		JSR prnChar			; print it
			_PLY				; retrieve index
			INY					; next byte
			CPY #PERLINE		; bytes per line (8 if not 20-char)
			BNE ex_a			; continue line
		LDA #CR				; print newline
		JSR prnChar
		LDA tmp2			; get pointer LSB
		CLC
		ADC #PERLINE		; add shown bytes (8 if not 20-char)
		STA tmp2			; update pointer
		BCC ex_npb			; skip if within same page
			INC tmp2+1			; next page
ex_npb:
		_PLX				; retrieve counter!!!!
		DEX					; one line less
		BNE ex_l			; continue until done
	RTS

set_SP:
	JSR fetch_byte		; get operand in A
	STA _sp				; set stack pointer
	RTS

help:
	LDA #>help_str		; help string
	LDY #<help_str
	JMP prnStr			; print it, and return to main loop

move:
; preliminary version goes forward only, modifies ptr.MSB and X!

	JSR fetch_word		; get operand word
	LDY #0				; reset offset
	LDX siz+1			; check n MSB
		BEQ mv_l			; go to second stage if zero
mv_hl:
		LDA (ptr), Y		; get source byte
		STA (tmp), Y		; copy at destination
		INY					; next byte
		BNE mv_hl			; until a page is done
	INC ptr+1			; next page
	INC tmp+1
	DEX					; one less to go
		BNE mv_hl			; stay in first stage until the last page
	LDA siz				; check LSB
		BEQ mv_end			; nothing to copy!
mv_l:
		LDA (ptr), Y		; get source byte
		STA (tmp), Y		; copy at destination
		INY					; next byte
		CPY siz				; compare with LSB
		BNE mv_l			; continue until done
mv_end:
	RTS

set_count:
	JSR fetch_word		; get operand word
	LDY tmp				; copy LSB
	LDA tmp+1			; and MSB
	STY siz				; into destination variable
	STA siz+1
	RTS

origin:
	JSR fetch_word		; get operand word
	LDY tmp				; copy LSB
	LDA tmp+1			; and MSB
	STY ptr				; into destination variable
	STA ptr+1
	RTS

set_PSR:
	JSR fetch_byte		; get operand in A
	STA _psr			; set status
	RTS

quit:
; will not check any pending issues
	PLA					; discard main loop return address
	PLA
	_FINISH				; exit to minimOS, proper error code

store_str:
;	LDY cursor				; use as offset
sstr_l:
		INC cursor			; skip the S and increase, not INY
		LDY cursor			; allows NMOS macro!
		LDA buffer, Y		; get raw character
		_STAY(ptr)			; store in place, STAX will not work
#ifdef	NMOS
		TAY					; update flags altered by macro!
#endif
			BEQ sstr_end		; until terminator, will be stored anyway
		CMP #CR				; newline also accepted, just in case
			BEQ sstr_cr			; terminate and exit
		INC ptr				; advance destination
		BNE sstr_l			; boundary not crossed
	INC ptr+1			; next page otherwise
	_BRA sstr_l			; continue
sstr_cr:
	_STZA buffer, X		; terminate string
sstr_end:
	RTS

set_lines:
	JSR fetch_byte		; get operand in A
	STA lines			; set number of lines
	RTS

view_regs:
	LDA #>regs_head		; print header
	LDY #<regs_head
	JSR prnStr
; PC might get printed by loop below in 20-char version
	LDA _pc+1			; get PC MSB
	JSR prnHex			; show it
	LDA _pc				; same for LSB
	JSR prnHex

#ifndef	NARROW
	LDA #' '			; space (not used in 20-char version)
	JSR prnChar			; print it
#endif

	LDX #0				; reset counter
vr_l:
		_PHX				; save index!
		LDA _a, X			; get value from regs
		JSR prnHex			; show value in hex

#ifndef	NARROW
		LDA #' '			; space, not for 20-char
		JSR prnChar			; print it
#endif

		_PLX				; restore index
		INX					; next reg
		CPX #4				; all regs done?
		BNE vr_l			; continue otherwise
	LDX #8				; number of bits
	STX tmp				; temp counter
	LDA _psr			; copy original value
	STA tmp+1			; temp storage
vr_sb:
		ASL tmp+1			; get highest bit
		LDA #' '			; default is off (space)
		BCC vr_off			; was off
			_INC				; otherwise turns into '!'
vr_off:
		JSR prnChar			; prints bit
		DEC tmp				; one less
		BNE vr_sb			; until done
	LDA #CR				; print newline
	JMP prnChar			; will return

store_word:
	JSR fetch_word		; get operand word
	LDA tmp				; get LSB
	_STAY(ptr)			; store in memory
	INC ptr				; next byte
	BNE sw_nw			; no wrap
		INC ptr+1			; otherwise increment pointer MSB
sw_nw:
	LDA tmp+1			; same for MSB
	_STAY(ptr)
	INC ptr				; next byte
	BNE sw_end			; no wrap
		INC ptr+1			; otherwise increment pointer MSB
sw_end:
	RTS

set_X:
	JSR fetch_byte		; get operand in A
	STA _x				; set register
	RTS

set_Y:
	JSR fetch_byte		; get operand in A
	STA _y				; set register
	RTS

force:
	LDY #PW_COLD		; cold boot request ** minimOS specific **
	_BRA fw_shut		; call firmware

reboot:
	LDY #PW_WARM		; warm boot request ** minimOS specific **
	_BRA fw_shut		; call firmware

poweroff:
	LDY #PW_OFF			; poweroff request ** minimOS specific **
fw_shut:
	_KERNEL(SHUTDOWN)

_unrecognised:
	PLA					; discard main loop return address
	PLA
	JMP bad_cmd			; show error message and continue

; *** useful routines ***
; ** basic output and hexadecimal handling **

; might include this library when a portable, properly interfaced one is available!
;#include "libs/hexio.s"
; in the meanwhile, it takes these subroutines

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

; * convert two hex ciphers into byte@tmp, A is current char, X is cursor *
hex2byte:
	LDY #0				; reset loop counter
	STY tmp				; also reset value
h2b_l:
		SEC					; prepare
		SBC #'0'			; convert to value
			BCC h2b_err			; below number!
		CMP #10				; already OK?
		BCC h2b_num			; do not shift letter value
			CMP #23			; should be a valid hex
				BCS h2b_err			; not!
			SBC #6			; convert from hex (had CLC before!)
h2b_num:
		ASL tmp				; older value times 16
		ASL tmp
		ASL tmp
		ASL tmp
		ORA tmp				; add computed nibble
		STA tmp				; and store full byte
		JSR gnc_do			; go for next hex cipher *** THIS IS OUTSIDE THE LIB ***
		INY					; loop counter
		CPY #2				; two ciphers per byte
		BNE h2b_l			; until done
	RTS					; value is at tmp
h2b_err:
	DEX					; will try to reprocess this char
	RTS

; * print a byte in A as two hex ciphers *
prnHex:
	JSR ph_conv			; first get the ciphers done
	LDA tmp				; get cipher for MSB
	JSR prnChar			; print it!
	LDA tmp+1			; same for LSB
	JMP prnChar  ; will return
ph_conv:
	STA tmp+1			; keep for later
	AND #$F0			; mask for MSB
	LSR					; convert to value
	LSR
	LSR
	LSR
	LDY #0				; this is first value
	JSR ph_b2a			; convert this cipher
	LDA tmp+1			; get again
	AND #$0F			; mask for LSB
	INY					; this will be second cipher
ph_b2a:
	CMP #10				; will be letter?
	BCC ph_n			; numbers do not need this
		ADC #'A'-'9'-2		; turn into letter, C was set
ph_n:
	ADC #'0'			; turn into ASCII
	STA tmp, Y
	RTS

; ** end of inline library **

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

; * get clean character from buffer in A, cursor at X *
getNextChar:
	LDX cursor			; retrieve index
gnc_do:
	INX					; advance!
	LDA buffer, X		; get raw character
	  BEQ gn_ok  ; go away if ended
	CMP #' '			; white space?
		BEQ gnc_do			; skip it!
	CMP #'$'			; ignored radix?
		BEQ gnc_do			; skip it!
;	CMP #';'			; is it a comment?
;		BEQ gn_fin			; forget until the end
	CMP #'a'			; not lowercase?
		BCC gn_ok			; all done!
	CMP #'z'+1			; still within lowercase?
		BCS gn_ok			; otherwise do not correct!
	AND #%11011111		; remove bit 5 to uppercase
gn_ok:
	RTS
;gn_fin:
;		INX				; skip another character in comment
;		LDA buffer, X	; get pointed char
;			BEQ gn_ok		; finish if already at terminator
;		CMP #58			; colon ends sentence
;			BEQ gn_ok
;		CMP #CR			; newline ends too
;			BNE gn_fin
;	RTS


; * fetch one byte from buffer, value in A *
fetch_byte:
	JSR getNextChar		; go to operand
	JSR hex2byte		; convert value
	LDA tmp				; converted byte
	RTS

; * fetch more than one byte from hex input buffer *
fetch_word:
	JSR fetch_byte		; get operand in A
	STA tmp+1			; leave room for next
	DEX					; as will increment...
	JSR gnc_do			; get next char!!!
	JMP hex2byte		; get second byte, tmp is little-endian now, will return


; *** pointers to command routines ***
cmd_ptr:
	.word	set_A			; .A
	.word	store_byte		; .B
	.word	call_address	; .C
	.word	_unrecognised	; .D
	.word	examine			; .E
	.word	force			; .F
	.word	set_SP			; .G
	.word	help			; .H
	.word	_unrecognised	; .I
	.word	jump_address	; .J
	.word	_unrecognised	; .K
	.word	_unrecognised	; .L
	.word	move			; .M
	.word	set_count		; .N
	.word	origin			; .O
	.word	set_PSR			; .P
	.word	quit			; .Q
	.word	reboot			; .R
	.word	store_str		; .S
	.word	_unrecognised	; .T
	.word	set_lines		; .U
	.word	view_regs		; .V
	.word	store_word		; .W
	.word	set_X			; .X
	.word	set_Y			; .Y
	.word	poweroff		; .Z

; *** strings and other data ***
title:
	.asc	"miniMonitor", 0

splash:
	.asc	"minimOS 0.5.1 monitor", CR
	.asc	"(c) 2016-2017 Carlos J. Santisteban", CR, 0


;err_mmod:
;	.asc	"***Missing module***", CR, 0

err_bad:
	.asc	"*** Bad command ***", CR, 0

regs_head:
#ifdef	NARROW
	.asc	"PC: A:X:Y:S:NV-bDIZC", CR, 0	; for 20-char devices
#else
	.asc	"PC:  A: X: Y: S: NV-bDIZC", CR, 0
#endif

dump_in:
#ifdef	NARROW
	.asc	"[", 0		; for 20-char version
#else
	.asc	" [", 0
#endif

dump_out:
	.asc	"] ", 0

; online help only available under the SAFE option!
help_str:
#ifdef	SAFE
	.asc	"---Command list---", CR
	.asc	"(d = 2 hex char.)", CR
	.asc	"(a = 4 hex char.)", CR
	.asc	"(s = raw string)", CR
	.asc	"Ad = set A reg.", CR
	.asc	"Bd = store byte", CR
	.asc	"Ca = call subr.", CR
	.asc	"Ea = dump 'u' lines", CR
	.asc	"F = cold boot", CR
	.asc	"Gd = set SP reg.", CR
	.asc	"H = show this list", CR
	.asc	"Ja = jump", CR
	.asc	"Ma =copy n byt. to a", CR
	.asc	"Na = set 'n' bytes", CR
	.asc	"Oa = set address", CR
	.asc	"Pd = set Status reg.", CR
	.asc	"Q = quit", CR
	.asc	"R = reboot", CR
	.asc	"Ss = put raw string", CR
	.asc	"Ud = set 'u' lines", CR
	.asc	"V = view registers", CR
	.asc	"Wa = store word", CR
	.asc	"Xd = set X reg.", CR
	.asc	"Yd = set Y reg.", CR
	.asc	"Z = poweroff", CR
#endif
	.byt	0
mon_end:				; for size computation
.)
