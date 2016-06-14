; Monitor-debugger-assembler shell for minimOS!
; v0.5b4
; last modified 20160614-1014
; (c) 2016 Carlos J. Santisteban

; ##### minimOS stuff but check macros.h for CMOS opcode compatibility #####

#ifndef	KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
.text
#endif

; *** uncomment for narrow (20-char) displays ***
;#define	NARROW	_NARROW

; *** constant definitions ***
#define	BUFSIZ		16
#define	CR			13
#define	TAB			9
#define	BS			8
#define	BEL			7
#define	COLON		58

; bytes per line in dumps 4 or 8/16
#ifdef	NARROW
#define		PERLINE		4
#else
#define		PERLINE		8
#endif

; ##### include minimOS headers and some other stuff #####
-shell:
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	ptr		= uz		; current address pointer, would be filled by NMI/BRK handler
	_pc		= ptr		; ***unified variables, keep both names for compatibility***
	_a		= _pc+2		; A register
	_x		= _a+1		; X register
	_y		= _x+1		; Y register
	_sp		= _y+1		; stack pointer
	_psr	= _sp+1		; status register
	siz		= _psr+1	; number of bytes to copy or transfer ('n')
	lines	= siz+2		; lines to dump ('u')
	cursor	= lines+1	; storage for cursor offset, now on Y
	buffer	= cursor+1	; storage for direct input line (BUFSIZ chars)
	value	= buffer+BUFSIZ	; fetched values
	oper	= value+2	; operand storage
	temp	= oper+2	; temporary storage, also for indexes
	scan	= temp+1	; pointer to opcode list
	bufpt	= scan+2	; NEW pointer to variable buffer
	count	= bufpt+2	; char count for screen formatting, also opcode count
	bytes	= count+1	; bytes per instruction
	iodev	= bytes+1	; standard I/O ##### minimOS specific #####

	__last	= iodev+1	; ##### just for easier size check #####

; *** initialise the monitor ***

; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_da			; enough space
	BEQ go_da			; just enough!
		_ERR(FULL)			; not enough memory otherwise (rare)
go_da:
#endif
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<title			; LSB of window title
	LDA #>title			; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_da			; no errors
		_ERR(NO_RSRC)		; abort otherwise! proper error code
open_da:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####

; global variables
; will no longer set ptr, as should be done by BRK/NMI handler as _pc
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
;		_STZA cursor		; eeeeeeeeeek... but really needed?
; *** NEW variable buffer setting ***
		LDY #<buffer		; get LSB that is full address in zeropage
		LDA #0				; ### in case of 65816 should be TDC, XBA!!! ###
		STY bufpt			; set new movable pointer
		STA bufpt+1
; put current address before prompt
		LDA ptr+1			; MSB goes first
		JSR prnHex			; print it
		LDA ptr				; same for LSB
		JSR prnHex
		LDA #'>'			; prompt character
		JSR prnChar			; print it
		JSR getLine			; input a line
; execute single command (or assemble opcode) from buffer
cli_loop:
		LDY #$FF			; getNextChar will advance it to zero!
		JSR gnc_do			; get first character on string, without the variable
		TAX					; set status for A
			BEQ main_loop		; ignore blank lines! 
		CMP #COLON			; end of instruction?
			BEQ cli_chk			; advance to next valid char
		CMP #'.'			; comtmpmand introducer (not used nor accepted if monitor only)
			BNE not_mcmd		; not a monitor command
		JSR gnc_do			; get into command byte otherwise
		CMP #'Z'+1			; past last command?
			BCS bad_cmd			; unrecognised
		SBC #'A'-1			; first available command (had borrow)
			BCC bad_cmd			; cannot be lower
		ASL					; times two to make it index
		TAX					; use as index
		JSR call_mcmd		; call monitor command
		JSR getNextChar		; should be done but check whether in direct mode
		BCC cmd_term		; no more commands in line (or directly to main loop?)
