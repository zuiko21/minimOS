; miniPET built-in VGA-compatible VDU for minimOS!
; v0.6a3
; (c) 2019 Carlos J. Santisteban
; last modified 20190629-1722

#include "../usual.h"

; this for debugging only!
#include "vdu-aca.h"

; ***********************
; *** minimOS headers ***
; ***********************
.(
; *** begins with sub-function addresses table ***
	.byt	192			; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	va_err		; does not read
	.word	va_prn		; print N characters
	.word	va_init		; initialise device
	.word	va_rts		; no periodic interrupt, thus...
	.word	0			; frequency makes no sense
	.word	va_err		; D_ASYN does nothing
	.word	va_err		; no config
	.word	va_err		; no status
	.word	va_rts		; shutdown procedure does nothing
	.word	va_text		; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
va_text:
	.asc	"miniPET built-in VDU v0.6", 0

va_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	VP_BASE	= $8000		; standard VRAM for miniPET

	crtc_rs	= $E880		; *** hardwired 6845 addresses on miniPET ***
	crtc_da	= $E881

; define SEPARATORS in order to use a shorter table by letting 28-31 as printable!
#define	SEPARATORS	_SEPARATORS

; define INVERSE7 in order to allow inverse video when bit 7 is set
#define	INVERSE7	_INVERSE7

; *** zeropage variables ***
	v_dest	= $E8		; generic writes, was local2, perhaps including this on zeropage.h? aka ptc
	v_src	= $EA		; for scroll only

; ************************
; *** initialise stuff *** should create line addresses table...
; ************************
va_init:
; must check for VRAM mirroring, for 40/80 col. auto-detecting
; should work on a real PET, too!
	LDA #80				; max columns
	STA $87FF			; 80-col-only address
	LSR					; half value (40 col)
	STA $83FF			; end of 40 col screen
	LDA $87FF			; this is either 80-col screen, or a mirror of the above (in 40-col mode)
	STA va_wdth			; this is the actual screen width
; load 6845 CRTC registers
	LDX #13
vi_crl:
		STX crtc_rs			; select this register
		LDA va_data, X		; get value for it
		STA crtc_da			; set value
		DEX					; next address
		BPL vi_crl			; continue otherwise
	LDA #192			; cursor is visible by default
	STA va_cur
;	CLC					; just in case there is no splash code
	JSR va_cls			; reuse code from Form Feed, but needs to return for the SPLASH screen!

; **************************
; *** splash screen code ***
; **************************

; ****************************
; *** end of splash screen ***
; ****************************
; if not used may just do CLC above and let it fall into CLS routine ***

	_DR_OK				; installation succeeded

; ***************************************
; *** routine for clearing the screen ***
; ***************************************
va_cls:					; * initial code takes 18t *
	LDY #<VP_BASE		; set home position... must be zero (2)
	STY va_x			; reset coordinates (4+4)
	STY va_y
	STY va_xor			; reset inverse mode too (4)
; must clear VRAM
	LDA #>VP_BASE
	STY v_dest			; clear pointer LSB, will stay this way (2)
	STA v_dest+1		; eeeeeeeeeeeeek (4)
; better set proper limit depending on columns
	JSR va_vlim
; ready to clear VRAM
	LDA #32				; ASCII for space (2)
vcl_c:					; * whole loop takes 36x(2559+18) = 92772t *
		STA (v_dest), Y		; set this byte (5)
		INY					; go for next (2+3)
		BNE vcl_c
			INC v_dest+1		; check following page eeeeeeeeek (5)
			LDX v_dest+1		; how far are we? (3) eeeeeeeeeeek
			CPX va_col			; finished? (4)
		BNE vcl_c			; no, continue (3)
	STY va_col			; reset flag too EEEEEEEK
	RTS

; *** compute temporary VRAM limit***
va_vlim:
	LDA va_wdth		; read %00101000 or %01010000
	LSR					; %00010100 or %00101000
	LSR					; %00001010 or %00010100
	SEC					; will set bit 7!
	LSR					; %10000101 or %10001010
	AND #%11111100				; %10000100 or %10001000
	STA va_col			; temporary limit is $84 or $88
	RTS

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
va_prn:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
vp_l:
		_PHY				; keep this
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		JSR va_char			; *** print one byte *** might be inlined
;			BCS va_exit			; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		DEC bl_siz			; one less to go
			BNE vp_l			; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ va_end			; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA vp_l
va_exit:
	PLA					; discard saved index
va_end:
	PLA					; get saved MSB...
	STA bl_ptr+1		; ...and restore it
va_rts:
	RTS					; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
va_char:
	LDA io_c			; get char (3)
; ** first of all, check whether was waiting for an extra byte (or two) **
	LDX va_col			; something being set?
	BEQ va_nbin			; if not, continue with regular code
		_JMPX(va_xtb-16)	; otherwise process accordingly (using another table, note offset)

; *** *** much closer control code, may be elsewhere *** ***
; * * expects row byte... * *
vch_atyx:
	SEC
	SBC #' '			; from space and beyond
; compute new Y pointer...
#ifdef	SAFE
	CMP #25			; over screen heigth?
	BCC vat_yok
		LDA #24		; stay at limit if outside range
vat_yok:
#endif
	STA va_y			; set new value
	INC va_col			; flag expects second coordinate... routine pointer placed TWO bytes after!
	INC va_col
	_DR_OK				; just wait for the next coordinate

; * * ...and then expects column byte, note it is now 25, no longer 24! * *
vch_atcl:
	SEC
	SBC #' '			; from space and beyond
; add X and set cursor...
#ifdef	SAFE
	CMP va_wdth			; over screen size?
	BCC vat_xok
		LDA #va_wdth-1		; stay at limit if outside range
vat_xok:
#endif
	STA va_x			; coordinates are set
	JSR vch_scs			; set cursor
		_BRA va_mbres		; reset flag and we are done

; * * colours are simply ignored * *
; ...or let INK 0 set global inverse and PAPER 0 reset it!
vch_ink:
	TAX					; check whether zero
	BNE vch_cend		; no, nothing to do
		LDA #$10			; yes, set TA12
		BNE vch_sinv
vch_papr:
	TAX					; check whether zero
	BNE vch_cend		; no, nothing to do, otherwise clear TA12, A is already zero
vch_sinv:
		STA va_col			; keep temporary mask
		LDX #12				; CRTC start address MSB
		STX crtc_rs			; select register
		LDA crtc_da			; get current data...
		AND #%11101111			; ...mask out invert bit...
		ORA va_col			; ...and set desired bit
		STA crtc_da
vch_cend:
	_STZA va_col		; clear flag and we are done
	RTS					; *** no need for DR_OK as BCS is not being used

; ** check whether control char or printable **
va_nbin:
#ifdef	SEPARATORS
	CMP #28				; from this one, all printable!
#else
	CMP #' '			; printable? (2)
#endif
		BCS vch_prn			; it is! skip further comparisons (3)
; **** identify possible control codes ****
	ASL					; character code times two
	TAX					; is now an index
		_JMPX(va_c0)		; new, operate according to C0 code table

; *** *** much closer control routines, can be placed anywhere *** ***
#ifdef	INVERSE7
; * * EON (inverse video) * *
vch_so:
	LDA #$80			; mask for reverse video
	BNE vso_xor			; set mask and finish, no need for BRA
; * * EOFF (true video) * * vch_so reuses some code
vch_si:
		LDA #0				; mask for true video eeeeeeeeeek
; common code for EON & EOFF
vso_xor:
	STA va_xor			; set new mask
	RTS					; all done for this setting *** no need for DR_OK as BCS is not being used
#endif

; * * XON (cursor on) * *
vch_sc:
; PET hardware does not use 6845 cursor
	LDA #192			; value for visible cursor
	BNE vc_set			; put this value on register, no need for BRA

; * * XOFF (cursor off) * * vch_sc reuses some code
vch_hc:
		LDA #0				; value for hidden cursor
; common code for XON & XOFF
vc_set:
; should just set some software flag
	STA va_cur			; 0 means no cursor, %10000000 means cursor on but not showing, %11000000 is showing cursor
	RTS					; all done for this setting

; * * HOME (without clearing) * *
va_home:
	_STZA va_y			; reset row... and fall into HOML

; * * HOML (CR without LF) * *
va_homl:
	_STZA va_x			; just reset column
	_BRA va_rtnw			; update cursor and exit

; * * cursor left * *
vch_left:
	LDX va_x			; check whether at leftmost column
	BNE vcl_nl			; no, proceed
		RTS				; yes, simply ignore!
vcl_nl:
	DEC va_x			; previous column
	_BRA va_rtnw			; standard end

; * * cursor right * * also used by normal printing
vch_rght:
	INC va_x			; point to following column
	CMP va_wdth			; over line length?
	BNE va_rtnw
		_STZX va_x			; if so, back to left...
; ...and fall into cursor down!

; * * cursor down * *
vch_down:
		INC va_y			; advance row
va_rtnw:				; **** common exit point ***
	JMP vch_scs			; update cursor and exit

; * * cursor up * *
; this is expected to be much longer, as may need to scroll up!
vch_up:
	LDX va_y			; check if already at top
	BNE vcu_nt			; no, just update coordinate
; otherwise, scroll up...


vcu_nt:
	DEC va_y			; one row up
	JMP vch_scs			; update cursor and exit (already checked for scrolling, may skip that)

; * * request for extra bytes * *
vch_dcx:
	STA va_col			; set flag if any colour or coordinate is to be set
	RTS					; all done for this setting *** no need for DR_OK as BCS is not being used

; * * direct glyph printing (was above) * * should be close to actual printing
vch_dle:				; * process byte as glyph *
	_STZX va_col		; ...but reset flag! eeeeeeeek^2
		_BRA vch_prn		; NMOS might use BEQ instead, but not for CMOS!

; * * non-printable neither accepted control, thus use substitution character * *
vch_npr:
	LDA #'?'			; unrecognised char
	STA io_c			; store as required

; **** actual printing ****
vch_prn:
	PHA
; create local destination pointer
	_STZA v_dest+1			; pointer MSB
	LDA va_y			; current absolute row
	ASL
	ASL
	ASL				; times 8
	STA v_dest			; temporary
	ASL
	ROL v_dest+1
	ASL
	ROL v_dest+1			; times 32... and C is clear
	ADC v_dest			; row x 40, C should stay clear
	STA v_dest			; LSB OK
	LDA v_dest+1
	ADC #>VP_BASE			; actual address
	STA v_dest+1			; pointer ready!
; put char on VRAM
	PLA
#ifdef	INVERSE7
	EOR va_xor			; apply mask! may double invert (4)
#endif
	LDY va_x			; column offset
	STA (v_dest), Y
; printing is done, now advance current position
	JMP vch_rght		; *** this is actually cursor right! ***
vch_scs:
; check whether scrolling is needed
; it is assumed that only UPCU may issue a scroll up, thus not checked here
	LDA va_y		; actual row
	CMP #25			; over last line?
	BNE vch_ok		; no, just exit (3/2)
; scroll is needed
		JSR va_vlim		; should compute limit...
		LDX #>VP_BASE		; base address (for destination)
		LDA #<VP_BASE
		TAY					; expected 0!
		STX v_dest+1		; set pointers MSB
		STX v_src+1
		STA v_dest		; destination LSB
		CLC
		ADC va_wdth		; source is one line after
		STA v_src
vs_loop:
			LDA (v_src), Y		; get source data
			STA (v_dest), Y		; ...into destination
			INY
			BNE vs_loop
				INC v_dest+1		; next page
				INC v_src+1
				LDA v_dest+1		; over limit?
				CMP va_col
			BNE vs_loop
; scroll is done but must clear last line ** TO DO **

vch_ok:
	_DR_OK

; **** several printing features ****
; *** carriage return ***
va_cr:
	INC va_y		; line feed...
	JMP va_homl		; ...and finish with simple CR

; *** tab (8 spaces) ***
va_tab:
	LDA va_x			; get column (4)
	AND #%11111000		; modulo 8 (2+2)
	CLC
	ADC #8				; increment target position (2)
	CMP va_wdth			; over the limit?
	BCC vtb_l
		LDA #0
vtb_l:
		PHA					; save desired position (3)
		LDA #' '			; will print spaces (2+3)
		STA io_c
		JSR vch_prn			; direct space printing, A holds 32 too (...)
		PLA					; retrieve target column (4)
		CMP va_x			; reached? (4)
		BNE vtb_l			; no, continue (3/2)
	_DR_OK				; yes, all done

; *** backspace ***
va_bs:
; first get cursor one position back...
	JSR vch_left			; standard
; ...then print a space, the regular way...
	LDA #' '			; code of space (2)
	STA io_c			; store as single char... (3)
	JSR va_prn			; print whatever is in io_c (...)
; ...and back again!
	JMP vch_left			; will return

; ********************
; *** several data ***
; ********************

va_c0:
; new C0 codes managament table
	.word	vch_npr		; NULL, not accepted... or might just generate a NEWL
	.word	va_homl		; HOML, CR without LF
	.word	vch_left	; LEFT, move cursor
	.word	vch_npr		; TERM, does not affect screen
	.word	va_cls		; ENDT, end of text, may just issue a FF
	.word	vch_npr		; ENDL, not accepted... or might just put cursor at the rightmost column
	.word	vch_rght	; RGHT, move cursor
	.word	vch_npr		; BELL, should make something conspicuous***
	.word	va_bs		; BKSP, backspace
	.word	va_tab		; HTAB, move to next tab column
	.word	vch_down	; DOWN, move cursor
	.word	vch_up		; UPCU, move cursor
	.word	va_cls		; FORM, clear screen
	.word	va_cr		; NEWL, new line
#ifdef	INVERSE7
	.word	vch_so		; EON,  inverse video
	.word	vch_si		; EOFF, true video
#else
	.word	va_rts		; no inverse video on full 8-bit
	.word	va_rts
#endif
	.word	vch_dcx		; DLE,  disable next control char
	.word	vch_sc		; XON,  turn cursor on
	.word	vch_dcx		; INK,  set foreground colour (uses another char, 0 for global inverse)
	.word	vch_hc		; XOFF, turn cursor off
	.word	vch_dcx		; PAPR, set background colour (uses another char, 0 disables global inverse)
	.word	va_home		; HOME, move cursor to top left without clearing
	.word	va_cls		; PGDN, page down, may issue a FF
	.word	vch_dcx		; ATYX, takes two more chars!
; further savings can be done if these left printed anyway!
	.word	vch_npr		; BKTB, no direct effect on screen
	.word	vch_npr		; PGUP, no direct effect on screen, might do CLS anyway
	.word	vch_npr		; STOP, no effect on screen
	.word	vch_npr		; ESC,  no effect on screen (this far!)
; here come the ASCII separators, might be left printed anyway, saving 8 bytes from the table
#ifndef	SEPARATORS
	.word	vch_npr		; FS,   no effect on screen or just print the glyph
	.word	vch_npr		; GS,   no effect on screen or just print the glyph
	.word	vch_npr		; RS,   no effect on screen or just print the glyph
	.word	vch_npr		; US,   no effect on screen or just print the glyph
#endif

va_xtb:
; new table for extra-byte codes
; note offset as managed X codes are 16, 18, 20 and 23, thus padding byte
	.word	vch_dle		; 16, process byte as glyph
	.word	vch_ink		; 18, take byte as FG colour *** global inverse only
	.word	vch_papr	; 20, take byte as BG colour *** glonal inverse only
	.byt	$FF			; *** padding as ATYX is 23, not 22 ***
	.word	vch_atyx	; 23, expects row byte
	.word	vch_atcl	; 25, expects column byte, note it is no longer 24!


va_data:
; CRTC registers initial values
; cursor raster & blink (R10, R11) to be reset (as not used) by CLS
; start & cursor addresses (R12...R15) to be set by CLS

; *** values for 25.175 MHz dot clock *** 31.47 kHz Hsync, 59.94 Hz Vsync
; unlikely to work on 24.576 MHz crystal (30.72 kHz Hsync, 58.5 Hz Vsync)
; alternate commented values for 24.576 MHz crystal (32 kHz Hsync, 60.04 Hz VSync)
	.byt 49		; 47	; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 6		; 3		; R3, HSYNC width
	.byt 31		; 32	; R4, vertical total chars - 1
	.byt 13		; 5		; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt 27		; 28	; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.word 0				; R10-R11, cursor raster and blink *** NOT USED ***
	.byt 0				; R12-R13, BE start address (use 32 on full ASCII mode)
	.byt 0				; (R14-R15 irrelevant on this hardware)

; *** no glyphs! ***
.)
