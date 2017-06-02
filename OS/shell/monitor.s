; Monitor shell for minimOS (simple version)
; v0.6a7
; last modified 20170602-0845
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
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
mon_head:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
montitle:
	.asc	"monitor", 0	; file name (mandatory)
	.asc	"NMOS & 816-savvy", 0	; comment

; advance to end of header
	.dsb	mon_head + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6800		; time, 13.00
	.word	$4ABF		; date, 2017/5/31

	monSize	=	mon_end - mon_head - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	monSize		; filesize
	.word	0			; 64K space does not use upper 16-bit
#endif
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
	_sp		= _y+1		; stack pointer (will take 2 bytes in 816 version)
#ifdef	C816
	_psr	= _sp+2		; status register, leave space as above
#else
	_psr	= _sp+1		; status register, regular 8-bit size
#endif
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
; proceed normally
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<montitle		; LSB of window title
	LDA #>montitle		; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_mon		; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_mon:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####
; print splash message, just the first time!
	LDA #>mon_splash	; address of splash message
	LDY #<mon_splash
	JSR prnStr			; print the string!

; *** initialise relevant registers ***
; hopefully the remaining registers will be stored by NMI/BRK handler, especially PC!
	LDA #%00110000		; 8-bit sizes eeeeeeeek
	STA _psr			; *** essential, at least while not previously set ***
; *** store current stack pointer as it will be restored upon JMP ***
; * specially tailored code for 816-savvy version! *
get_sp:
#ifdef	C816
	.xl: REP #$10		; *** 16-bit index ***
#endif
	TSX					; get current stack pointer
	STX _sp				; store original value
#ifdef	C816
	.xs: SEP #$10		; *** regular size ***
#endif
; does not really need to set PC/ptr
; these ought to be initialised after calling a routine!
	LDA #__last-uz		; zeropage space needed (again)
	STA z_used			; set needed ZP space as required by minimOS ####
; global variables
	LDA #4				; standard number of lines
	STA lines			; set variable
	STA siz				; also default transfer size
	_STZA siz+1			; clear copy/transfer size MSB

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
		STX cursor			; save cursor!
		CMP #'Y'+1			; past last command?
			BCS bad_cmd			; unrecognised
#ifdef	SAFE
		SBC #'?'-1			; first available command (had borrow)
#else
		SBC #'A'-1			; first available command (had borrow)
#endif
			BCC bad_cmd			; cannot be lower
		ASL					; times two to make it index
		TAX					; use as index
		JSR call_mcmd		; call monitor command
		_BRA main_loop		; continue forever
; *** generic error handling ***
_unrecognised:
	PLA					; discard main loop return address
	PLA
bad_cmd:
	LDA #>err_bad		; address of error message
	LDY #<err_bad
d_error:
	JSR prnStr			; display error
	_BRA main_loop		; continue

; *** call command routine ***
call_mcmd:
	_JMPX(cmd_ptr)		; indexed jump macro, supposedly from bank 0 only!

; *** command routines, named as per pointer table ***

; ** .A = set accumulator **
set_A:
	JSR fetch_byte		; get operand in A
	STA _a				; set accumulator
	RTS

; ** .B = store byte **
store_byte:
	JSR fetch_byte		; get operand in A
	_STAY(ptr)			; set byte in memory
	INC ptr				; advance pointer
	BNE sb_end			; all done if no wrap
		INC ptr+1			; increase MSB otherwise
sb_end:
	RTS

; ** .C = call address **
call_address:
	JSR fetch_value		; get operand address
#ifdef	SAFE
	LDA tmp2			; at least one?
		BEQ _unrecognised	; reject zero loudly
#endif
; setting SP upon call makes little sense...
	LDA iodev			; *** must push default device for later ***
	PHA
	JSR do_call			; set regs and jump!
#ifdef	C816
	.xs: .as: SEP #$30	; *** make certain about standard size ***
#endif
; ** should record actual registers here **
	STA _a
	STX _x
	STY _y
	PHP					; get current status
	CLD					; eeeeeeeeeeeeeek
	PLA					; A was already saved
	STA _psr
; hopefully no stack imbalance was caused, otherwise will not resume monitor!
	PLA					; this (eeeeek) will take previously saved default device
	STA iodev			; store device!!!
	PLA					; must discard previous return address, as will reinitialise stuff!
	PLA
	JMP get_sp			; hopefully context is OK, will restore as needed

