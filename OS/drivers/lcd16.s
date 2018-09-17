; Hitachi LCD for minimOS-16
; v0.6a4
; (c) 2018 Carlos J. Santisteban
; last modified 20180917-2211

; new VIA-connected device ID is $10-17, will go into PB
; VIA bit functions (data goes thru PA)
; E	= PB0 (easier pulsing)
; RS	= PB1
; R/W	= PB2
; should it respect PB3? Just in case...

; ***********************
; *** minimOS headers ***
; ***********************
//#include "../usual.h"
#include "options/chihuahua_plus.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"

* = $200
#include "drivers/lcd.h"
.text

.(
; *** assembly options and other constants ***
; substitution for undefined chars
#define	SUBST	'?'
; enable char redefining for international support
#define	INTLSUP	_INTLSUP

; *** begins with sub-function addresses table ***
	.byt	144			; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	lcd_err		; does not read
	.word	lcd_prn		; print N characters
	.word	lcd_init	; initialise device, called by POST only
	.word	lcd_rts		; no periodic interrupt
	.word	0			; frequency makes no sense
	.word	lcd_err		; D_ASYN does nothing
	.word	lcd_err		; no config
	.word	lcd_err		; no status
	.word	lcd_off		; shutdown procedure will disable display
	.word	lcd_txt		; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
lcd_txt:
	.asc	"20x4 LCD v0.6-16bit", 0

lcd_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	L_OTH	= %00001000	; bits to be kept, PB3 only
	L_NOTH	= %11110111	; required PB outputs (inverse of L_OTH)
	LCD_ID	= %00010000	; idle command E=0 (pulse PB0 via INC/DEC)
	LCD_PR	= %00010010	; set RS for printing & CG (PB1)
	LCD_RS	= %00010100	; read status from LCD (PB2)
	LCD_RM	= %00010110	; read DDRAM/CGRAM (PB2+PB1)

; size definitions for other size LCDs
	L_CHAR	= 20		; chars per line
	L_LINE	= 4		; lines

#ifdef	INTLSUP
; glyph redefinition size
	num_glph	= cg_glph - cg_defs
#endif

; ************************
; *** initialise stuff ***
; ************************
lcd_init:
	JSR lcd_rst		; set VIA ready for LCD command
; follow standard LCD init procedure
	LDX #2			; wait values [0..2]
ld_loop:
		LDY wait_c, X	; get delay (in 100us units)
; * code for waiting Y×100 uS *
; base 100uS delay
w100us:
			LDA #14			; 97+5uS delay @ 1 MHz, change or compute if needed
w_loop:
				SEC				; (2)
				SBC #1			; (2)
				BNE w_loop		; (3)
			DEY				; another 100uS
			BNE w100us
; end of delay code
		LDA #$30		; standard init value
		JSR l_issue		; ...as command sent
		DEX				; next delay
		BPL ld_loop
; set LCD parameters
	LDX #4			; will send 5 commands
li_loop:
		JSR l_busy		; wait for LCD availability
		LDA l_set, X		; get config command
		JSR l_issue		; ...as command sent
		DEX				; next command
		BPL li_loop
; LCD is ready, proceed with driver variables
	STZ lcd_x		; reset coordinate
	STZ lcd_y		; reset coordinate
#ifdef	INTLSUP
	STZ nx_sub		; next free substitution entry (for intl support)
	LDX #7
ints_l:
		STZ cg_sub, X	; clear substitution entry
		DEX
		BPL ints_l
#endif
lcd_off:			; *** placeholder ***
	_DR_OK			; succeeded

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
lcd_prn:
	.xl: REP #$10			; 16-bit index
	LDY #0				; reset index
	LDX bl_siz			; not empty?
	BEQ lcd_end
lp_l:
		PHY				; keep these
		PHP
		LDA [bl_ptr], Y		; buffer contents...
		STA io_c			; ...will be sent
		.xs: SEP #$10
		JSR lcd_char		; *** print one byte ***
			BCS lcd_exit		; any error ends transfer!
		PLP: .xl
		PLY				; restore size and index
		INY					; go for next
		LDX bl_siz			; bytes to go
		DEX					; one less
		STX bl_siz		; update
		BNE lp_l
	BRA lcd_end		; until the end
lcd_exit:
		PLA
		PLA				; discard saved index, but respect possible error code
lcd_end:
	.xs: SEP #$10
lcd_rts:
	RTS					; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
lcd_char:
; first check whether control char or printable
	LDA io_c			; get char (3)
	CMP #' '			; printable? (2)
	BCS lch_wdd			; it is! skip further comparisons (3)
		CMP #FORMFEED		; clear screen?
		BNE lch_nff
			JMP lcd_cls			; clear and return!
lch_nff:
		CMP #LF			; line feed?
		BNE lch_nlf
			JMP lcd_lf			; clear and return!
lch_nlf:
		CMP #CR				; newline?
		BNE lch_ncr
			JMP lcd_cr			; scrolling perhaps
lch_ncr:
		CMP #HTAB			; tab?
		BNE lch_ntb
			JMP lcd_tab			; advance cursor
lch_ntb:
		CMP #BS				; backspace?
		BNE lch_nbs
			JMP lcd_bs			; delete last character
lch_nbs:
; non-printable neither accepted control, thus use substitution character
		LDA #SUBST			; unrecognised char
		STA io_c			; store as required
lch_wdd:
	JSR l_avail			; wait for LCD
; set up VIA for LCD print (RS)
	LDA VIA_U+IORB		; current PB (4)
	AND #L_OTH			; respect PB3 only (2)
	ORA #LCD_PR			; allow DDRAM write (2)
	STA VIA_U+IORB		; set mode... (4)
; send char at io_c
	LDA io_c			; get char
; *** *** should check here for special characters *** ***
#ifdef	INTLSUP
; assuming ROM code A02!
; 128-143 are the ZX Spectrum graphics (16)
; 144-159 taken from CP437 @ $Ex, most coincide except 145, 150, 152 & 157... (4)
; ...which come from CP437 @ $Fx and can be found elsewhere
; other changes are 160, 164, 168, 172, 173, 175, 180, 185, 188-190 (11)
; 184 (lowercase omega) differs from ISO 8859-1, but is OK on LCD
; 164 (€), 189 (oe) come from 8859-15
; thus 191 & up are OK just like 8859-1
	BPL lch_ok2			; standard ASCII
		CMP #191			; higher chars like ISO-8859
	BCS lch_ok
; I think is best to use a LUT 128-190, zero means must be redefined
		AND #$7F			; supress MSb eeeeeek
		TAX					; index for LUT
		LDA isolut, X			; check code or redefine
lch_ok2:
	BNE lch_ok			; no change (or substitute available)
; *** zero in LUT means char is not available, so seek for a definition ***
; 1) look if already has been defined, if so just use it
		LDX #7				; max index for assign array
