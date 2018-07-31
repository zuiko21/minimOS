; Hitachi LCD for minimOS
; v0.6a2
; (c) 2018 Carlos J. Santisteban
; last modified 20180731-1923

; new VIA-connected device ID is $10-17, will go into PB
; VIA bit functions (data goes thru PA)
; E	= PB0 (easier pulsing)
; RS	= PB1
; R/W	= PB2
; should it respect PB3? Just in case...

; ***********************
; *** minimOS headers ***
; ***********************
#include "../usual.h"

.(
; substitution for undefined chars
#define	SUBST	' '

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
	.word	lcd_shut	; shutdown procedure will disable display
	.word	lcd_text	; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
srs_info:
	.asc	"20x4 char LCD 0.6a1", 0

lcd_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	L_OTH	= %00001000	; bits to be kept, PB3 only
	L_NOTH	= %11110111	; required PB outputs (inverse of L_OTH)
	LCD_PB	= %00010000	; idle command E=0 (pulse PB0 via INC/DEC)
	LCD_RS	= %00010010	; set RS for printing & CG (PB1)
	LCD_RD	= %00010100	; read status from LCD (PB2)
	LCD_RM	= %00010110	; read DDRAM/CGRAM (PB2+PB1)

; size definitions for other size LCDs
	L_CHAR	= 20		; chars per line
	L_LINE	= 4		; lines

; glyph redefinition size
	num_glph	= cg_glph - cg_defs 
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
	_STZA nx_sub		; next free substitution entry (for intl support)
	_DR_OK			; succeeded

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
lcd_prn:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
lp_l:
		_PHY				; keep this
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		JSR lcd_char		; *** print one byte ***
			BCS lcd_exit		; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		DEC bl_siz			; one less to go
			BNE lp_l			; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ lcd_end			; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA lp_l
lcd_exit:
	PLA					; discard saved index
lcd_end:
	PLA					; get saved MSB...
	STA bl_ptr+1		; ...and restore it
lcd_rts:
	RTS					; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
lcd_char:
; first check whether control char or printable
	LDA io_c			; get char (3)
	CMP #' '			; printable? (2)
	BCS lcd_prn			; it is! skip further comparisons (3)
		CMP #FORMFEED		; clear screen?
		BNE lch_nff
			JMP lcd_cls			; clear and return!
lcd_nff:
		CMP #CR				; newline?
		BNE lch_ncr
			JMP lcd_cr			; scrolling perhaps
lcd_ncr:
		CMP #HTAB			; tab?
		BNE lch_ntb
			JMP lcd_tab			; advance cursor
lcd_ntb:
		CMP #BS				; backspace?
		BNE lch_nbs
			JMP lcd_bs			; delete last character
lcd_nbs:
/*
		CMP #14				; shift out?
		BNE lch_nso
			LDA #$FF			; mask for reverse video
			_BRA lcd_xor		; set mask and finish
vch_nso:
		CMP #15				; shift in?
		BNE lch_nsi
			LDA #$FF			; mask for true video
vso_xor:
			STA vdu_xor			; set new mask
			RTS					; all done for this setting
vdu_nsi:
*/
; non-printable neither accepted control, thus use substitution character
		LDA #SUBST			; unrecognised char
		STA io_c			; store as required
lcd_prn:
	JSR l_avail			; wait for LCD
; set up VIA for LCD print (RS)
	LDA VIA_U+IORB		; current PB (4)
	AND #L_OTH			; respect PB3 only (2)
	ORA #LCD_RS			; allow DDRAM write (2)
	STA VIA_U+IORB		; set mode... (4)
; send char at io_c
	LDA io_c			; get char
; *** *** should check here for special characters *** ***
; assuming ROM code A02!
; 128-143 are the ZX Spectrum graphics (16)
; 144-159 taken from CP437 @ $Ex, most coincide except 145, 150, 152 & 157 (4)
; other changes are 160, 164, 168, 172-175, 180, 184, 188-190 (12)
; thus 191 & up are OK
; 161-167, 169-171, 176-179, 181-183, 185 and up seem just like 8859-1
; 164 (€), 188-190 are defined but in minimOS come from 8859-15
	BPL lch_ok			; standard ASCII
		CMP #191			; higher chars like ISO-8859
	BCS lch_ok
; I think is best to use a LUT 128-190, zero means must be redefined
		AND #$7F			; supress MSb eeeeeek
		TAX					; index for LUT
		LDA isolut, X			; check code or redefine
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
		LDX #num_glph-1		; max index for definitions array (size is 30 currently, must be 32 or less)
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
		ASL					; fortunately 31×8 < 255!
		TAX					; index into glyph 'file'
		JSR l_busy			; wait for LCD
		LDA 

; 5) get substitution (128-135)
		LDX nx_sub			; first free entry...
		DEX				; ...minus 1...
		TXA				; ...is last used
		AND #7			; in case it wrapped
		ORA #128		; add bit 7 and we are done
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

; *** new line ***
lcd_cr:
	JSR l_busy		; ready for several commands
	_STZA lcd_x		; correct local coordinates
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
				LDA #LCD_RS		; will write
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
			LDA #LCD_RS		; will write
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
	ORA #%10000000	; set DDRAM address
	BNE l_issue		; issue command and return (no need for BRA)

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
	ORA #LCD_PB		; E=RS=0, ready for commands
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
	ORA #LCD_RD		; will read status
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

; LUT marking undefined chars
isolut:
	.byt	32,	0,	0,	0,	0,	0,	0,	0	; 128-143, ZX semigraphics, note 128 is just remapped to space
	.byt	0,	0,	0,	0,	0,	0,	0,	0
	.byt	144,	0,	146,	147,	148,	149,	0,	151	; 144-159, most like CP437 $Ex
	.byt	0,	153,	154,	155,	156,	0,	158,	159
	.byt	32,	161,	162	163,	0,	165,	166,	167	; note NBSP is just remapped to regular space
	.byt	0,	169,	170,	171,	0,	0,	0,	0
	.byt	176,	177,	178,	179,	0,	181,	182,	183
	.byt	0,	185,	186,	187,	0,	0,	0		; up to 190, rest is unchanged

; list of redefinitions (glyphs must be at 8×index)
cg_defs:
	.byt	129, 130, 131, 132, 133, 134, 135	; ZX graphics (128 is a space)
	.byt	136, 137, 138, 139, 140, 141, 142, 143
	.byt	145, 150, 152, 157			; selected math greek
	.byt	164, 168, 172, 173, 174, 175		; euro sign and other differences between ISO 8859-1 & -15
	.byt	180, 184, 188, 189, 190

; ** glyph definitions (note index above) **
cg_glph:
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

.)
