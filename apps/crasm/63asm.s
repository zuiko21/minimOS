; 6800/6801/6301 cross-assembler for minimOS 6502
; based on miniMoDA engine!
; v0.5.2b1 like 0.5.1 but 65816-savvy
; last modified 20180829-2134
; (c) 2017-2018 Carlos J. Santisteban

#include "../../OS/usual.h"

.(
; *** uncomment for narrow (20-char) displays ***
;#define	NARROW	_NARROW

; *** constant definitions ***
#define	BUFSIZ		80

; bytes per line in dumps 4 or 8/16
#ifdef	NARROW
#define		PERLINE		4
#else
#define		PERLINE		8
#endif

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
a68_head:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD
; *** filename and optional comment ***
title:
	.asc	"68asm", 0	; file name (mandatory)
	.asc	"6800/6801/6301 cross-assembler for 65xx, v0.5.2", 0	; comment

; advance to end of header
	.dsb	a68_head + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$7200		; time, 14.16
	.word	$4AAB		; date, 2017/5/11

	a68siz	=	a68_end - a68_head - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	a68siz		; filesize
	.word	0			; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	ptr		= uz		; current address pointer, would be filled by NMI/BRK handler
	siz		= ptr+2		; number of bytes to copy or transfer ('n')
	lines	= siz+2		; lines to dump ('u')
	cursor	= lines+1	; storage for cursor offset, now on Y
	buffer	= cursor+1	; storage for direct input line (BUFSIZ chars)
	value	= buffer+BUFSIZ	; fetched values
	oper	= value+2	; operand storage
	temp	= oper+2	; temporary storage, also for indexes
	scan	= temp+1	; pointer to opcode list, size is architecture dependent!
	bufpt	= scan+2	; NEW pointer to variable buffer, regular sizes
	count	= bufpt+2	; char count for screen formatting, also opcode count
	bytes	= count+1	; bytes per instruction

	__last	= bytes+1	; ##### just for easier size check #####

; *** initialise the assembler/monitor ***

; ##### minimOS specific stuff #####
; standard minimOS initialisation
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_da			; enough space
	BEQ go_da			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_da:
#endif
	STA z_used			; set needed ZP space as required by minimOS
; will not ask for a window as takes standard device
; ##### end of minimOS specific stuff #####

; splash message just shown once
	LDA #>splash		; address of splash message
	LDY #<splash
	JSR $FFFF &  prnStr			; print the string!

; preset ptr to a safe area
	LDX #>user_ram		; beginning of available ram, as defined... in rom.s
	LDY #<user_ram		; LSB misaligned?
	BEQ ptr_init		; nothing to align
		INX					; otherwise start at next page
ptr_init:
	STX ptr+1			; set MSB
	_STZA ptr			; page aligned
; global variables
	LDA #4				; standard number of lines
	STA lines			; set variable
	STA siz				; also default transfer size
	_STZA siz+1			; clear copy/transfer size MSB
; *** begin things ***
main_loop:
		_STZA cursor		; eeeeeeeeeek... but really needed?
; *** NEW variable buffer setting ***
		LDY #<buffer		; get LSB that is full address in zeropage
		STY bufpt			; set new movable pointer
		_STZA bufpt+1
; put current address before prompt
		LDA ptr+1			; MSB goes first
		JSR $FFFF &  prnHex			; print it
		LDA ptr				; same for LSB
		JSR $FFFF &  prnHex
		LDA #'>'			; prompt character
		JSR $FFFF &  prnChar			; print it
		JSR $FFFF &  getLine			; input a line
; execute single command (or assemble opcode) from buffer
cli_loop:
		LDY #$FF			; getNextChar will advance it to zero!
		JSR $FFFF &  gnc_do			; get first character on string, without the variable
		TAX					; set status for A
			BEQ main_loop		; ignore blank lines!
		CMP #COLON			; end of instruction?
			BEQ cli_chk			; advance to next valid char
		CMP #CR				; ** newline is the same as colon **
			BEQ cli_chk
		CMP #'.'			; command introducer (not used nor accepted if monitor only)
			BNE not_mcmd		; not a monitor command
		JSR $FFFF &  gnc_do			; get into command byte otherwise
		CMP #'W'+1			; past last command?
			BCS bad_cmd			; unrecognised
		SBC #'?'-1			; first available command (had borrow)
			BCC bad_cmd			; cannot be lower
		ASL					; times two to make it index
		TAX					; use as index
		JSR $FFFF &  call_mcmd		; call monitor command
		JSR $FFFF &  getNextChar		; should be done but check whether in direct mode
		BCC cmd_term		; no more commands in line (or directly to main loop?)
cli_chk:
			TYA					; otherwise advance pointer
			SEC					; set carry in case the BCC is skipped! eeeek
			ADC bufpt			; carry was set, so the colon/newline is skipped
			STA bufpt			; update pointer
			BCC cli_loop		; MSB OK means try another right now
				INC bufpt+1			; otherwise wrap!
			BCS cli_loop		; and try another (instead of BRA)
cmd_term:
		BEQ main_loop		; no more on buffer, restore direct mode
	BNE bad_cmd			; otherwise has garbage! No need for BRA

bad_opr:				; *** this entry point has to discard return address as will be issued as command ***
		PLA
		PLA
bad_cmd:
	LDA #>err_bad		; address of error message
	LDY #<err_bad
d_error:
	JSR $FFFF &  prnStr			; display error
	_BRA main_loop		; restore

; some room here for the overflow error message!
overflow:
	LDA #>err_ovf		; address of overflow message
	LDY #<err_ovf
	_BRA d_error		; display and restore

not_mcmd:
; ** try to assemble the opcode! **
	_STZA count			; reset opcode counter
	_STZA bytes			; eeeeeeeeek
	LDY #<da_oclist-1	; get list address, notice trick
	LDA #>da_oclist-1
	STY scan			; store pointer from Y eeeeeeeeeeek
	STA scan+1
; proceed normally, but 65816 must use long addressing for scan pointer
sc_in:
		DEC cursor			; every single option will do it anyway
		JSR $FFFF &  getListChar		; will return NEXT c in A and x as carry bit, notice trick above for first time!
; ...but C will be lost upon further comparisons!
		CMP #'%'			; relative addressing?
		BNE sc_nrel
; *** try to get a relative operand ***
			JSR $FFFF &  fetch_word		; will pick up a couple of bytes
			BCC srel_ok			; no errors, go translate into relative offset 
				JMP $FFFF &  no_match		; no address, not OK
srel_ok:
			LDA #1				; standard branch operands
; --- at this point, (ptr)+A+1 is the address of next instruction
; --- should offset be zero, the branch will just arrive there
; --- (value) holds the desired address
; --- (value) minus that previously computed address is the proper offset
; --- offset MUST fit in a signed byte! overflow otherwise
; --- alternatively, bad_opc(ptr)+A - (value), then EOR #$FF
; --- how to check bounds then? same sign on MSB & LSB!
; --- but MSB can ONLY be 0 or $FF!
			CLC					; prepare
			ADC ptr				; A = ptr + Y
			SEC					; now for the subtraction
			SBC value			; one's complement of result
			EOR #$FF			; the actual offset!
; will poke offset first, then check bounds
			STA oper			; standard storage
; check whether within branching range
; first compute MSB (no need to complement)
			LDA ptr+1			; get original position
			SBC value+1			; subtract MSB
			BEQ srel_bak		; if zero, was backwards branch, no other positive accepted!
				CMP #$FF			; otherwise, only $FF valid for forward branch
				BEQ srel_fwd		; possibly valid forward branch
					JMP $FFFF &  overflow		; overflow otherwise
srel_fwd:
				LDA oper			; check stored offset
				BPL srel_done		; positive is OK
					JMP $FFFF &  overflow		; slight overflow otherwise
srel_bak:
			LDA oper			; check stored offset
			BMI srel_done		; this has to be negative
				JMP $FFFF &  overflow		; slight overflow otherwise
srel_done:
			INC bytes			; one operand was really detected
			BNE sc_adv			; continue decoding, no need for BRA
sc_nrel:
		CMP #'@'			; single byte operand?
		BNE sc_nsbyt
; *** try to get a single byte operand ***
; * please note that Hitachi 6301/6303 may use double operand opcodes *
			JSR $FFFF &  fetch_byte		; currently it is a single byte...
				BCS sc_skip			; could not get operand eeeeeeeek
			LDX bytes			; *** operands detected this far *** Hitachi only
			STA oper, X			; will poke it where appropriated! *** indexed for Hitachi
; no longer tries a SECOND one which must FAIL
			INC bytes			; one operand was detected
			BNE sc_adv			; continue decoding, no need for BRA
sc_nsbyt:
		CMP #'&'			; word-sized operand? hope it is OK
		BNE sc_nwrd
; try to get a word-sized operand
			JSR $FFFF &  fetch_word		; will pick up a couple of bytes
				BCS sc_skip			; not if no number found eeeeeeeek
			LDY value+1			; get computed value, LSB already in A
			STY oper			; store in safer place ***** endianness corrected *****
			STA oper+1
			INC bytes			; two operands were detected
			INC bytes
			BNE sc_adv			; continue decoding, no need for BRA
sc_nwrd:
; regular char in list, compare with input
		STA temp			; store list contents eeeeeeeek!
		JSR $FFFF &  getNextChar		; reload char from buffer eeeeeeeek^2
		CMP temp			; list coincides with input?
		BEQ sc_adv			; if so, continue scanning input
sc_skip:
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
			BEQ bad_opc			; no more to try!
				JMP $FFFF &  sc_in			; there is another opcode to try
bad_opc:
			LDA #>err_opc		; address of wrong opcode message
			LDY #<err_opc
			JMP $FFFF &  d_error			; display and restore
sc_adv:
		JSR $FFFF &  getNextChar		; get another valid char, in case it has ended
		TAX					; check A flags... and keep c!
		BNE sc_nterm		; if end of buffer, sentence ends too
			SEC					; just like a colon, instruction ended
sc_nterm:
		_LDAY(scan)			; what is being pointed in list?
		BPL sc_rem			; opcode not complete
			BCS valid_oc		; both opcode and instruction ended
			BCC no_match		; only opcode complete, keep trying! eeeeek
sc_rem:
		BCS sc_skip			; instruction is shorter, usually non-indexed indirect eeeeeeek^3
		JMP $FFFF &  sc_in			; neither opcode nor instruction ended, continue matching
valid_oc:
; opcode successfully recognised, let us poke it in memory
		_PHX				; ***** eeeeeek *****
		LDY bytes			; set pointer to last argument
		LDX bytes			; ***** this is done for 65816 savvyness *****
		BEQ poke_opc		; no operands
poke_loop:
			LDA oper-1, X		; ***** endianness previously corrected, 816-savvy ***** eeeeeek
			STA (ptr), Y		; store in RAM
			DEX					; ***** independent index is 816-savvy *****
			DEY					; next byte
			BNE poke_loop		; could start on zero
poke_opc:
		_PLX				; ***** restore saved value *****
		LDA count			; matching opcode as computed
		STA (ptr), Y		; poke it, Y guaranteed to be zero here
; now it is time to print the opcode and hex dump! make sures 'bytes' is preserved!!!
; **** to do above ****
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
			JMP $FFFF &  main_loop		; and continue forever
main_nnul:
		LDY cursor			; eeeeeeeeek
		JMP $FFFF &  cli_chk			; otherwise continue parsing line eeeeeeeeeek
; *** this is the end of main loop ***

; *** call command routine ***
call_mcmd:
	_JMPX(cmd_ptr)		; indexed jump macro, bank 0!

; ****************************************************
; *** command routines, named as per pointer table ***
; ****************************************************

; ** .? = show commands **
help:
	LDA #>help_str		; help string
	LDY #<help_str
	JMP $FFFF &  prnStr			; print it, and return to main loop


; ** .B = store byte **
store_byte:
	JSR $FFFF &  fetch_byte		; get operand in A
	_STAY(ptr)			; set byte in memory
	INC ptr				; advance pointer
	BNE sb_end			; all done if no wrap
		INC ptr+1			; increase MSB otherwise
sb_end:
	RTS


; ** .D = disassemble 'u' lines **
disassemble:
	JSR $FFFF &  fetch_value		; get address
; ignoring operand error...
	LDY value			; save value elsewhere
	LDA value+1
	STY oper
	STA oper+1
	LDX lines			; get counter
das_l:
		_PHX				; save counters
; time to show the opcode and trailing spaces until 20 chars
		JSR $FFFF &  disOpcode		; dissassemble one opcode @oper (will print it)
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
; proceed normally now
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
			_BRA do_skip		; might use BNE as well
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
;	JMP $FFFF &  prnOpcode		; show all and return

; decode opcode and print hex dump
prnOpcode:
; first goes the current address in label style
	LDA #'_'			; make it self-hosting
	JSR $FFFF &  prnChar
	LDA oper+1			; address MSB
	JSR $FFFF &  prnHex			; print it
	LDA oper			; same for LSB
	JSR $FFFF &  prnHex
	LDA #COLON			; code of the colon character
	JSR $FFFF &  prnChar
	LDA #' '			; leading space, might use string
	JSR $FFFF &  prnChar
; then extract the opcode string from scan
	LDY #0				; scan increase, temporarily stored in temp
	STY bytes			; number of bytes to be dumped (-1)
	STY count			; printed chars for proper formatting
	STY value+1			; *** reset operand count because of Hitachi opcodes ***
po_loop:
		LDA (scan), Y		; get char in opcode list
		STY temp			; keep index as will be destroyed
		AND #$7F			; filter out possible end mark
		CMP #'%'			; relative addressing
		BNE po_nrel			; currently the same as single byte!
; put here specific code for relative arguments!
			LDA #'$'			; hex radix
			JSR $FFFF &  prnChar
			LDY #1				; standard branch offset
			LDX #0				; reset offset sign extention
			STY value			; store now as will be added later
			LDY bytes			; retrieve instruction index
			INY					; point to operand!
			LDA (oper), Y		; get offset!
			STY bytes			; correct index
			BPL po_fwd			; forward jump does not extend sign
				DEX					; puts $FF otherwise
po_fwd:
			_INC				; plus opcode...
			CLC					; (will this and the above instead of SEC fix the error???)
			ADC value			; ...and displacement...
			ADC oper			; ...from current position
			PHA					; this is the LSB, now check for the MSB
			TXA					; get sign extention
			ADC oper+1			; add current position MSB plus ocassional carry
			JSR $FFFF &  prnHex			; show as two ciphers
			PLA					; previously computed LSB
			JSR $FFFF &  prnHex			; another two
			LDX #5				; five more chars
			BNE po_done			; update and continue, no need for BRA
po_nrel:
		CMP #'@'			; single byte operand
		BNE po_nbyt			; otherwise check word-sized operand
; *** unified 1 and 2-byte operand management ***
			LDY #1				; number of bytes minus one
			LDX #3				; number of chars to add
			BNE po_disp			; display value, no need for BRA
po_nbyt:
		CMP #'&'			; word operand
		BNE po_nwd			; otherwise is normal char
			LDY #2				; number of bytes minus one
			LDX #5				; number of chars to add
po_disp:
; could check HERE for undefined references!!!
			_PHX				; save values, chars to add
			_PHY				; these are the operand bytes
			STY bytes			; set counter
			LDA #'$'			; hex radix
			JSR $FFFF &  prnChar
			LDY #1				; ***** big endian operand index *****
; ***** should check here for double-operand opcodes (Hitachi only), then INY *****
			LDX value+1			; how many operands already processed?
			BEQ po_dloop		; if first or only, just proceed
				INY					; otherwise advance to next!
po_dloop:
				_PHY				; ***** need to save it *****
				LDA (oper), Y		; get whatever byte
				JSR $FFFF &  prnHex			; show in hex
				_PLY			; **** retrieve operand index *****
				INY				; ***** advance for endianness *****
				DEC bytes			; go back one byte
				BNE po_dloop
			_PLY				; restore original operand size
			STY bytes
			INC value+1			; *** increment number of operands (for Hitachi) ***
			PLA					; number of chars to add
			_BRA po_adv			; update count (direct from A) and continue
po_nwd:
		JSR $FFFF &  prnChar			; just print it
		INC count			; yet another char
		BNE po_char			; eeeeeeeeek, do not think needs BRA
po_done:
		TXA					; increase of number of chars
po_adv:
		CLC
		ADC count			; add to previous value
		STA count			; update value
po_char:
		LDY temp			; get scan index
		LDA (scan), Y		; get current char again
			BMI po_end			; opcode ended, no more to show
		INY					; go for next char otherwise
		JMP $FFFF &  po_loop			; BNE would work as no opcode string near 256 bytes long, but too far...
po_end:
; add spaces until 20 chars!
		LDA #12				; number of chars after the initial 7
		CMP count			; already done?
	BCC po_dump			; go for dump then, even if over
		LDA #' '			; otherwise print a space
		JSR $FFFF &  prnChar
		INC count			; eeeeeeeeeeeek
		BNE po_end			; until complete, again no need for BRA
; print hex dump as a comment!
po_dump:
	LDA #';'			; semicolon as comment introducer
	JSR $FFFF &  prnChar
	LDY #0				; reset index
	STY temp			; save index (no longer scan)
; *** care for Hitachi double-operand opcodes! ***
	LDX value+1			; get detected operands
	CPX #2				; one of these?
	BNE po_dbyt			; if not, proceed normally
		INC bytes			; otherwise takes one more byte!
po_dbyt:
		LDA #' '			; leading space
		JSR $FFFF &  prnChar
		LDY temp			; retrieve index
		LDA (oper), Y		; get current byte in instruction
		JSR $FFFF &  prnHex			; show as hex
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
	BCC po_cr			; in case of page crossing
		INC oper+1
po_cr:
	LDA #CR				; final newline
	JMP $FFFF &  prnChar			; print it and return


; ** .E = examine 'u' lines of memory **
examine:
	JSR $FFFF &  fetch_value		; get address
; ignoring operand error...
	LDY value			; save value elsewhere
	LDA value+1
	STY oper
	STA oper+1
	LDX lines			; get counter
ex_l:
		_PHX				; save counters
		LDA oper+1			; address MSB
		JSR $FFFF &  prnHex			; print it
		LDA oper			; same for LSB
		JSR $FFFF &  prnHex
		LDA #>dump_in		; address of separator
		LDY #<dump_in
		JSR $FFFF &  prnStr			; print it
		; loop for 4/8 hex bytes
		LDY #0				; reset offset
ex_h:
			_PHY				; save offset
; space only when wider than 20 char AND if not the first
#ifndef	NARROW
			BEQ ex_ns			; no space if the first one
				_PHY				; please keep Y!
				LDA #' '			; print space, not in 20-char
				JSR $FFFF &  prnChar
				_PLY				; retrieve Y!
ex_ns:
#endif
			LDA (oper), Y		; get byte
			JSR $FFFF &  prnHex			; print it in hex
			_PLY				; retrieve index
			INY					; next byte
			CPY #PERLINE		; bytes per line (8 if not 20-char)
			BNE ex_h			; continue line
		LDA #>dump_out		; address of separator
		LDY #<dump_out
		JSR $FFFF &  prnStr			; print it
		; loop for 4/8 ASCII
		LDY #0				; reset offset
ex_a:
			_PHY				; save offset BEFORE!
			LDA (oper), Y		; get byte
			CMP #127			; check whether printable
				BCS ex_np
			CMP #' '
			BCS ex_pr			; it is printable
ex_np:
				LDA #'.'			; substitute
ex_pr:		JSR $FFFF &  prnChar			; print it
			_PLY				; retrieve index
			INY					; next byte
			CPY #PERLINE		; bytes per line (8 if not 20-char)
			BNE ex_a			; continue line
		JSR $FFFF &  po_cr			; print trailing newline
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


; ** .I = show symbol table ***
; ***** TO DO ****** TO DO ******


; ** .K = keep (load or save) **
; ### highly system dependent ###
; placeholder will send/read raw data to/from indicated I/O device
ext_bytes:
	JSR $FFFF &  getNextChar		; check for subcommand
	BCC ex_noni			; no need to ask user
; might turn into interactive mode here
		RTS					; fail silently
ex_noni:
; subcommand is OK, let us check target device ###placeholder
	STA count			; first save the subcommand!
	JSR $FFFF &  fetch_byte		; read desired device
		BCS ex_abort		; could not get it
	STA temp			; set as I/O channel
	LDY #0				; reset counter!
	STY oper			; also reset forward counter, decrement is too clumsy!
	STY oper+1
; decide what to do
	LDA count			; restore subcommand
	CMP #'-'			; is it save? (MARATHON MAN)
		BEQ ex_save			; OK to continue
	CMP #'+'			; load otherwise?
		BEQ ex_load			; OK then
ex_abort:
	JMP $FFFF &  _unrecognised	; else I do not know what to do
ex_save:
; save raw bytes
		LDA (ptr), Y		; get source data
		STA io_c			; set parameter
		_PHY				; save index
		LDY temp			; get target device
		_KERNEL(COUT)		; send raw byte!
		_PLY				; restore index eeeeeeeeeek
			BCS ex_err			; aborted!
		INY					; go for next
		BNE esl_nw			; no wrap
			INC ptr+1
esl_nw:
; 16-bit INcrement
		INC oper			; one more
		BNE ex_sinc			; no wrap
			INC oper+1
ex_sinc:
		LDA oper			; check LSB
		CMP siz				; compare against desired size
			BNE ex_save			; continue until done
		LDA oper+1			; check MSB, just in case
		CMP siz+1			; against size
		BNE ex_save			; continue until done
	BEQ ex_ok			; done! no need for BRA
ex_load:
; load raw bytes
		_PHY				; save index
		LDY temp			; get target device
		_KERNEL(CIN)		; get raw byte!
		_PLY				; restore index
			BCS ex_err			; aborted!
		LDA io_c			; get parameter
		STA (ptr), Y		; write destination data
		INY					; go for next
		BNE ell_nw			; no wrap
			INC ptr+1
ell_nw:
; 16-bit INcrement
		INC oper			; one more
		BNE ex_linc			; no wrap
			INC oper+1
ex_linc:
		LDA oper			; check LSB
		CMP siz				; compare against desired size
			BNE ex_load			; continue until done
		LDA oper+1			; check MSB, just in case
		CMP siz+1			; against size
		BNE ex_load			; continue until done
	BEQ ex_ok			; done! no need for BRA
ex_err:
; an I/O error occurred during transfer!
	LDA #>io_err		; set message pointer
	LDY #<io_err
	JSR $FFFF &  prnStr			; print it and finish function
ex_ok:
; transfer ended, show results
	LDA #'$'			; print hex radix
	JSR $FFFF &  prnChar
	LDA oper+1			; get MSB
	JSR $FFFF &  prnHex			; and show it in hex
	LDA oper			; same for LSB
	JSR $FFFF &  prnHex
	LDA #>ex_trok		; get pointer to string
	LDY #<ex_trok
	JMP $FFFF &  prnStr			; and print it! eeeeeek return also


; ** .L = invoke line editor ***
; ***** TO DO ****** TO DO ******


; ** .M = move (copy) 'n' bytes of memory **
move:
; preliminary version goes forward only, modifies ptr.MSB and X!
	JSR $FFFF &  fetch_value		; get operand address
	LDA temp			; at least one?
	BNE mv_ok
		JMP bad_opr		; reject zero loudly
mv_ok:
; the real stuff begins
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
	JSR $FFFF &  fetch_value		; get operand
	LDA value			; check whether zero
	ORA value+1
	BEQ nn_end			; quietly abort operation
		LDY value			; copy LSB
		LDA value+1			; and MSB
		STY siz				; into destination variable
		STA siz+1
nn_end:
	LDA #'N'			; let us print some message
	JSR $FFFF &  prnChar		; print variable name
	LDA #>set_str		; pointer to rest of message
	LDY #<set_str
	JSR $FFFF &  prnStr			; print that
	LDA siz+1			; check current or updated value MSB
	JSR $FFFF &  prnHex			; show in hex
	LDA siz				; same for LSB
	JSR $FFFF &  prnHex			; show in hex
	JMP $FFFF &  po_cr			; print trailing newline and return!


; ** .O = set origin **
origin:
	JSR $FFFF &  fetch_value		; get up to 2 bytes, unchecked
; ignore error as will show up in prompt
	LDY value			; copy LSB
	LDA value+1			; and MSB
	STY ptr				; into destination variable
	STA ptr+1
	RTS


; ** .Q = standard quit **
quit:
	PLA					; discard main loop return address
	PLA
	_FINISH				; exit to minimOS, proper error code, new interface


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
	_BRA sst_loop		; continue, might use BNE?
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
	JSR $FFFF &  fetch_value		; get desired address
	LDA temp			; at least one?
	BNE ta_ok
		JMP bad_opr		; reject zero loudly
ta_ok:
	LDY value			; fetch result
	LDA value+1
	STY bufpt			; this will be new buffer
	STA bufpt+1
	JMP $FFFF &  cli_loop		; execute as commands!


; ** .U = set 'u' number of lines/instructions **
; might replace this for an autoscroll feature
set_lines:
	JSR $FFFF &  fetch_byte		; get operand in A
	TAX					; anything set?
	BEQ sl_show			; fail quietly if zero
		STA lines			; set number of lines
sl_show:
	LDA #'U'			; let us print some message
	JSR $FFFF &  prnChar		; print variable name
	LDA #>set_str		; pointer to rest of message
	LDY #<set_str
	JSR $FFFF &  prnStr			; print that
	LDA lines			; check current or updated value
	JSR $FFFF &  prnHex			; show in hex
	JMP $FFFF &  po_cr			; print trailing newline and return!


; ** .W = store word **
store_word:
	JSR $FFFF &  fetch_value		; get operand, do not force 3-4 hex chars
	LDA value+1			; ***** get MSB, this is big endian *****
	_STAY(ptr)			; store in memory
	INC ptr				; next byte
	BNE sw_nw			; no wrap
		INC ptr+1			; otherwise increment pointer MSB
sw_nw:
	LDA value			; ***** same for LSB, this is big endian *****
	_STAY(ptr)
	INC ptr				; next byte
	BNE sw_end			; no wrap
		INC ptr+1			; otherwise increment pointer MSB
sw_end:
	RTS


; **** Unrecognised command ****
_unrecognised:
	PLA					; discard main loop return address
	PLA
	JMP $FFFF &  bad_cmd			; show error message and continue

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
	JSR $FFFF &  ph_b2a			; convert and print this cipher
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
	LDY #0			; standard device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print a NULL-terminated string pointed by $AAYY *
prnStr:
	STA str_pt+1		; store MSB
	STY str_pt			; LSB
#ifdef	C816
	CMP #0				; A points to zero page by some chance?
	BNE ps_nzp			; no, get "standard" bank
		TDC					; otherwise get Direct page instead
		XBA					; in LSB
		TAX					; ready to be poked
		BRA ps_stk
ps_nzp:
	PHK					; must make sure about current bank!
	PLX
ps_stk:
	STX str_pt+2
#endif
	LDY #0			; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS

; * new approach for hex conversion *
; add one nibble from hex in current char!
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
		ASL value			; current value will be times 16
		ROL value+1
		DEY					; next iteration
		BNE h2n_loop
	ORA value			; combine with older value
	STA value
	CLC					; all done without error
h2n_rts:
	RTS					; usual exit
h2n_err:
	SEC					; notify error!
	RTS

; ** end of inline library **

; * get input line from device at fixed-address buffer *
; new movable buffer!
getLine:
	LDY bufpt			; get buffer address
	LDA bufpt+1			; likely 0!
	STY str_pt			; set parameter
	STA str_pt+1
#ifdef	C816
	CMP #0				; A points to zero page by some chance?
	BNE gl_nzp			; no, get "standard" bank
		TDC					; otherwise get Direct page instead
		XBA					; in LSB
		TAX					; ready to be poked
		BRA gl_stk
gl_nzp:
	PHK					; must make sure about current bank!
	PLX
gl_stk:
	STX str_pt+2
#endif
	LDX #BUFSIZ-1		; max index
	STX ln_siz			; set value
	LDY #0			; use standard device
	_KERNEL(READLN)		; get line
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
	CMP #HTAB			; tabulations will be skipped too
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
		CMP #HTAB			; tabulation?
			BEQ bc_loop			; ignore
		CMP #'$'			; ignored radix?
			BEQ bc_loop			; also ignore
	STY cursor				; otherwise we are done
	RTS

; * get clean NEXT character from opcode list, set Carry if last one! *
; no point on setting Carry if last one!
getListChar:
		INC scan			; try next
		BNE glc_do			; if did not wrap
			INC scan+1			; otherwise carry on
glc_do:
		_LDAY(scan)			; get current
		CMP #' '			; is it blank? will never end an opcode, though
		BEQ getListChar		; nothing interesting yet
	AND #$7F			; most convenient!
	RTS

; * fetch one byte from buffer, value in A and @value.b *
; newest approach as interface for fetch_value
fetch_byte:
	JSR $FFFF &  fetch_value		; get whatever
	LDA temp			; how many bytes will fit?
	_INC				; round up chars...
	LSR					; ...and convert to bytes
	CMP #1				; strictly one?
	_BRA ft_check		; common check

; * fetch two bytes from hex input buffer, value @value.w *
fetch_word:
; another approach using fetch_value
	JSR $FFFF &  fetch_value		; get whatever
	LDA temp			; how many bytes will fit?
	_INC				; round up chars...
	LSR					; ...and convert to bytes
	CMP #2				; strictly two?
; common fetch error check
ft_check:
	BNE ft_err
		CLC					; if so, all OK
		LDA value			; convenient!!!
		RTS
; common fetch error discard routine
ft_err:
	LDA temp			; check how many chars were processed eeeeeeek
	BEQ ft_clean		; nothing to discard eeeeeeeeek
ft_disc:
		JSR $FFFF &  backChar		; should discard previous char!
		DEC temp			; one less to go
		BNE ft_disc			; continue until all was discarded
ft_clean:
	SEC					; there was an error
	RTS

; * fetch typed value, no matter the number of chars *
fetch_value:
	_STZA value			; clear full result
	_STZA value+1
	_STZA temp			; no chars processed yet
; could check here for symbolic references...
ftv_loop:
		JSR $FFFF &  getNextChar		; go to operand first cipher!
		JSR $FFFF &  hex2nib			; process one char
			BCS ftv_bad			; no more valid chars
		INC temp			; otherwise count one
		BNE ftv_loop		; until no more valid, no need for BRA
ftv_bad:
	JSR $FFFF &  backChar		; should discard very last char! eeeeeeeek
	CLC					; always check temp=0 for errors!
	RTS

; *** pointers to command routines (? to Y) ***
cmd_ptr:
	.word	help			; .?
	.word		_unrecognised	; .@
	.word		_unrecognised	; .A
	.word	store_byte		; .B
	.word		_unrecognised	; .C
	.word	disassemble		; .D
	.word	examine			; .E
	.word		_unrecognised	; .F
	.word		_unrecognised	; .G
	.word		_unrecognised	; .H
	.word		_unrecognised	; .I will be symbol_table
	.word		_unrecognised	; .J
	.word	ext_bytes		; .K
	.word		_unrecognised	; .L will invoke line editor
	.word	move			; .M
	.word	set_count		; .N
	.word	origin			; .O
	.word		_unrecognised	; .P
	.word	quit			; .Q
	.word		_unrecognised	; .R
	.word	store_str		; .S
	.word	asm_source		; .T
	.word	set_lines		; .U
	.word		_unrecognised	; .V
	.word	store_word		; .W

; *** strings and other data ***
splash:
	.asc	"MC6800/6801/6301 cross-assembler", CR
	.asc	"for 65xx, v0.5.2", CR
	.asc	"(c) 2017-2018 Carlos J. Santisteban", CR
#ifdef	SAFE
	.asc	"Type 680x opcodes or .commands,", CR
	.asc	".? for help", CR
#endif
	.asc	0

err_bad:
	.asc	"*** Bad command ***", CR, 0

err_opc:
	.asc	"*** Bad opcode ***", CR, 0

err_ovf:
	.asc	"*** Out of range ***", CR, 0

dump_in:
#ifdef	NARROW
	.asc	"[", 0		; for 20-char version
#else
	.asc	" [", 0
#endif

dump_out:
	.asc	"] ", 0

io_err:
	.asc	"*** I/O error ***", CR, 0

set_str:
	.asc	" = $", 0

ex_trok:
	.asc	" bytes transferred", CR, 0

; online help only available under the SAFE option!
help_str:
#ifdef	SAFE
	.asc	"(d => 2 hex chars)", CR
	.asc	"(a => 4 hex chars)", CR
	.asc	"(* => up to 4 chars)", CR
	.asc	"(s => raw string)", CR
	.asc	"---Command list---", CR
	.asc	".? = show this list", CR
	.asc	".Bd = store byte", CR
	.asc	".D* = dis. 'u' instr", CR
	.asc	".E* = dump 'u' lines", CR
	.asc	".K+d=load n byt. @#d", CR
	.asc	".K-d=save n byt. @#d", CR
	.asc	".Ma=copy n byt. to a", CR
	.asc	".N* = set 'n' value", CR
	.asc	".O* = set origin", CR
	.asc	".Q = quit", CR
	.asc	".Ss = put raw string", CR
	.asc	".T* = assemble src.", CR
	.asc	".Ud = set 'u' lines", CR
	.asc	".Wa = store word", CR
#endif
	.byt	0

; include opcode list
da_oclist:
; this is the full 6301/6303 list
#include "data/opc6301.s"
a68_end:					; size computation
.)