cli_chk:
			TYA					; otherwise advance pointer
			SEC					; set carry in case the BCC is skipped! eeeek
			ADC bufpt			; carry was set, so the colon/newline is skipped
			STA bufpt			; update pointer
			BCC cli_loop		; MSB OK means try another
				INC bufpt+1			; otherwise wrap!
			_BRA cli_loop		; and try another (BCS or BNE might do as well)
cmd_term:
		BEQ main_loop		; no more on buffer, restore direct mode, otherwise has garbage!
bad_cmd:
	LDA #>err_bad		; address of error message
	LDY #<err_bad
d_error:
	JSR prnStr			; display error
	_BRA main_loop		; continue

not_mcmd:
; ** try to assemble the opcode! **
	_STZA count			; reset opcode counter (aka value[2])
	_STZA bytes			; eeeeeeeeek
	LDY #<da_oclist-1	; get list address, notice trick
	LDA #>da_oclist-1
	STY scan			; store pointer from Y eeeeeeeeeeek
	STA scan+1
sc_in:
		JSR getListChar		; will return NEXT c in A and x as carry bit, notice trick above for first time!
		CMP #'%'			; relative addressing?
		BNE sc_nrel
; try to get a relative operand
			BEQ sc_sbyt			; *** currently no different from single-byte ***
sc_nrel:
		CMP #'@'			; single byte operand?
		BNE sc_nsbyt
; try to get a single byte operand
sc_sbyt:					; *** temporary label ***
			DEC cursor			; eeeeeeek but this seems ok
			JSR fetch_byte		; currently it is a single byte...
				BCS no_match		; could not get operand
			LDX bytes			; check whether the first operand!
			BNE sbyt_2nd		; otherwise do not overwrite previous
				STA oper			; store value to be poked
sbyt_2nd:
			STA oper+1		; store here too, for BBS/BBR eeeeeek
; should try a SECOND one which must FAIL, otherwise get back just in case comes later
			JSR fetch_byte		; this one should NOT succeed
			BCS sbyt_ok			; OK if no other number found
				JSR backChar		; otherwise is an error, forget previous byte!!!
				JSR backChar
				BCC no_match		; reject
sbyt_ok:
			JSR backChar		; reject tested char! eeeeeeeek
			INC bytes			; one operand was detected
			_BRA sc_adv			; continue decoding
sc_nsbyt:
		CMP #'&'			; word-sized operand? hope it is OK
		BNE sc_nwrd
; try to get a word-sized operand
			DEC cursor			; eeeeeeeek but seems OK
			JSR fetch_word		; currently it is a single byte...
				BCS no_match		; not if no number found?
			LDY value				; get computed value
			LDA value+1
			STY oper			; store in safer place, endianness was ok
			STA oper+1
			INC bytes			; two operands were detected
			INC bytes
			_BRA sc_adv			; continue decoding
sc_nwrd:

; regular char in list, compare with input
		STA temp			; store list contents eeeeeeeek!
		DEC cursor			; let us see what we have, seems ok
		JSR getNextChar		; reload char from buffer eeeeeeeek^2
		CMP temp			; list coincides with input?
		BEQ sc_adv			; if so, continue scanning input
			LDY #$FF			; otherwise seek end of current opcode
sc_seek:
				INY					; advance in list (optimised)
				LDA (scan), Y		; look at opcode list
				BPL sc_seek			; until the end
			TYA					; get offset
			CLC					; stay at the end
			ADC scan			; add to current pointer
			STA scan			; update LSB
			BCC no_match		; and try another opcode
				INC scan+1			; in case of page crossing
no_match:
			_STZA cursor		; back to beginning of instruction
			_STZA bytes			; also no operands detected! eeeeek
			INC count			; try next opcode
			BNE sc_in			; there is another opcode to try
		_STZA bytes			; otherwise nothing to poke, really needed?
		JMP bad_cmd			; generic error
sc_adv:
		JSR getNextChar		; get another valid char, in case it has ended
		TAX					; check A flags... and keep c!
		BNE sc_nterm		; if end of buffer, sentence ends too
			SEC					; just like a colon, instruction ended
sc_nterm:
		_LDAY(scan)			; what it being pointed in list?
		BPL sc_rem			; opcode not complete
			BCS valid_oc		; both opcode and instruction ended
			BCC no_match		; only opcode complete, keep trying! eeeeek