; ** .J = jump to an address **
jump_address:
	JSR fetch_value		; get operand address
#ifdef	SAFE
	LDA tmp2			; at least one?
		BEQ _unrecognised	; reject zero loudly
;	BNE jp_ok
;		JMP _unrecognised	; reject zero loudly
;jp_ok:
#endif
; restore stack pointer...
#ifdef	C816
	.xl: REP #$10		; *** essential 16-bit index ***
#endif
	LDX _sp				; get stored value (word)
	TXS					; set new pointer...
; SP restored
; restore registers and jump
do_call:
#ifdef	C816
	.xs: .as: SEP #$30	; *** make certain about standard size ***
#endif
	LDX _x				; retrieve registers
	LDY _y
	LDA _psr			; status is different
	PHA					; will be set via PLP
	LDA _a				; lastly retrieve accumulator
	PLP					; restore status
	JMP (tmp)			; go! might return somewhere else

; ** .E = examine 'u' lines of memory **
examine:
	JSR fetch_value		; get address
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

; ** .G = set stack pointer **
set_SP:
	JSR fetch_byte		; get operand in A
	STA _sp				; set stack pointer (LSB only)
	RTS

; ** .? = show commands **
#ifdef	SAFE
help:
	LDA #>help_str		; help string
	LDY #<help_str
	JMP prnStr			; print it, and return to main loop
#endif

; ** .K = keep (load or save) **
; ### highly system dependent ###
; placeholder will send (-) or read (+) raw data to/from indicated I/O device
ext_bytes:
; *** set labels from miniMoDA ***
count	= tmp2+1		; subcommand
temp	= cursor		; will store I/O channel
oper	= tmp			; 16-bit counter
; try to get subcommand, then device
	JSR getNextChar		; check for subcommand
	TAY					; already at the end?
	BNE ex_noni			; not yet
ex_abort:
		JMP _unrecognised			; fail loudly otherwise
ex_noni:
; there is subcommand, let us check target device ###placeholder
	STA count			; first save the subcommand!
	JSR fetch_byte		; read desired device
		BCS ex_abort		; could not get it
	STA temp			; set as I/O channel
	LDY #0				; reset counter!
	STY oper			; also reset forward counter, decrement is too clumsy!
	STY oper+1
; check subcommand
#ifdef	SAFE
	LDA count			; restore subcommand
	CMP #'+'			; is it load?
		BEQ ex_do			; OK then
	CMP #'-'			; is it save? (MARATHON MAN)
		BNE ex_abort		; if not, complain
#endif
ex_do:
; decide what to do
	LDA count			; restore subcommand
	CMP #'+'			; is it load?
	BEQ ex_load			; OK then
; otherwise assume save!
; save raw bytes
		LDA (ptr), Y		; get source data
		STA io_c			; set parameter
		_PHY				; save index
		LDY temp			; get target device
		_KERNEL(COUT)		; send raw byte!
		_PLY				; restore index eeeeeeeeeek
			BCS ex_err			; aborted!
		BCC ex_next			; otherwise continue, no need for BRA
; load raw bytes
ex_load:
		_PHY				; save index
		LDY temp			; get target device
		_KERNEL(CIN)		; get raw byte!
		_PLY				; restore index
			BCS ex_err			; aborted!
		LDA io_c			; get parameter
		STA (ptr), Y		; write destination data
; go for next byte in any case
ex_next:
		INY					; go for next
		BNE ex_nw			; no wrap
			INC ptr+1
ex_nw:
; 16-bit counter INcrement
		INC oper			; one more
		BNE ex_sinc			; no wrap
			INC oper+1
ex_sinc:
; have we finished yet?
		LDA oper			; check LSB
		CMP siz				; compare against desired size
		BNE ex_do			; continue until done
			LDA oper+1			; check MSB, just in case
			CMP siz+1			; against size
		BNE ex_do			; continue until done
ex_ok:
; update PC LSB!
	TYA					; current offset
	CLC
	ADC ptr				; add base LSB
	STA ptr				; update
	BCC ex_show			; no wrap
		INC ptr+1			; or carry to MSB
ex_show:
; transfer ended, show results
#ifndef	SAFE
ex_err:					; without I/O error message, indicate 0 bytes transferred
#endif
	LDA oper			; get LSB
	PHA					; into stack
	LDA oper+1			; get MSB
	PHA					; same
	JMP nu_end			; and print it! eeeeeek return also