sc_sub:
			CMP cg_sub, X			; check entry
				BEQ sc_yet			; already defined
			DEX					; try another
			BPL sc_sub
		BMI sc_sch			; not found, get definition (BRA)
sc_yet:
		TXA				; number of user-defined char...
		ORA #128			; ...plus 128 for LCD!
		BNE lch_ok			; all done (BRA)
; 2) look it up into supplied definitions
sc_sch:
		LDX #num_glph-1		; max index for definitions array (size must be 32 or less)
sc_ldef:
			CMP cg_defs, X			; is this the glyph?
				BEQ sc_reg			; yeah, send it
			DEX					; or try another
			BPL sc_ldef
; strange to arrive here... just use usual substitution character
		LDA #SUBST
			BNE lch_ok			; actually BRA
; 3) take note of new definition
sc_reg:
		LDY nx_sub			; first free element in assigns array
		STA cg_sub, Y			; store before original code is lost
		INY				; advance pointer
		TYA
		AND #7				; mod 8
		STA nx_sub
; 4) send definition to CGRAM
		TXA					; index of glyph
		ASL					; times 8
		ASL
		ASL
		TAX					; will save index into glyph 'file'
		CLC
		ADC #8				; will need final index for loop
		STA lc_tmp			; I need this variable
; let us set CGRAM address for this
		JSR l_busy			; wait for LCD
		_PHX				; much safer in case of timeout
		LDX nx_sub			; first free entry...
		DEX					; ...minus 1...
		TXA					; ...is last used
		AND #7				; in case it wrapped
		ORA #64				; make it set CGRAM command
		JSR l_issue