sc_rem:
		BCS no_match		; instruction is shorter, usually non-indexed indirect eeeeeeek
		JMP sc_in			; neither opcode nor instruction ended, continue matching
valid_oc:
; opcode successfully recognised, let us poke it in memory
		LDY bytes			; set pointer to last argument
		BEQ poke_opc		; no operands
poke_loop:
			LDA oper-1, Y		; get argument, note trick, ***NOT 816-savvy***
			STA (ptr), Y		; store in RAM
			DEY					; next byte
			BNE poke_loop		; could start on zero
poke_opc:
		LDA count			; matching opcode as computed
		STA (ptr), Y		; poke it, Y guaranteed to be zero here
; now it is time to print the opcode and hex dump! make sures 'bytes' is preserved!!!

; advance pointer and continue execution
		LDA bytes			; add number of operands...
		SEC					; ...plus opcode itself... (will be included? CLC then)
		ADC ptr				; ...to current address
		STA ptr				; update LSB
		BCC main_nw			; check for wrap
			INC ptr+1			; in case of page crossing
main_nw:
		TXA					; retrieve c, what was NEXT in buffer eeeeeeek^3
		BNE main_nnul		; termination will return to exterior main loop
			JMP main_loop		; and continue forever
main_nnul:
		JMP cli_loop		; otherwise continue parsing line
; *** this is the end of main loop ***

; *** call command routine ***
call_mcmd:
	_JMPX(cmd_ptr)		; indexed jump macro

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
	JSR fetch_word		; get operand address
; now ignoring operand errors!
; restore stack pointer... and forget return address (will jump anyway)
	LDX _sp				; get stored value
	TXS					; set new pointer...
; SP restored
	JSR do_call			; set regs and jump!
; ** should record actual registers here **
	STA _a
	STX _x
	STY _y
	PHP					; get current status
	PLA					; A was already saved
	STA _psr
	JMP get_sp			; hopefully context is OK

; ** .J = jump to an address **
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
	JMP (value)			; go! might return somewhere else

; ** .D = disassemble 'u' lines **
disassemble:
	JSR fetch_word		; get address
	LDY value			; save value elsewhere
	LDA value+1
	STY oper
	STA oper+1
	LDX lines			; get counter
das_l:
		_PHX				; save counters
; time to show the opcode and trailing spaces until 20 chars
		JSR disOpcode		; dissassemble one opcode @oper (will print it)
		_PLX				; retrieve counter
		DEX					; one line less
		BNE das_l			; continue until done
	RTS

; disassemble one opcode and print it
disOpcode:
	_LDAY(oper)			; check pointed opcode
	STA count			; keep for comparisons
	LDY #<da_oclist		; get address of opcode list
	LDA #>da_oclist
	_STZX scan			; indirect-indexed pointer, NMOS use X eeeeeeek
	STA scan+1
	LDX #0				; counter of skipped opcodes
do_chkopc:
		CPX count			; check if desired opcode already pointed
			BEQ do_found		; no more to skip
do_skip:
			LDA (scan), Y		; get char in list
			BMI do_other		; found end-of-opcode mark (bit 7)
			INY
			BNE do_skip			; next char in list if not crossed
				INC scan+1			; otherwise correct MSB
			_BRA do_skip
do_other:
		INY					; needs to point to actual opcode, not previous end eeeeeek!
		BNE do_set			; if not crossed
			INC scan+1			; otherwise correct MSB
do_set:
		INX					; yet another opcode skipped
		BNE do_chkopc		; until list is done ***should not arrive here***
do_found:
	STY scan			; restore pointer
; this is a fully defined opcode, when symbolic assembler is available!
	JMP prnOpcode		; show all and return

; decode opcode and print hex dump
prnOpcode:
; first goes the current address in label style
	LDA #'_'			; make it self-hosting
	JSR prnChar
	LDA oper+1			; address MSB *** this may go into printOpcode
	JSR prnHex			; print it
	LDA oper			; same for LSB
	JSR prnHex
	LDA #$3A			; code of the colon character
	JSR prnChar
	LDA #' '			; leading space, might use string
	JSR prnChar