#ifdef	SAFE
ex_err:
; an I/O error occurred during transfer!
	LDA #>io_err		; set message pointer
	LDY #<io_err
	JSR prnStr			; print it and finish function afterwards
	_BRA ex_show		; there is nothing to increment!
#endif

; ** .M = move (copy) 'n' bytes of memory **
move:
; preliminary version goes forward only, modifies ptr.MSB and X!

	JSR fetch_value		; get operand word
#ifdef	SAFE
	LDA tmp2			; at least one?
	BNE mv_ok
		JMP _unrecognised	; reject zero loudly
mv_ok:
#endif
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

; ** .N = set 'n' value **
set_count:
	JSR fetch_value		; get operand word
	LDA tmp				; copy LSB
#ifdef	SAFE
	BNE sc_ok			; not zero is OK
		LDX tmp+1			; check MSB otherwise
		BEQ sc_z			; there was nothing!
sc_ok:
#endif
	STA siz				; into destination variable
sc_z:
	PHA					; for common ending!
	LDA tmp+1			; and MSB
	STA siz+1
	PHA					; to be displayed right now...

; *** common ending for .N and .U ***
; 16-bit REVERSED value on stack!
nu_end:
	LDA #>set_str		; pointer to rest of message
	LDY #<set_str
	JSR prnStr			; print that
	PLA					; check current or updated value MSB
	JSR prnHex			; show in hex
	PLA					; same for LSB
	JSR prnHex			; show in hex
	JMP po_cr			; print trailing newline and return!

; ** .O = set origin **
origin:
	JSR fetch_value		; get operand word
	LDY tmp				; copy LSB
	LDA tmp+1			; and MSB
	STY ptr				; into destination variable
	STA ptr+1
	RTS

; ** .P = set status register **
set_PSR:
	JSR fetch_byte		; get operand in A
	ORA #$30			; *** let X & M set on 65816 ***
	STA _psr			; set status
	RTS

; ** .Q = standard quit **
quit:
; will not check any pending issues
	PLA					; discard main loop return address
	PLA
	_FINISH				; exit to minimOS, proper error code

; ** .S = store raw string **
store_str:
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
		BNE store_str		; boundary not crossed
	INC ptr+1			; next page otherwise
	BNE store_str		; continue, no real need for BRA
sstr_cr:
	_STZA buffer, X		; terminate string
sstr_end:
	RTS

; ** .U = set 'u' number of lines/instructions **
set_lines:
	JSR fetch_byte		; get operand in A
#ifdef	SAFE
	TAX					; check value
		BEQ sl_z			; nothing to set
#endif
	STA lines			; set number of lines
sl_z:
	PHA					; to be displayed
	LDA #0				; no MSB
	PHA
	_BRA nu_end

; ** .V = view register values **
view_regs:
	LDA #>regs_head		; print header
	LDY #<regs_head
	JSR prnStr
; since _pc and ptr are the same, no need to print it!
	LDX #0				; reset counter
vr_l:
		_PHX				; save index!
		LDA _a, X			; get value from regs
		JSR prnHex			; show value in hex
; without PC being shown, narrow displays will also put regular spacing
		LDA #' '			; space, not for 20-char
		JSR prnChar			; print it
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
po_cr:
	LDA #CR				; print newline
	JMP prnChar			; will return

; ** .W = store word **
store_word:
	JSR fetch_value		; get operand word
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

; ** .X = set X register **
set_X:
	JSR fetch_byte		; get operand in A
	STA _x				; set register
	RTS

; ** .Y = set Y register **
set_Y:
	JSR fetch_byte		; get operand in A
	STA _y				; set register
	RTS

; ** .R = reboot or shutdown **
reboot:
	JSR getNextChar		; is there an extra character?
	TAX					; check whether end of buffer
		BEQ rb_exit			; no interactive option
	CMP #'W'			; asking for warm boot?
	BNE rb_notw
		LDY #PW_WARM		; warm boot request ## minimOS specific ##
		_BRA fw_shut		; call firmware, could use BNE?
rb_notw:
	CMP #'C'			; asking for cold boot?
	BNE rb_notc
		LDY #PW_COLD		; cold boot request ## minimOS specific ##
		_BRA fw_shut		; call firmware, could use BNE?