; now transfer the whole 8 bytes from glyph record
		_PLX					; retrieve file index
		LDA VIA_U+IORB		; current PB (4)
		AND #L_OTH			; respect PB3 only (2)
		ORA #LCD_PR			; allow CGRAM write (2)
		STA VIA_U+IORB		; set mode... (4)
sc_wcl:
			JSR l_busy		; wait for CGRAM access
			LDA VIA_U+IORB		; current PB (4)
			AND #L_OTH			; respect PB3 only (2)
			ORA #LCD_PR			; allow CGRAM write (2)
			STA VIA_U+IORB		; set mode... (4)
			LDA cg_glph, X		; get byte from glyph
			JSR l_issue		; write into device
			INX
			CPX lc_tmp		; are we done.
			BNE sc_wcl
		JSR l_busy		; will need it
; 5) get substitution (128-135)
		LDX nx_sub			; first free entry...
		DEX				; ...minus 1...
		TXA				; ...is last used
		AND #7			; in case it wrapped
#endif
; *** *** end of regional support *** ***
lch_ok:
	JSR l_issue			; enable transfer
; advance local cursor position and check for possible wrap/scroll
	INC lcd_x			; one more char
	LDA lcd_x			; check for EOL
	CMP #L_CHAR
		BEQ lcd_cr			; wrapped, thus do CR
	_DR_OK

; *************************
; *** printing routines ***
; *************************

; *** clear the screen ***
lcd_cls:
	_STZA lcd_x		; clear local coordinates
	_STZA lcd_y
	JSR l_busy		; wait for LCD availability
	LDA #1			; command = clear display
; * issue command on A, assume PB set for cmd output *
l_issue:
	STA VIA_U+IORA		; eeeeeeeeeeeeeek
l_pulse:
	INC VIA_U+IORB		; pulse E on LCD!
	DEC VIA_U+IORB
	RTS

; *** new line and line feed ***
lcd_cr:
	JSR l_busy		; ready for several commands
	_STZA lcd_x		; correct local coordinates
lcd_lf:
	INC lcd_y
	LDA lcd_y		; check whether should scroll
	CMP #L_LINE
	BCC lcr_ns		; no scroll
; ** scrolling code, may become routine if makes branches too far **
		LDY #1			; yes, first source line
lcr_sc:
			STY lcd_y		; will be loop variable
			LDA l_addr, Y	; address of this line
			ORA #%10000000	; set DDRAM address
			JSR l_issue
			LDX #0			; loop variable
lcr_scr:
				JSR l_avail		; wait for DDRAM access
				LDA #LCD_RM		; will read
				STA VIA_U+IORB
				INC VIA_U+IORB	; enable...
				LDA VIA_U+IORA	; get byte and advance pointer
				DEC VIA_U+IORB	; ...and disable
				STA l_buff, X	; store temporarily
				INX
				CPX #L_CHAR		; until 20 chars done
				BNE lcr_scr
; one 20 char line in buffer, copy back on line above
			JSR l_busy
			LDY lcd_y		; destination is one line less
			DEY
			LDA l_addr, Y	; address of this line
			ORA #%10000000	; set DDRAM address
			JSR l_issue
			LDX #0			; loop variable
lcr_scw:
				JSR l_busy		; wait for DDRAM access
				LDA #LCD_PR		; will write
				STA VIA_U+IORB
				LDA l_buff, X	; retrieve from buffer
				JSR l_issue	; and write into device
				INX
				CPX #L_CHAR		; until 20 chars done
				BNE lcr_scw