; then extract the opcode string from scan
	LDY #0				; scan increase, temporarily stored in temp
	STY bytes			; number of bytes to be dumped (-1)
	STY count			; printed chars for proper formatting
po_loop:
		LDA (scan), Y		; get char in opcode list
		STY temp			; keep index as will be destroyed
		AND #$7F			; filter out possible end mark
		CMP #'%'			; relative addressing
		BNE po_nrel			; currently the same as single byte!
; put here specific code for relative arguments!
;			_BRA po_sbyte		; *** placeholder
			LDA #'$'			; hex radix
			JSR prnChar
			LDY bytes			; retrieve instruction index
			INY					; point to operand!
; should I call fetch_word???
po_nrel:
		CMP #'@'			; single byte operand
		BNE po_nbyt			; otherwise check word-sized operand
; could check also for undefined references!!!
po_sbyte:
			LDA #'$'			; hex radix
			JSR prnChar
			LDY bytes			; retrieve instruction index
			INY					; point to operand!
			LDA (oper), Y		; get whatever byte
			STY bytes			; correct index
			JSR prnHex			; show in hex
			LDX #3				; number of chars to add
			_BRA po_done		; update count and continue
po_nbyt:
		CMP #'&'			; word operand
		BNE po_nwd			; otherwise is normal char
; could check also for undefined references!!!
			LDA #'$'			; hex radix
			JSR prnChar
			LDY bytes			; retrieve instruction index
			INY					; point to operand MSB!
			INY
			STY bytes			; save here as will back off for LSB
			LDA (oper), Y		; get whatever byte
			JSR prnHex			; show in hex
			LDY bytes			; retrieve final index
			DEY					; back to LSB
			LDA (oper), Y		; get whatever byte
			JSR prnHex			; show in hex
			LDX #5				; five more chars
			_BRA po_done		; update count and continue
po_nwd:
		JSR prnChar			; just print it
		INC count			; yet another char
po_done:
		TXA					; increase of number of chars
		CLC
		ADC count			; add to previous value
		STA count			; update value
		LDY temp			; get scan index
		LDA (scan), Y		; get current char again
			BMI po_end			; opcode ended, no more to show
		INY					; go for next char otherwise
		BNE po_loop			; will work as no opcode string near 256 bytes long!
po_end:
; add spaces until 20 chars!
		LDA #13				; number of chars after the initial 7
		CMP count			; already done?
	BCC po_dump			; go for dump then, even if over
		LDA #' '			; otherwise print a space
		JSR prnChar
		INC count			; eeeeeeeeeeeek
		BNE po_end			; until complete, again no need for BRA
; print hex dump as a comment!
po_dump:
	LDA #';'			; semicolon as comment introducer
	JSR prnChar
	LDY #0				; reset index
	STY temp			; save index (no longer scan)
po_dbyt:
		LDA #' '			; leading space
		JSR prnChar
		LDY temp			; retrieve index
		LDA (oper), Y		; get current byte in instruction
		JSR prnHex			; show as hex
		INC temp			; next
		LDX bytes			; get limit (-1)
		INX					; correct for post-increased
		CPX temp			; compare current count
		BNE po_dbyt			; loop until done
; skip all bytes and point to next opcode
	LDA oper			; address LSB
	SEC					; skip current opcode...
	ADC bytes			; ...plus number of operands
	STA oper
	BCC po_nowr			; in case of page crossing
		INC oper+1
po_nowr:
	LDA #CR				; final newline
	JMP prnChar			; print it and return

; ** .E = examine 'u' lines of memory **
examine:
	JSR fetch_word		; get address
	LDY value			; save value elsewhere
	LDA value+1
	STY oper
	STA oper+1
	LDX lines			; get counter