rb_notc:
	CMP #'S'			; asking for shutdown?
	BNE rb_exit			; otherwise abort quietly
		LDY #PW_OFF			; poweroff request ## minimOS specific ##
fw_shut:
		_KERNEL(SHUTDOWN)	; unified firmware call
rb_exit:
	RTS					; needs to return and wait for the complete shutdown!


; *** useful routines ***
; ** basic output and hexadecimal handling **

; might include this library when a portable, properly interfaced one is available!
;#include "libs/hexio.s"
; in the meanwhile, it takes these subroutines

; * print a byte in A as two hex ciphers *
prnHex:
	PHA					; keep whole value
	LSR					; shift right four times (just the MSB)
	LSR
	LSR
	LSR
	JSR ph_b2a			; convert and print this cipher
	PLA					; retrieve full value
	AND #$0F			; keep just the LSB... and repeat procedure
ph_b2a:
	CMP #10				; will be a letter?
	BCC ph_n			; just a number
		ADC #6				; convert to letter (plus carry)
ph_n:
	ADC #'0'			; convert to ASCII (carry is clear)
; ...and print it (will return somewhere)

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
		PHK					; get current bank
		PLA					; pick it up
		STA str_pt+2		; set accordingly
#endif
	LDY iodev			; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS

; * convert two hex ciphers into byte@tmp, A is current char, X is cursor *
; * new approach for hex conversion *
; * add one nibble from hex in current char!
; A is current char, returns result in value[0...1]
; does NOT advance any cursor (neither reads char from nowhere)
; MUST reset value previously!
hex2nib:
	SEC					; prepare for subtract
	SBC #'0'			; convert from ASCII
		BCC h2n_err			; below number!
	CMP #10				; already OK?
	BCC h2n_num			; do not convert from letter
		CMP #23				; otherwise should be a valid hex
			BCS h2n_rts			; or not! exits with C set
		SBC #6				; convert from hex (C is clear!)
h2n_num:
	LDY #4				; shifts counter, no longer X in order to save some pushing!
h2n_loop:
		ASL tmp				; current value will be times 16
		ROL tmp+1
		DEY					; next iteration
		BNE h2n_loop
	ORA tmp				; combine with older value
	STA tmp
	CLC					; all done without error
h2n_rts:
	RTS					; usual exit
h2n_err:
	SEC					; notify error!
	RTS

; ** end of inline library **

; * get input line from device at fixed-address buffer *
; new from API!
getLine:
	LDY #<buffer		; get buffer address
	STY str_pt			; set parameter
	_STZA str_pt+1		; it IS in zeropage!
	LDX #BUFSIZ-1		; max index
	STX ln_siz			; set value
	LDY iodev			; use device
	_KERNEL(READLN)		; get line
; *** 16-bit API would resolve, but access from here is thru ZP opcodes ***
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
	CMP #'a'			; not lowercase?
		BCC gn_ok			; all done!
	CMP #'z'+1			; still within lowercase?
		BCS gn_ok			; otherwise do not correct!
	AND #%11011111		; remove bit 5 to uppercase
gn_ok:
	STX cursor			; eeeeeeeeeeeeeeeeeeeeek
	RTS

; * back off one character, skipping whitespace, use instead of DEC cursor! *
backChar:
	LDX cursor			; get current position
bc_loop:
		DEX					; back once
		LDA buffer, X		; check what is pointed
		CMP #' '			; blank?
			BEQ bc_loop			; once more
		CMP #TAB			; tabulation?
			BEQ bc_loop			; ignore
		CMP #'$'			; ignored radix?
			BEQ bc_loop			; also ignore
	STX cursor				; otherwise we are done
	RTS

; * fetch one byte from buffer, value in A and @value.b *
; newest approach as interface for fetch_value
fetch_byte:
	JSR fetch_value		; get whatever
	LDA tmp2			; how many bytes will fit?
	_INC				; round up chars...
	LSR					; ...and convert to bytes
	CMP #1				; strictly one?
	_BRA ft_check		; common check

; * fetch two bytes from hex input buffer, value @value.w *
fetch_word:
; another approach using fetch_value
	JSR fetch_value		; get whatever
	LDA tmp2			; how many bytes will fit?
	_INC				; round up chars...
	LSR					; ...and convert to bytes
	CMP #2				; strictly two?
