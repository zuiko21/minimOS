; nanoPython (Proof Of Concept)
; (c) 2023 Carlos J. Santisteban
; last modified 20231005-1540

; assemble from /forge/nanopython with:
; xa np.s -I ../../OS/firmware

; *** zeropage ***
cio_pt		= $E6
cio_src		= $E4
temptr		= $E8
cursor		= $EA			; input buffer position
cmd_id		= $EB			; token counter
vars		= $80			; a-z, single byte!
old			= vars+26		; previous operand
oper		= old+1			; operator
result		= oper+1		; last evaluation
lvalue		= result+1		; variable to be assigned after end of evaluation (0=none, 1=a... 26=z)
scratch		= lvalue+1		; temporary value
prnflag		= scratch+1		; print enabled
errflag		= prnflag+1		; error detected
assign		= errflag+1		; pending assignation
exitf		= assign+1		; exit requested

; *** hardware definitions for Durango-X ***
IO8attr		= $DF80
IO9di		= $DF9A		; data input (PASK standard)
IOAen		= $DFA0
IOBeep		= $DFB0		; canonical buzzer address (d0)

; *** firmware definitions for Durango-X ***
fw_irq		= $0200			; ### usual minimOS interrupt vectors ###
fw_nmi		= $0202			; not used
ticks		= $0206			; jiffy counter EEEEK
; make room for keyboard driver ($020A-$020F)
; CONIO specific variables
fw_cbin		= $0210			; integrated picoVDU/Durango-X specifics
fw_fnt		= fw_cbin+1		; (new, pointer to relocatable 2KB font file)
fw_mask		= fw_fnt+2		; (for inverse/emphasis mode)
fw_chalf	= fw_mask+1		; (remaining pages to write)
fw_sind		= fw_chalf+1
fw_ccol		= fw_sind+3		; (no longer SPARSE array of two-pixel combos, will store ink & paper)
fw_ctmp		= fw_ccol+4
fw_cbyt		= fw_ctmp		; (temporary glyph storage) other tmp
fw_ccnt		= fw_cbyt		; (bytes per raster counter, no longer X) actually the same tmp
fw_ciop		= fw_ccnt+1		; cursor position
fw_vbot		= fw_ciop+2		; page start of screen at current hardware setting (updated upon FF)
fw_vtop		= fw_vbot+1		; first non-VRAM page (new)
fw_io9		= fw_vtop+1		; received keypress
fw_scur		= fw_io9+1		; NEW, cursor control
; parser workspace
buffer		= fw_scur+1		; input buffer
;lvalue		= buffer+80		; variable to be assigned

*	= $C000

rom_start:
; header ID
	.byt	0						; [0]=NUL, first magic number
	.asc	"dX"					; bootable ROM for Durango-X devCart
	.asc	"****"					; reserved
	.byt	13						; [7]=NEWLINE, second magic number
; filename
	.asc	"nanoPython POC"		; C-string with filename @ [8], max 238 chars
	.byt	0						; first terminator for filename
	.asc	""						; optional C-string with comment after filename, filename+comment up to 238 chars
	.byt	0						; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; library commit (new, optional)
	.asc	"--------"				; USERFIELD2
	.dsb	(rom_start + $EE - *) * (* < rom_start+$EE), $FF	; padding in case of string shorter than 8 chars!
; version number (new)
	.word	$0000					; VERSION
; main commit (new, helpful)
	.asc	"--------"				; USERFIELD1
	.dsb	(rom_start + $F8 - *) * (* < rom_start+$F8), $FF	; padding in case of string shorter than 8 chars!
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$9D80					; H_TIME
	.word	$5597					; H_DATE
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start		; filesize (rom_end is actually $10000)
	.word	0						; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *************************
; *** *** main code *** ***
; *************************

nanopython:
	LDX #>splash
	LDY #<splash
	JSR string
repl:
		JSR prompt
		STZ cursor
buff:
			JSR getch
			PHY				; eeeek
			CPY #8			; BACKSPACE?
			BNE echo
				LDX cursor
				BNE delete
					LDY #7		; BELL if nothing to delete
					JSR conio
					JMP buff	; continue input
delete:
				DEC cursor
				JSR conio		; actual screen deletion
				JMP buff
echo:
			JSR conio		; *** just echo
			PLA				; this was the received char
			LDX cursor		; current position
			STA buffer, X	; store received
			INC cursor
			CMP #13			; hit RETURN?
		BEQ parse
			BNE buff
parse:
		STZ buffer, X		; terminate input buffer