ex_l:
		_PHX				; save counters
		LDA oper+1			; address MSB
		JSR prnHex			; print it
		LDA oper			; same for LSB
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
			LDA (oper), Y		; get byte
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
			LDA (oper), Y		; get byte
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
		LDA oper			; get pointer LSB
		CLC
		ADC #PERLINE		; add shown bytes (8 if not 20-char)
		STA oper			; update pointer
		BCC ex_npb			; skip if within same page
			INC oper+1			; next page
ex_npb:
		_PLX				; retrieve counter!!!!
		DEX					; one line less
		BNE ex_l			; continue until done
	RTS

; ** .G = set stack pointer **
set_SP:
	JSR fetch_byte		; get operand in A
	STA _sp				; set stack pointer
	RTS

; ** .H = show commands **
help:
	LDA #>help_str		; help string
	LDY #<help_str
	JMP prnStr			; print it, and return to main loop

; ** .I = show symbol table ***
symbol_table:
;***********placeholder*************
	LDA #'?'
	STA io_c
	LDY iodev
	_KERNEL(COUT)
	RTS		; ***** TO DO ****** TO DO ******

; ** .K = keep (save) **
; ### highly system dependent ###
save_bytes:
;***********placeholder*************
	LDA #'!'
	STA io_c
	LDY iodev
	_KERNEL(COUT)
	RTS		; ***** TO DO ****** TO DO ******

; ** .L = load **
; ### highly system dependent ###
load_bytes:
;***********placeholder*************
	LDA #'@'
	STA io_c
	LDY iodev
	_KERNEL(COUT)
	RTS		; ***** TO DO ****** TO DO ******

; ** .M = move (copy) 'n' bytes of memory **
move:
; preliminary version goes forward only, modifies ptr.MSB and X!

	JSR fetch_word		; get operand word
	LDY #0				; reset offset
	LDX siz+1			; check n MSB
		BEQ mv_l			; go to second stage if zero
mv_hl:
		LDA (ptr), Y		; get source byte
		STA (value), Y		; copy at destination
		INY					; next byte
		BNE mv_hl			; until a page is done
	INC ptr+1			; next page
	INC value+1
	DEX					; one less to go
		BNE mv_hl			; stay in first stage until the last page
	LDA siz				; check LSB
		BEQ mv_end			; nothing to copy!
mv_l:
		LDA (ptr), Y		; get source byte
		STA (value), Y		; copy at destination
		INY					; next byte
		CPY siz				; compare with LSB
		BNE mv_l			; continue until done
mv_end:
	RTS

; ** .N = set 'n' value **
set_count:
	JSR fetch_word		; get operand word
	LDY value			; copy LSB
	LDA value+1			; and MSB
	STY siz				; into destination variable
	STA siz+1
	RTS

; ** .O = set origin **
origin:
	JSR fetch_word		; get operand word
	LDY value			; copy LSB
	LDA value+1			; and MSB
	STY ptr				; into destination variable
	STA ptr+1
	RTS

; ** .P = set status register **
set_PSR:
	JSR fetch_byte		; get operand in A
	STA _psr			; set status
	RTS

; ** .Q = standard quit **
quit:
; will not check any pending issues
	PLA					; discard main loop return address
	PLA
	_EXIT_OK			; exit to minimOS, proper error code

; ** .S = store raw string **
store_str:
	LDY cursor			; allows NMOS macro!
sst_loop:
		INY					; skip the S and increase
		LDA (bufpt), Y		; get raw character
		_STAX(ptr)			; store in place, respect Y but now X is OK to use in NMOS
#ifdef	NMOS
		TAY					; update flags altered by macro!
#endif
			BEQ sstr_end		; until terminator, will be stored anyway
		CMP #CR				; newline also accepted, just in case
			BEQ sstr_cr			; terminate and exit
		CMP #COLON			; that marks end of sentence, thus not accepted in string!
			BEQ sstr_cr
		CMP #';'			; comments neither included
			BEQ sstr_com		; skip until colon, newline or nul
		INC ptr				; advance destination
		BNE sst_loop		; boundary not crossed
	INC ptr+1			; next page otherwise
	_BRA sst_loop		; continue, might use BNE
sstr_com:
	LDA #0				; no STZ indirect
	_STAX(ptr)			; terminate string in memory Eeeeeeeeek