; proceed until three lines have been moved
			LDY lcd_y		; advance one line
			INY
			CPY #L_LINE		; all done?
			BNE lcr_sc
		DEY				; eeeeeeeeeeek
		STY lcd_y		; restore as maximum
; before exit, should clear bottom line!
		JSR l_busy
		LDA l_addr+L_LINE-1	; bottom line address (+3)
		ORA #%10000000	; set DDRAM address
		JSR l_issue
		LDX #L_CHAR		; spaces to be printed
; this space-printing loop cannot use regular lcd_prn as the last one will invoke CR
lcr_sp:
			JSR l_busy		; wait for DDRAM access
			LDA #LCD_PR		; will write
			STA VIA_U+IORB
			LDA #' '		; white space
			JSR l_issue		; write into device
			DEX
			BNE lcr_sp		; until done
		JSR l_busy		; wait for address setting
; ** end of scrolling code **
lcr_ns:
	LDX lcd_y		; index for y
	LDA l_addr, X	; current line address
; as this is common for CR & LF, the latter may not assume X as 0
	CLC
	ADC lcd_x		; either zero or current value
; preset address
	ORA #%10000000	; set DDRAM address
	JMP l_issue		; issue command and return

; *** tab (4 spaces) ***
lcd_tab:
	LDA lcd_x		; get column
	AND #%11111100	; modulo 4
	CLC
	ADC #4			; increment to target position (2)
	SEC
	SBC lcd_x		; subtract current, these are the needed spaces
	TAX				; will be respected
	LDA #' '		; char to be printed, set once only
	STA io_c
ltab_sp:
		JSR lcd_prn		; do print that space, but must respect X
		DEX
		BNE ltab_sp		; until done
; regular print will take care of possible CR
	_DR_OK

; *** backspace ***
lcd_bs:
; first get cursor one position back...
	LDA lcd_x		; nothing to the left? (4)
	BNE lbs_ok		; something, go back one (3/2)
		_DR_ERR(EMPTY)		; nothing, complain somehow
	DEC lcd_x		; one position back (6)
lbs_ok:
; ...then print a space
; easier with cursor shift! 26 vs 39b
	JSR l_busy		; wait for LCD
	LDA #$10		; shift left cursor!
	JSR l_issue
	LDA #' '		; will print a space
	STA io_c
	JSR lcd_prn		; regular print
	DEC lcd_x		; one position back (6)
	JSR l_busy		; wait for LCD again
	LDA #$10		; shift left cursor again!
	JSR l_issue
	_DR_OK			; local cursor was not affected

; ************************
; *** generic routines ***
; ************************

; *** set up VIA for LCD commands ***
lcd_rst:
	LDA VIA_U+DDRB		; control port... (4)
	ORA #L_NOTH		; ...with required outputs... (2)
	STA VIA_U+DDRB		; ...just in case (4)
; *** faster command output ***
lcd_out:
	LDA #$FF			; all outputs... (2)
	STA VIA_U+DDRA		; ...as uses 8-bit mode (4)
; *** even faster command mode set ***
lcd_cmd:
	LDA VIA_U+IORB		; original PB value on user VIA (4)
lcd_cpb:
	AND #L_OTH			; leave PB3 (2)
	ORA #LCD_ID		; E=RS=0, ready for commands
	STA VIA_U+IORB		; just waiting for E to send LCD command in PA (4)
	RTS

; *** wait command completion *** respects X
l_busy:
	JSR l_wait		; generic busy check
	JSR lcd_cpb		; ready for command (A was PB)
	DEC VIA_U+DDRA	; set back outputs
	RTS

; *** wait for sending chars*** respects X
l_avail:
	JSR l_wait		; cannot optimise as JMP, in case of timeout!
	RTS			; back with PA as input

; ** generic availability check **
l_wait:
	_STZA VIA_U+DDRA	; set input!
	LDA VIA_U+IORB	; original PB
	AND #L_OTH		; respect bits
	ORA #LCD_RS		; will read status
	STA VIA_U+IORB
	LDY #74			; for 2.25 ms timeout