; common fetch error check
ft_check:
	BNE ft_err
		CLC					; if so, all OK
		LDA tmp				; convenient!!!
		RTS
; common fetch error discard routine
ft_err:
	LDA tmp2			; check how many chars were processed eeeeeeek
	BEQ ft_clean		; nothing to discard eeeeeeeeek
ft_disc:
		JSR backChar		; should discard previous char!
		DEC tmp2			; one less to go
		BNE ft_disc			; continue until all was discarded
ft_clean:
	SEC					; there was an error
	RTS

; * fetch typed value, no matter the number of chars *
fetch_value:
	_STZA tmp			; clear full result
	_STZA tmp+1
	_STZA tmp2			; no chars processed yet
; could check here for symbolic references...
ftv_loop:
		JSR getNextChar		; go to operand first cipher!
		JSR hex2nib			; process one char
			BCS ftv_bad			; no more valid chars
		INC tmp2			; otherwise count one
		BNE ftv_loop		; until no more valid, no real need for BRA
ftv_bad:
	JSR backChar		; should discard very last char! eeeeeeeek
	CLC					; always check temp=0 for errors!
	RTS

; *** pointers to command routines (? to Y) ***
cmd_ptr:
#ifdef	SAFE
	.word	help			; .?
	.word		_unrecognised	; .@
#endif
	.word	set_A			; .A
	.word	store_byte		; .B
	.word	call_address	; .C
	.word		_unrecognised	; .D
	.word	examine			; .E
	.word		_unrecognised	; .F
	.word	set_SP			; .G
	.word		_unrecognised	; .H
	.word		_unrecognised	; .I
	.word	jump_address	; .J
	.word	ext_bytes		; .K
	.word		_unrecognised	; .L
	.word	move			; .M
	.word	set_count		; .N
	.word	origin			; .O
	.word	set_PSR			; .P
	.word	quit			; .Q
	.word	reboot			; .R
	.word	store_str		; .S
	.word		_unrecognised	; .T
	.word	set_lines		; .U
	.word	view_regs		; .V
	.word	store_word		; .W
	.word	set_X			; .X
	.word	set_Y			; .Y


; *** strings and other data ***
#ifdef	NOHEAD
montitle:
	.asc	"monitor", 0
#endif

mon_splash:
	.asc	"minimOS 0.6 monitor", CR
	.asc	"(c) 2016-2017 Carlos J. Santisteban", CR, 0


err_bad:
	.asc	"** Bad command **", CR, 0

regs_head:
	.asc	"A: X: Y: S: NV-bDIZC", CR, 0

dump_in:
#ifdef	NARROW
	.asc	"[", 0		; for 20-char version
#else
	.asc	" [", 0
#endif

dump_out:
	.asc	"] ", 0

set_str:
	.asc	"-> $", 0

#ifdef	SAFE
; I/O error message stripped on non-SAFE version
io_err:
	.asc	"*** I/O error ***", CR, 0

; online help only available under the SAFE option!
help_str:
	.asc	"---Command list---", CR
	.asc	"? = show this list", CR
	.asc	"Ad = set A reg.", CR
	.asc	"Bd = store byte", CR
	.asc	"C* = call subroutine", CR
	.asc	"E* = dump 'u' lines", CR
	.asc	"Gd = set SP reg.", CR
	.asc	"J* = jump to address", CR
	.asc	"Kcd=load/save n byt.", CR
	.asc	"   from/to device #d", CR
	.asc	"Ma =copy n byt. to a", CR
	.asc	"N* = set 'n' value", CR
	.asc	"O* = set origin", CR
	.asc	"Pd = set Status reg", CR
	.asc	"Q = quit", CR
	.asc	"Rx = reboot/poweroff", CR
	.asc	"Ss = put raw string", CR
	.asc	"Ud = set 'u' lines", CR
	.asc	"V = view registers", CR
	.asc	"Wa = store word", CR
	.asc	"Xd = set X reg.", CR
	.asc	"Yd = set Y reg.", CR
	.asc	"--- values ---", CR
	.asc	"d => 2 hex char.", CR
	.asc	"a => 4 hex char.", CR
	.asc	"* => up to 4 char.", CR
	.asc	"s => raw string", CR
	.asc	"c = +(load)/ -(save)", CR
	.asc	"x=Cold/Warm/Shutdown", CR

#endif
	.byt	0

mon_end:				; for size computation
.)