sstr_cloop:
		INY					; advance
		LDA (bufpt), Y		; check whatever
			BEQ sstr_end		; terminator ends
		CMP #CR				; newline ends too
			BEQ sstr_end
		CMP #COLON			; and also does colon
			BEQ sstr_end
		BNE sstr_cloop		; otherwise continue discarding, no need for BRA
sstr_cr:
	LDA #0				; no STZ indirect
	_STAX(ptr)			; terminate string in memory Eeeeeeeeek
sstr_end:
	DEY					; will call getNextChar afterwards eeeeeeeeek
	STY cursor			; update optimised index!
	RTS

; ** .T = assemble from source **
asm_source:
	PLA					; discard return address as will jump inside cli_loop
	PLA
	JSR fetch_word		; get desired address
	LDY value			; fetch result
	LDA value+1
	STY bufpt			; this will be new buffer
	STA bufpt+1
	JMP cli_loop		; execute as commands!

; ** .U = set 'u' number of lines/instructions **
set_lines:
	JSR fetch_byte		; get operand in A
	STA lines			; set number of lines
	RTS

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
	STX value			; temp counter
	LDA _psr			; copy original value
	STA value+1			; temp storage
vr_sb:
		ASL value+1			; get highest bit
		LDA #' '			; default is off (space)
		BCC vr_off			; was off
			_INC				; otherwise turns into '!'
vr_off:
		JSR prnChar			; prints bit
		DEC value			; one less
		BNE vr_sb			; until done
	LDA #CR				; print newline
	JMP prnChar			; will return

; ** .W = store word **
store_word:
	JSR fetch_word		; get operand word
	LDA value			; get LSB
	_STAY(ptr)			; store in memory
	INC ptr				; next byte
	BNE sw_nw			; no wrap
		INC ptr+1			; otherwise increment pointer MSB
sw_nw:
	LDA value+1			; same for MSB
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

; ** .F = force cold boot
force:
	LDY #PW_COLD		; cold boot request ** minimOS specific **
	_BRA fw_shut		; call firmware

; ** .R = warm boot **
reboot:
	LDY #PW_WARM		; warm boot request ** minimOS specific **
	_BRA fw_shut		; call firmware

; ** .Z = shutdown **
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

; * convert two hex ciphers into byte@value, A is current char, Y is cursor from NEW buffer *
hex2byte:
	LDX #0				; reset loop counter
	STX value			; also reset value
h2b_l:
		SEC					; prepare
		SBC #'0'			; convert to value
			BCC h2b_err			; below number!
		CMP #10				; already OK?
		BCC h2b_num			; do not shift letter value
			CMP #23				; should be a valid hex
				BCS h2b_err			; not!
			SBC #6				; convert from hex (had CLC before!)
h2b_num:
		ASL value			; older value times 16
		ASL value
		ASL value
		ASL value
		ORA value			; add computed nibble
		STA value			; and store full byte
		INX					; loop counter
		CPX #2				; two ciphers per byte
			BEQ h2b_end			; all done
		JSR gnc_do			; go for next hex cipher *** THIS IS OUTSIDE THE LIB ***
		_BRA h2b_l			; process it
h2b_end:
	_EXIT_OK			; clear carry, value is valid!
h2b_err:
	DEX					; at least one cipher processed?
	BMI h2b_exit		; no need to correct
		JSR backChar		; will try to reprocess former char
h2b_exit:
	SEC					; indicate error
	RTS

; * print a byte in A as two hex ciphers *
; uses value.w
prnHex:
	JSR ph_conv			; first get the ciphers done
	LDA value			; get cipher for MSB
	JSR prnChar			; print it!
	LDA value+1			; same for LSB
	JMP prnChar			; will return
ph_conv:
	STA value+1			; keep for later
	AND #$F0			; mask for MSB
	LSR					; convert to value
	LSR
	LSR
	LSR
	LDX #0				; this is first value
	JSR ph_b2a			; convert this cipher
	LDA value+1			; get again
	AND #$0F			; mask for LSB
	INX					; this will be second cipher