; *** inline parse() function, as only called here ***
		STZ cursor
		STZ oper
		STZ prnflag
		STZ errflag
		STZ exitf
		STZ lvalue
		STZ assign
ploop:
			LDA errflag		; while (!errflag...
		BNE chk_err
			LDX cursor
			LDA buffer, X
		BEQ chk_err			; ... && buffer[cursor]) {
			JSR get_token	; a = get_token();		*** could be inlined as well ***
			BPL do_exec		; if (a<0)	evaluate();
				JSR evaluate
				BRA no_exec
do_exec:
			JSR execute		; else	execute();
no_exec:
			BRA ploop
chk_err:
		LDA errflag
	BNE do_error
		LDA prnflag
		BEQ no_print
			JSR print
no_print:
		LDA assign
		BEQ no_assign
			LDX lvalue
			LDA result
			STA vars-1, X
no_assign:
		LDA errflag			; actually 0
do_error:					; return errflag;
; *** end of parse() ***
		BEQ no_err			; if (parse())	error();
			LDX #>wtf
			LDY #<wtf
			JSR string
			JMP repl
no_err:
		LDA exitf			; } while (!exitf);
	BNE exit
		JMP repl
exit:
	LDX #>bye
	LDY #<bye
	JSR string
	BRK						; this will exit with a flashing LED

; ************************
; *** support routines ***
; ************************
getch:
; *** get a character from keyboard (locking) ***
		LDY #0
		JSR conio			; character input
		BCS getch
	RTS

prompt:
; *** display current prompt ***
	LDX #>pr3gt
	LDY #<pr3gt
	JMP string				; print prompt and return

string:
; *** display string at XY ***
	STX temptr+1
	STZ temptr				; set pointer
str_loop:
		LDA (temptr), Y		; get char from string
			BEQ str_end		; terminator will finish printing
		PHY					; keep cursor
		TAY					; eeeeek
		JSR conio			; display char
		PLY					; retrieve cursor
		INY					; next char
		BNE str_loop
	INC temptr+1			; in case of page crossing
		BNE str_loop		; always
str_end:
	RTS

get_token:
; *** detect some token at specified position ***
	LDY #<tokens
	LDA #>tokens
	STY temptr
	STA temptr+1			; start of token list
	STZ cmd_id				; reset token counter
tk_loop:
		LDX cursor			; try from current position
		LDY #0
tk_char:
			LDA (temptr), Y	; check token list
		BEQ found			; if (!a)	break;					terminated token without any difference found
			CMP buffer, X	; compare with what is at the input
		BNE next_tk			; if (a != buffer[x])	break;		any difference will try next token
			INX
			INY				; advance position
			BRA tk_char		; keep trying
next_tk:					; do {
		INY					; eeeeeeeeeeeek
		LDA (temptr), Y		; a = tokens[y+temptr];
		BNE next_tk			; } while (a);						browse until end of token
	INC cmd_id				; eeeeek
	INY
	TYA
	CLC
	ADC temptr
	STA temptr				; temptr += y;						advance to next token in list
	BCC tk_pass				; try another one
		INC temptr+1		; in case of page crossing
tk_pass:
	LDA (temptr)			; check start of new token
	BPL tk_loop				; } while(tokens[temptr] >= 0);		go check next token...
; if arrived here, token is invalid (list has ended at $FF)
	RTS						; return -1;						try to evaluate a expression
found:
	LDA cmd_id
	RTS						; return cmd_id;

evaluate:
; *** get values from variables or numeric constants ***
	LDX cursor				; just in case
; single-letter variables
	LDA buffer, X			; take current char from buffer
	BNE not_eol				; no more in buffer! check for assignation
		RTS