lb_loop:
; MUST implement some timeout, or will hang if disconnected!!
		DEY
			BEQ l_tout			; timeout expired!
; is busy flag updated without pulsing E? if so, may put INC before and DEC after the loop!
		INC VIA_U+IORB	; enable...
		BIT VIA_U+IORA	; read status (respect A)
		PHP				; must keep this
		DEC VIA_U+IORB	; ...and disable
		PLP				; unaffected by DEC
		BMI lb_loop		; until available
	RTS
; ** timeout handler **
l_tout:
	PLA					; discard both return addresses
	PLA
	PLA
	PLA
	_DR_ERR(TIMEOUT)

; ********************
; *** several data ***
; ********************

; initialisation delays (reversed)
wait_c:
	.byt	1, 41, 150	; 15ms, 4.1ms & 100us

; initialisation commands (reversed)
l_set:
	.byt	%00001110	; enable display & cursor
	.byt	%00000110	; entry set = increment, do not shift
	.byt	%00000001	; display clear
	.byt	%00001000	; display off
	.byt	%00111000	; 8-bit, 2 lines, 5x8 font

; line adresses
l_addr:
	.byt	0, $40, $14, $54	; start address of each line

#ifdef	INTLSUP
; LUT marking undefined chars
isolut:
	.byt	32,	0,	0,	0,	0,	0,	0,	0	; 128-143, ZX semigraphics, note 128 is just remapped to space
	.byt	0,	0,	0,	0,	0,	0,	0,	0
	.byt	144,	17,	146,	147,	148,	149,	28,	151	; 144-159, most like CP437 $Ex with some remappings
	.byt	29,	153,	154,	155,	156,	126,	158,	159
	.byt	135,	161,	162,	163,	0,	165,	166,	167	; note NBSP is now a hollow square, SHY is 'not-equal' (remapped to Yen) and a few more changes
	.byt	0,	169,	170,	171,	0,	165,	174,	0
	.byt	176,	177,	178,	179,	39,	181,	182,	183
	.byt	184,	127,	186,	187,	23,	0,	102		; up to 190, rest is unchanged

; list of (currently) 20 redefinitions (glyphs must be at 8×index)
cg_defs:
	.byt	129, 130, 131, 132, 133, 134, 135	; ZX graphics (128 is a space)
	.byt	136, 137, 138, 139, 140, 141, 142, 143
	.byt	164, 168, 172, 175, 189			; euro sign and other differences between ISO 8859-1 & -15, SHY remapped

; ** glyph definitions (note index above) **
cg_glph:
; ZX semi-graphs
; 129, ZX up rt
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000

; 130, ZX up lt
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000

; 131, ZX up
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000

; 132, ZX dn rt
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00111

; 133, ZX right
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100

; 134, ZX backslash
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00111

; 135, ZX neg dn lt
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00111

; 136, ZX dn lt
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100

; 137, ZX slash
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100

; 138, ZX left
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100

; 139, ZX neg dn rt
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100

; 140, ZX down
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111

; 141, ZX neg up lt
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%00111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111

; 142, ZX neg up rt
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11100
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111

; 143, ZX black
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111
	.byt	%11111

; differences between ISO 8859-1 & 8859-15 (SHY remapped to -)
; 164, Euro sign
	.byt	%00110
	.byt	%01001
	.byt	%11110
	.byt	%01000
	.byt	%11110
	.byt	%01001
	.byt	%00110
	.byt	%00000

; 168, diaeresis
	.byt	%00000
	.byt	%01010
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000

; 172, negation
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%11111
	.byt	%00001
	.byt	%00001
	.byt	%00000
	.byt	%00000

; 175, macron
	.byt	%11111
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000
	.byt	%00000

; 189, lower oe
	.byt	%00000
	.byt	%00000
	.byt	%01110
	.byt	%10101
	.byt	%10110
	.byt	%10100
	.byt	%01111
	.byt	%00000

#endif
.)