ph_b2a:
	CMP #10				; will be letter?
	BCC ph_n			; numbers do not need this
		ADC #'A'-'9'-2		; turn into letter, C was set
ph_n:
	ADC #'0'			; turn into ASCII
	STA value, X		; this became 816-savvy!
	RTS

; ** end of inline library **

; * get input line from device at fixed-address buffer *
; minimOS should have one of these in API...
; new movable buffer!
getLine:
	_STZA cursor			; reset variable
gl_l:
		LDY iodev			; use device
		_KERNEL(CIN)		; get one character #####
			BCS gl_l			; wait for something
		LDA io_c			; get received
		LDY cursor			; retrieve index
		CMP #CR				; hit CR?
			BEQ gl_cr			; all done then
		CMP #BS				; is it backspace?
		BNE gl_nbs			; delete then
			CPY #0				; already 0?
				BEQ gl_l			; ignore if so
			DEC cursor			; reduce index
			_BRA gl_echo		; resume operation
gl_nbs:
		CPY #BUFSIZ-1		; overflow?
			BCS gl_l			; ignore if so
		STA (bufpt), Y		; store into buffer
		INC	cursor			; update index
gl_echo:
		JSR prnChar			; echo!
		_BRA gl_l			; and continue
gl_cr:
	JSR prnChar			; newline
	LDY cursor			; retrieve cursor!!!!!
	LDA #0				; sorry, no STZ for indirect-indexed!
	STA (bufpt), Y		; terminate string
	RTS					; and all done!

; * get clean character from NEW buffer in A, (return) offset at Y *
getNextChar:
	LDY cursor			; retrieve index
gnc_do:
	INY					; advance!
	LDA (bufpt), Y		; get raw character
		BEQ gn_ok			; go away if ended
	CMP #' '			; white space?
		BEQ gnc_do			; skip it!
	CMP #TAB			; tabulations will be skipped too
		BEQ gnc_do
	CMP #'$'			; ignored radix?
		BEQ gnc_do			; skip it!
	CMP #COLON			; end of sentence?
		BEQ gn_exit			; command is done but not the whole buffer!
	CMP #CR				; newline?
		BEQ gn_exit			; go for next too
	CMP #';'			; is it a comment?
		BEQ gn_fin			; forget until the end
	CMP #'_'			; is it a label? Not yet supported!!!
		BEQ gn_fin			; treat it as a comment!
gnc_low:
	CMP #'a'			; not lowercase?
		BCC gn_ok			; all done!
	CMP #'z'+1			; still within lowercase?
		BCS gn_ok			; otherwise do not correct!
	AND #%11011111		; remove bit 5 to uppercase
gn_ok:
	CLC					; new, will signal buffer is done
	BCC gn_end			; save and exit, no need for BRA
gn_fin:
		INY				; skip another character in comment
		LDA (bufpt), Y	; get pointed char
			BEQ gn_ok		; completely finish if already at terminator
		CMP #COLON		; colon ends just this sentence
			BEQ gn_exit
		CMP #CR			; newline ends too
			BNE gn_fin
gn_exit:
	SEC					; new, indicates command has ended but not the last in input buffer
gn_end:
	STY cursor			; worth updating here!
	RTS

; * back off one character, skipping whitespace, use instead of DEC cursor! *
backChar:
	LDY cursor			; get current position
bc_loop:
		DEY					; back once
		LDA (bufpt), Y		; check what is pointed
		CMP #' '			; blank?
			BEQ bc_loop			; once more
		CMP #TAB			; tabulation?
			BEQ bc_loop			; ignore
		CMP #'$'			; ignored radix?
			BEQ bc_loop			; also ignore
	STY cursor				; otherwise we are done
	RTS

; * get clean NEXT character from opcode list, set Carry if last one! *
getListChar:
		INC scan			; try next
		BNE glc_do			; if did not wrap
			INC scan+1			; otherwise carry on
glc_do:
		_LDAY(scan)			; get current
		CMP #' '			; is it blank? will never end an opcode, though
		BEQ getListChar		; nothing interesting yet
	_LDAY(scan)			; recheck bit 7
	CLC					; normally not the end
	BPL glc_end			; it was not
		SEC					; otherwise do x=128