not_eol:					; if (a) {
	JSR isletter			; variable, perhaps?
	BEQ evalnum				; if (a) {							eeeeeek
		TAY					; use as index
		LDA vars-1, Y		; note offset
		CPX #0				; justified use
		BEQ is_lvalue
			STA result		; if (x)	result = a;
			BRA was_rval
is_lvalue:
		STY lvalue			; else		lvalue = y;
was_rval:
		INX
		BRA pending
evalnum:
; single-byte numbers and basic operators with no priorities nor parenthesis
	STZ result
	STX cmd_id				; * better error handling *
enuml:						; do {
		LDA buffer, X
		CMP #'0'
			BCC pending
		CMP #'9'+1
			BCS pending		; if (a<'0' || a>'9')	break;		no more numbers
; if arrived here, it's a number
		SBC #'0'-1			; C was clear, thus borrows
		ASL result			; times 2...
		LDY result
		STY scratch			; ...will be added
		ASL result
		ASL result			; now times 8
		CLC					; just in case
		ADC result			; 8i+j
		ADC scratch			; 10i+j
		STA result			; ...result *= 10; a += result; result = a;
		INX					; next char
		BRA enuml			; } while (x);						actually more like	} while(1);
; * new code for better error handling *
	CPX cmd_id
	BNE pending				; no strange characters found
		INX
		STX cursor
		JMP error
; * *
pending:
	STX cursor
	LDA oper				; x = oper;							see below
	ASL 					; times two for indexing
	TAX						; eeeeeek
	JMP (exec, X)			; switch(x) {						do command
; *** pending operation execution block ***
p_add:						; case 1:
	LDA old
	CLC
	ADC result
	STA result				; result = old + result;
	BRA not_pend
p_sub:
	LDA old
	SEC
	SBC result
	STA result				; result = old - result;
	BRA not_pend
p_mul:						; *** quick-and-dirty multiplication algorithm ***
	LDA #0
	CLC
	LDY result
		BEQ not_pend		; n * 0 = 0, do nothing
mul_loop:
		ADC old
		DEY
		BNE mul_loop
	STA result				; result = old * result;
	BRA not_pend
p_div:						; *** quick-and-dirtiest division algorithm ***
	LDA result
	BNE div_ok
		INC errflag			; generic error for divide-by-zero
		BRA not_pend
div_ok:
	LDY #0
	LDA old
div_loop:
		CMP result
	BCC quot
;	BEQ quot
		SEC
		SBC result
		INY
		BRA div_loop
quot:
	STY result				; result = old / result;
;	BRA not_pend			; ...break
not_pend:
	STZ oper				; oper = 0...
	RTS

execute:
; *** perform detected token ***
	LDY oper				; is there any pending operation?
		BNE error			; note this prevents the use of negative numbers
	STX cursor
	ASL						; A times two for indexing
	TAX
	JMP (set_tk, X)			; switch(a);
; *** token acknowledge execution block ***
t_prn:
	INC prnflag
	BRA end_ex
t_bye:
	INC exitf
	BRA end_ex
t_asgn:
	LDA lvalue
		BEQ error
	INC assign
	BRA end_ex
t_add:
t_sub:
t_mul:
t_div:
	LSR						; eeeeeeeeeeeeeeeeek
	DEC
	DEC
	STA oper				; oper is actually A-2
end_ex:
	LDA result
	STA old					; old = result;
	RTS

isletter:
; *** check A if letter, return index 1...26 or 0 if failed
	ORA #32					; all lower case
	CMP #'a'				; check whether letter
		BCC notvar
	CMP #'z'+1
	BCC var_ok
notvar:
		LDA #'a'-1			; C is set, after subraction will result 0
var_ok:
	SBC #'a'-2				; C known clear, but should turn 'a' into 1 (proper l_value)
	RTS

error:
; *** discard stack, print error message and back to line input ***
	PLA
	PLA						; discard return address
	JMP do_error

print:
; *** display 'result' in decimal form ***
	STZ scratch					; temporary use, 0=previous zero not printed, 1=print everything
	LDA result
	LDX #0
cent:
		CMP #100
	BCC no_cent
		SBC #100				; C was set
		INX
		BRA cent
no_cent:
	PHA							; keep value!
	TXA
	BEQ nlead_c
		INC scratch				; does have hundreds, thus next zero is needed
		ADC #'0'				; C was clear
		TAY
		JSR conio
nlead_c:
	PLA							; retrieve value
	LDX #0
tens:
		CMP #10
	BCC no_tens
		SBC #10					; C was set
		INX
		BRA tens
no_tens:
	PHA							; keep value!
	LDA scratch					; check previous zero
		BNE ylead_t				; none skipped, thus print even if zero
	TXA
	BEQ nlead_t
ylead_t:
		TXA
		CLC
		ADC #'0'				; C is not known
		TAY
		JSR conio
nlead_t:
	PLA							; retrieve remaining value, just units
	CLC
	ADC #'0'					; no previous comparison, thus clear C
	TAY
	JSR conio
	LDY #13
	JMP conio					; new line and return

; ********************
; *** *** data *** ***
; ********************
splash:
	.asc	"65C02 nanoPython PoC 0.1", 13, "@zuiko21", 13, 0
bye:
	.asc	13, "Thanks for using nanoPython on", 13, "the 65C02-powered ", 14, "Durango·X", 15,"!", 0
wtf:
	.asc	13, 14, "*** WTF?? ***", 15, 7, 13, 0
pr3gt:
	.asc	13, ">>> ", 0
tokens:
	.asc	"print ", 0
	.asc	"quit()", 0
	.asc	"=", 0
	.asc	"+", 0
	.asc	"-", 0
	.asc	"*", 0
	.asc	"/", 0
	.byt	$FF				; list termination

; *** *** *** ***** *** *** ***
; *** pending operation pointer list ***
exec:
	.word	not_pend		; NULL pointer for unused index 0
	.word	p_add
	.word	p_sub
	.word	p_mul
	.word	p_div
; *** token acknowledge pointer list ***
set_tk:
	.word	t_prn
	.word	t_bye
	.word	t_asgn
	.word	t_add
	.word	t_sub
	.word	t_mul
	.word	t_div
; *** *** *** ***** *** *** ***

	.dsb	$E000-*, $FF	; just in case, skip IO

; ********************
; *** *** BIOS *** ***
; ********************

reset:
; POST
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
	STX IOAen				; ### enable Durango-X hardware interrupt ###
	STX fw_scur				; as bit 7 is on, activates cursor
	LDA #$B0				; start in HIRES mode
	STA IO8attr
	LDX #3					; max jiffy counter index
jf_res:
		STZ ticks, X		; reset all jiffy counter bytes
		STZ kb_asc, X		; init all keyboard variables too, up to kb_scan (4 bytes)
		DEX
		BPL jf_res
	LDX #>std_irq
	LDY #<std_irq
	STY fw_irq				; set standard interrupt vectors (NMI is not used)
	STX fw_irq+1
; * check keyboard *
	LDX #0					; default is PASK
	LDA #32					; column 6
	STA IO9m5x8				; select it
	LDA IO9m5x8				; and read rows
	CMP #$2C				; is it a 5x8 matrix? EEEEEEEEK
	BNE not_5x8
		LDX #2				; set as default keyboard
not_5x8:
	STX kb_type				; set selected type
; * init CONIO *
	STZ fw_cbin				; EEEEEEK
	STZ fw_mask
	STZ fw_io9
	LDA #$87				; yellow on blue intial colours (not for HIRES)
	STA fw_ccol+1			; will reconstruct colours from this upon FF
	LDY #12					; FF = clear screen
	JSR conio

	JMP nanopython			; start nanoPython

; **************************
; *** interrupt handlers ***
; **************************
irq:
	JMP (fw_irq)			; standard minimOS vector
std_irq:					; IRQ support for EhBASIC, from min_mon.asm
; *** minimOS jiffy counter ***
	INC ticks
	BNE irq_sup
		INC ticks+1
	BNE irq_sup
		INC ticks+2
	BNE irq_sup
		INC ticks+3
irq_sup:
	PHA
	PHX
	PHY						; needed for 5x8 matrix support
; *** interrupt support for matrix keyboard ***
	JSR kbd_isr
; in extremis check for (catastrophic) BRK
;	PHX						; already saved
	TSX
	LDA $104, X				; get pushed PSR (note stack frame)
	AND #$10				; check BRK bit
	BEQ not_brk
; *** BRK happened *** will keep the LED flashing, as no debugger is installed
brk_panic:
				INX
				BNE brk_panic
			INY
			BNE brk_panic	; 0.2s delay
		INC					; cycle LED
		STA IOAen
		BRA brk_panic
not_brk:
	PLY						; for 5x8 matrix support
	PLX
	PLA
nmi:						; NMI does nothing
	RTI

; ******************************
; *** multi-keyboard support ***
; ******************************
kbd_isr:
	LDX kb_type
	JMP (kbd_drv, X)		; CMOS only
; drivers pointer list
kbd_drv:
	.word	drv_pask
	.word	drv_5x8
; generic PASK driver
drv_pask:
	LDA IO9pask				; PASK peripheral address
	STA kb_asc				; store for software
	RTS

#include "../../OS/macros.h"
; EMPTY definition from abi.h
#define	EMPTY	6
#define	SAFE
-conio:
#include "../../OS/firmware/modules/conio-durango-fast.s"

; keyboard driver
#include "../../OS/firmware/modules/durango-5x8key.s"

; ************************************************
; *** padding, signatures and hardware vectors ***
; ************************************************

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; minimOS-compliant Durango-X cartridge signature
	.dsb	$FFDE-*, $FF
	.word	$FFFF			; Fletcher-16 checksum placeholder (not currently used)
	SEI
	JMP ($FFFC)				; devCart support @ $FFE1!

	.dsb	$FFFA-*, $FF

	.word	nmi				; standard 6502 hardware vectors
	.word	reset
	.word	irq