glc_end:
	AND #$7F			; most convenient!
	RTS

checkEnd:
	CLC					; prepare!
	LDY cursor			; otherwise set offset
	LDA (bufpt), Y		; ...and check buffer contents
		BEQ cend_ok			; end of buffer means it is OK to finish opcode
	CMP #COLON			; end of sentence
		BEQ cend_ok			; also OK
	SEC					; otherwise set carry
cend_ok:
	RTS

; * fetch one byte from buffer, value in A and @value *
fetch_byte:
	JSR getNextChar		; go to operand
	JSR hex2byte		; convert value
	LDA value			; converted byte
fetch_abort:
	RTS

; * fetch two bytes from hex input buffer, value @value.w *
fetch_word:
	JSR fetch_byte		; get operand in A
		BCS fetch_abort		; new, do not keep trying if error, not sure if needed
	STA value+1			; leave room for next
	JSR gnc_do			; get next char!!!
	JSR hex2byte		; get second byte, value is little-endian now
		BCC fetch_abort		; actually OK!!!
	JSR backChar		; should discard previous byte!
	JSR backChar
	RTS

; * abort command execution and return stack cleanup (remove X bytes) * NOT CURRENTLY USED
;abort:
;#ifdef	SAFE
;	TXA					; nothing to discard?
;	BNE do_abort		; otherwise proceed normally
;		RTS					; if not, just return quietly
;#endif
;do_abort:	
;		PLA					; discard one byte
;		DEX					; decrease counter
;		BNE do_abort		; until all done
;	JMP bad_cmd			; and show generic error

; *** pointers to command routines ***
cmd_ptr:
	.word	set_A			; .A
	.word	store_byte		; .B
	.word	call_address	; .C
	.word	disassemble		; .D
	.word	examine			; .E
	.word	force			; .F
	.word	set_SP			; .G
	.word	help			; .H
	.word	symbol_table	; .I
	.word	jump_address	; .J
	.word	save_bytes		; .K
	.word	load_bytes		; .L
	.word	move			; .M
	.word	set_count		; .N
	.word	origin			; .O
	.word	set_PSR			; .P
	.word	quit			; .Q
	.word	reboot			; .R
	.word	store_str		; .S
	.word	asm_source		; .T
	.word	set_lines		; .U
	.word	view_regs		; .V
	.word	store_word		; .W
	.word	set_X			; .X
	.word	set_Y			; .Y
	.word	poweroff		; .Z

; *** strings and other data ***
title:
	.asc	"miniMoDA", 0

splash:
	.asc	"minimOS 0.5 monitor/debugger/assembler", CR
	.asc	" (c) 2016 Carlos J. Santisteban", CR, 0


err_mmod:
	.asc	"***Missing module***", CR, 0

err_bad:
	.asc	"*** Bad command ***", CR, 0

opc_error:
	.asc	"*** Bad opcode ***", CR, 0

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
	.asc	"Da =disass. 'u' opc.", CR
	.asc	"Ea = dump 'u' lines", CR
	.asc	"F = cold boot", CR
	.asc	"Gd = set SP reg.", CR
	.asc	"H = show this list", CR
	.asc	"Ja = jump", CR
	.asc	"K = save 'n' bytes", CR
	.asc	"L = load up to 'n'", CR
	.asc	"Ma =copy n byt. to a", CR
	.asc	"Na = set 'n' bytes", CR
	.asc	"Oa = set address", CR
	.asc	"Pd = set Status reg.", CR
	.asc	"Q = quit", CR
	.asc	"R = reboot", CR
	.asc	"Ss = put raw string", CR
	.asc	"Ta = assemble source", CR
	.asc	"Ud = set 'u' lines", CR
	.asc	"V = view registers", CR
	.asc	"Wa = store word", CR
	.asc	"Xd = set X reg.", CR
	.asc	"Yd = set Y reg.", CR
	.asc	"Z = poweroff", CR
#endif
	.byt	0

; include opcode list
#include "shell/data/opcodes.s"
