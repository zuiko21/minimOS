; Acapulco built-in 8 KiB VDU for minimOS!
; v0.6a14
; (c) 2019 Carlos J. Santisteban
; last modified 20190501-2340

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
	.asc	"Acapulco built-in VDU v0.6", 0

va_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	VA_BASE	= $6000		; standard VRAM for Acapulco
	VA_END	= $8000		; end of VRAM
	VA_COL	= $5C00		; standard colour RAM for Acapulco
	VA_SCRL	= VA_BASE+1024	; base plus 32x32 chars, 16-bit in case is needed
	VA_SCAN	= 8			; number of scanlines (pretty hardwired)

	crtc_rs	= $DFC0		; *** hardwired 6845 addresses on Acapulco ***
	crtc_da	= $DFC1

; debug only!
	va_mode	= $400		; *** *** *** DEBUGGING ONLY *** *** ***

; define SEPARATORS in order to use a shorter table by letting 28-31 as printable!
#define	SEPARATORS	_SEPARATORS

; *** zeropage variables ***
	v_dest	= $E8		; was local2, perhaps including this on zeropage.h? aka ptc
	v_src	= $EA		; is this OK? aka ptl
; do these need to be in zeropage?
	vs_mask	= $E4		; *** local 1, splash screen only ***
	vs_cnt	= $E5		; line counter

; ************************
; *** initialise stuff *** should create line addresses table...
; ************************
va_init:
; must set up CRTC first, depending on selected video mode!
	LDA va_mode			; get requested *** from firmware!
	AND #7				; filter relevant bits, up to 8 modes
	STA va_mode			; fix possible altered bits
	ASL					; each mode has 8-byte table (remaining bytes are common)
	ASL
	ASL
;	ASL
	TAY					; use as index
	LDX #0				; separate counter
; reset inverse video mask!
	STX va_xor			; clear mask is true video
; load 6845 CRTC registers
; assumes FW has already set the special 6345/3445 regs!
vi_crl:
		STX crtc_rs			; select this register
		LDA va_data, Y		; get value for it
		STA crtc_da			; set value
		INY					; next address
		INX
		CPX #8				; last register done? (remaining registers are common, no longer $10)
		BNE vi_crl			; continue otherwise
; new, common registers from separate table (13 bytes more of code, but saves 72 from tables!)
vi_cmr:
		STX crtc_rs			; select this register
		LDA va_cdat-8, X	; get COMMON value for it, note offset
		STA crtc_da			; set value
		INX					; next address, now single index
		CPX #12				; last register done?
		BNE vi_cmr			; continue otherwise
; new, must copy R1 and R6 into va_wdth and va_hght
	LDA va_data-2, Y		; Y is known to be base+8, thus -2 is R6
	LDX va_data-7, Y		; Y is known to be base+8, thus -7 is R1
	STA va_hght			; store convenient values
	STX va_wdth
; MUST create line pointers array... but when clearing screen!

; clear all VRAM!
; ...but preset standard colours before!
	LDA #$F0			; white paper, black ink
	STA va_attr			; this value will be used by CLS
; software cursor will be set by CLS routine!
;	CLC					; just in case there is no splash code
	JSR va_cls			; reuse code from Form Feed, but needs to return for the SPLASH screen!

; **************************
; *** splash screen code *** 86 bytes, 7033t (~4.58 ms @ 1.536 MHz)
; **************************
; initial code takes 27t
	LDA #7				; line counter (2+3)
	STA vs_cnt
	LDA #<VA_BASE		; LSB as is page-aligned (2)
	CLC					; prepare addition (2)
	ADC va_wdth		; add chars per line (4)
	SEC					; prepare subtraction (2)
	SBC vs_cnt			; set initial column (3)
	STA v_dest			; set LSB (3)
	LDX #>VA_BASE		; MSB too (2)
vs_nlin:
; row loop takes 8 times 46+column loop, minus one = 7006t
		STX v_dest+1		; will be updated on loop (3)
		STA v_src			; LSB for both ponters! (3)
		TXA					; get MSB back (2+2)
		SEC
		SBC #$4				; VRAM is 1k after colour RAM (2)
		STA v_src+1			; set this MSB (3)
		LDY #0				; reset horiz index (2)
vs_ncol:
; columns loop takes 239*n-1 (n=7...1) = 1672, 1433, 1194, 955, 716, 477, 238t (total 6685t)
			LDA va_cspl, Y		; set attribute for this position (4+5)
			STA (v_src), Y
			LDA #$FF			; initial mask (2+3)
			STA vs_mask
vs_nras:
; inner raster loop takes 26*8-1 = 207t
				LDA vs_mask			; get mask for this raster (3)
				STA (v_dest), Y		; put on VRAM (5)
				LDA v_dest+1		; update for next raster (3+2+2+3)
				CLC
				ADC #4
				STA v_dest+1
				LSR vs_mask			; mask for next raster (5)
				BNE vs_nras			; while some dots in it (3*)
			LDA v_dest+1		; back to original raster (3+2+2+3)
			SEC
			SBC #$20
			STA v_dest+1
			INY					; next column (2)
			CPY vs_cnt			; less than X? (3+3*)
			BCC vs_ncol
		TAX					; keep MSB eeeeeeek (2)
		LDA v_dest			; get old pointer (3)
		SEC					; add line length PLUS 1 (2)
		ADC va_wdth			; add chars per line (4+3)
		STA v_dest
		BCC vs_nc			; no carry (3*)
			INX					; check possible carry! (2)
vs_nc:
		DEC vs_cnt			; one less row to go (5+3*)
		BNE vs_nlin
; ****************************
; *** end of splash screen ***
; ****************************
; if not used may just use CLC above and let it fall into CLS routine ***

	_DR_OK				; installation succeeded

; ***************************************
; *** routine for clearing the screen *** takes about 60 ms @ 1.536 MHz
; ***************************************
va_cls:					; * initial code took 22t *
; should create the pointer array!
	LDX #>VA_BASE		; base address (2) assume page aligned!
	LDA #<VA_BASE		; actually 0!
	TAY				; reset index
	STY va_bi		; ...and circular base too...
	STY va_x		; ...plus coordinates as well
	STY va_y
va_clp:
		STA va_lpl, Y		; make LSB entry
		STA va_src		; fast buffer!
		TXA				; get and store MSB
		STA va_lph, Y
		LDA va_src		; retrieve value
		CLC
		ADC va_wdth		; add columns per line
		BCC vc_nm		; check whether wraps
			INX
vc_nm:
		INY				; next row
		CPY va_hght
		BNE va_clp
	LDY #<VA_BASE			; set home position... this is faster
	LDA #>VA_BASE
; must set this as start & cursor address!
	LDX #12				; CRTC screen start register, then comes cursor address (2)
vc_crs:					; * this loops takes 49t *
		STX crtc_rs
		STA crtc_da			; set MSB... (4+4)
		INX					; next register (2)
		STX crtc_rs
		STY crtc_da			; ...and LSB (4+4)
		INX					; try next value (2)
		CPX #16				; all done? (2+3 twice, minus 1)
		BNE vc_crs
; must clear not only VRAM, but attribute area too! * this is 12t *
	STY v_dest			; clear pointer LSB, will stay this way (3)
	SBC #>(VA_BASE-VA_COL)	; set MSB, C was set, A held MSB (2)
	STA v_dest+1		; eeeeeeeeeeeeek (4)
	LDA va_attr			; default colour value! (4)
; both areas (colour & VRAM) may be reset from a single loop!
vcl_c:					; * whole loop takes 36x(2559+18) = 92772t *
		STA (v_dest), Y		; set this byte (5)
		INY					; go for next (2+3)
		BNE vcl_c
	INC v_dest+1		; check following page eeeeeeeeek (5)
	LDX v_dest+1		; how far are we? (3) eeeeeeeeeeek
	CPX #>VA_BASE		; already at VRAM? or suitable limit (2)
	BNE vcl_l			; no, do not change A (3)
; assume VRAM goes just after attribute area, thus v_dest already pointing to VA_BASE
		TYA				; zero (on Y) is the standard clear value (2)
; otherwise, do LDA #0 and TAY
vcl_l:
	CPX #>VA_END			; whole screen done?
		BNE vcl_c			; if not, continue
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
	STA va_y			; set new value
	INC va_col			; flag expects second coordinate... routine pointer placed TWO bytes after!
	INC va_col
	RTS					; just wait for the next coordinate
; * * ...and then expects column byte, note it is now 25, no longer 24! * *
vch_atcl:
	SEC
	SBC #' '			; from space and beyond
; add X and set cursor...
	STA va_x				; coordinates are set
; **** TO DO
		_BRA va_mbres		; reset flag and we are done
; * * take byte as FG colour * *
vch_ink:
	AND #%00001111		; filter relevant bits
	STA va_col			; temporary flag use for storing colour!
	LDA va_attr			; get current colour
	AND #%11110000		; will respect current paper
		_BRA va_sfrb		; combine attributes and exit
; * * take byte as BG colour * * (vch_ink reuses some code)
vch_papr:
	AND #%00001111		; filter relevant bits
	ASL					; convert to paper code
	ASL
	ASL
	ASL
	STA va_col			; temporary flag use for storing colour!
	LDA va_attr			; get current colour
	AND #%00001111		; will respect current ink
va_sfrb:
	ORA va_col			; mix with (possibly shifted) new colour
	STA va_attr			; new definition
va_mbres:
	_STZA va_col		; clear flag and we are done
	RTS					; *** no need for DR_OK as BCS is not being used
; ** then check whether control char or printable **
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
; * * EON (inverse video) * *
vch_so:
	LDA #$FF			; mask for reverse video
	BNE vso_xor			; set mask and finish, no need for BRA
; * * EOF (true video) * * vch_so reuses some code
vch_si:
		LDA #0				; mask for true video eeeeeeeeeek
; common code for EON & EOFF
vso_xor:
	STA va_xor			; set new mask
	RTS					; all done for this setting *** no need for DR_OK as BCS is not being used
; * * XON (cursor on) * *
vch_sc:
	LDA #96				; value for visible cursor, slowly blinking
	BNE vc_set			; put this value on register, no need for BRA
; * * XOFF (cursor off) * * vch_sc reuses some code
vch_hc:
		LDA #32				; value for hidden cursor
; common code for XON & XOFF
vc_set:
	LDX #10				; CRTC cursor register
	STX crtc_rs			; select register...
	STA crtc_da			; ...and set data
	RTS					; all done for this setting
; * * HOME (without clearing) * *
va_home:
	_STZA va_y ; reset row... and fall into HOML
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
; otherwise, scroll up... *** TO DO *** TO DO *** TO DO ***
		RTS				; temporarily do nothing
vcu_nt:
	DEC va_y			; one row up
	JMP vch_scs			; update cursor and exit (already checked for scrolling, may skip that)
; * * request for extra bytes * *
vch_dcx:
	STA va_col			; set flag if any colour or coordinate is to be set
	RTS					; all done for this setting *** no need for DR_OK as BCS is not being used
; * * direct glyph printing (was above) * * should be close to actual printing
vch_dle:				; * process byte as glyph *
	_STZA va_col		; ...but reset flag! eeeeeeeek
		_BRA vch_prn		; NMOS might use BEQ instead, but not for CMOS!
; * * non-printable neither accepted control, thus use substitution character * *
vch_npr:
	LDA #'?'			; unrecognised char
	STA io_c			; store as required
; **** actual printing ****
; *** convert ASCII into pointer offset, needs 11 bits ***
vch_prn:
	_STZA io_c+1		; clear MSB (3)
	LDX #3				; will shift 3 bits left (2)
vch_sh:
		ASL io_c			; shift left (5+5)
		ROL io_c+1
		DEX					; next shift (2+3)
		BNE vch_sh
; add offset to font base address
	LDA #<va_font		; add to base... (2+2) *** might use a RAM pointer
	CLC
	ADC io_c			; ...the computed offset (3)
	STA v_src			; store locally (3)
	LDA #>va_font		; same for MSB (2+3) *** ditto for flexibility
	ADC io_c+1
;	_DEC				; in case the font has no non-printable glyphs
	STA v_src+1			; is source pointer (3)
; create local destination pointer
	LDA va_y			; current absolute row
	CLC
	ADC va_bi			; actual position in circular array
	CMP va_hght			; check for wrapping
	BCC va_nwbi
		SBC va_hght
va_nwbi:
	TAX					; use as index
	LDA va_lpl, X			; get base pointer for that row
	LDY va_lph, X
	CLC
	ADC va_x			; and now add column offset
	STA v_dest			; will be destination pointer (3+3)
	STY v_dest+1
; copy from font (+1...) to VRAM (+1024...)
	LDY #0				; scanline counter (2)
vch_pl:
		LDA (v_src), Y		; get glyph data (5)
		EOR va_xor			; apply mask! (4)
		_STAX(v_dest)		; store into VRAM (5) do not mess with Y
; advance to next scanline
		LDA v_dest+1		; get current MSB (3+2)
		CLC
		ADC #4				; offset for next scanline is 1024 (2)
; *** *** is checking for wrap needed? *** ***
		STA v_dest+1		; update (3)
		INY					; next font byte (2)
		CPY #VA_SCAN		; all done? (2)
		BNE vch_pl			; continue otherwise (3)
; now must set attribute accordingly!
	SEC					; subtract 8192+1024 from v_dest (MSB already in A)
	SBC #36
vch_nw:
	STA v_dest+1		; now it should be pointing to the corresponding attribute
	LDA va_attr			; get preset colour...
	_STAX(v_dest)		; ...and place it eeeeeeeeeek
; printing is done, now advance current position
	JMP vch_rght		; *** this is actually cursor right! ***
vch_scs:
; check whether scrolling is needed *** RECOMPUTE USING TABLE
; it is assumed that only UPCU may issue a scroll up, thus not checked here
	LDA va_y		; actual row
	CMP va_hght		; over last line?
	BNE vch_ok		; no, just exit (3/2)
; scroll is needed, must update pointer array and base index
; *** *** *** TO DO *** *** ***
; set new base address on CRTC
		LDX va_bi			; where is the new start address?
		LDY va_lph, X			; get pointer, note order
		LDA va_lpl, X
; set CRTC registers, note MSB is on Y and LSB on A!
		LDX #12				; start_h register on CRTC (2)
		STX crtc_rs			; select register
		STY crtc_da			; ...and set data MSB
; go for next reg
		INX					; next reg (2)
		STX crtc_rs			; select register
		STA crtc_da			; ...and set data LSB
vch_ok:
; set cursor position from separate coordinates, might be inlined
; access to circular array is worth a subroutine?
	LDA va_y			; current absolute row
	CLC
	ADC va_bi			; actual position in circular array
	CMP va_hght			; check for wrapping
	BCC vsc_nwbi
		SBC va_hght
vsc_nwbi:
	TAX					; use as index
	LDA va_lpl, X			; get base pointer for that row
	LDY va_lph, X
	CLC
	ADC va_x			; and now add column offset
	BCC vsc_cok			; eeeeeeek
		INY
vsc_cok:
; set CRTC registers, note MSB is on Y and LSB on A! worth another?
	LDX #14				; cur_h register on CRTC (2)
	STX crtc_rs			; select register
	STY crtc_da			; ...and set data MSB
; go for next
	INX					; next reg (2)
	STX crtc_rs			; select register
	STA crtc_da			; ...and set data LSB
	_DR_OK

; **** several printing features ****
; *** carriage return ***
va_cr:
	INC va_y		; line feed...
	JMP vch_homl		; ...and finish with simple CR

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
	.word	va_npr		; BELL, should make something conspicuous***
	.word	va_bs		; BKSP, backspace
	.word	va_tab		; HTAB, move to next tab column
	.word	vch_down	; DOWN, move cursor
	.word	vch_up		; UPCU, move cursor
	.word	va_cls		; FORM, clear screen
	.word	va_cr		; NEWL, new line
	.word	vch_so		; EON,  inverse video
	.word	vch_si		; EOFF, true video
	.word	vch_dcx		; DLE,  disable next control char
	.word	vch_sc		; XON,  turn cursor on
	.word	vch_dcx		; INK,  set foreground colour (uses another char)
	.word	vch_hc		; XOFF, turn cursor off
	.word	vch_dcx		; PAPR, set background colour (uses another char)
	.word	va_home		; HOME, move cursor to top left without clearing
	.word	va_cls		; PGDN, page down, may issue a FF
	.word	vch_dcx		; ATYX, takes two more chars!
	.word	vch_npr		; BKTB, no direct effect on screen
	.word	vch_npr		; PGUP, no direct effect on screen
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
	.word	vch_dle		; process byte as glyph
	.word	vch_ink		; take byte as FG colour
	.word	vch_papr	; take byte as BG colour
	.byt	$FF			; *** padding as ATYX is 23, not 22 ***
	.word	vch_atyx	; expects row byte
	.word	vch_atcl	; expects column byte, note it is now 25, no longer 24!

va_cspl:
; splash screen attributes table (ink on upper right)
	.byt	%11111110	; yellow on white
	.byt	%11101011	; cyan on yellow
	.byt	%10111010	; green on cyan
	.byt	%10100101	; magenta on green
	.byt	%01010100	; red on magenta
	.byt	%01000001	; blue on red
	.byt	%00010000	; black on blue

; va_width array no longer used

va_cdat:
; new, common values for CRTC registers in ALL modes
	.byt $50			; R8, interlaced mode AND 1 ch. skew
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
; start & cursor addresses (R12...R15) to be set by CLS

va_data:
; CRTC registers initial values (only those which differ on each mode)
; total of eight video modes

; *** values for 25.175 MHz dot clock *** 31.47 kHz Hsync, 59.94 Hz Vsync
; unlikely to work on 24.576 MHz crystal (30.72 kHz Hsync, 58.5 Hz Vsync)
; mode 0 (aka 40/50) is 320x200 (40x25) 1-6-3, *** industry standard ***
	.byt 49				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt 26				; R7, VSYNC position - 1

; mode 1 (aka 36/50) is 288x224 (36x28) 1-6-3, fully compatible
	.byt 49				; R0, horizontal total chars - 1
	.byt 36				; R1, horizontal displayed chars
	.byt 39				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 28				; R6, vertical displayed chars
	.byt 28				; R7, VSYNC position - 1

; mode 2 (aka 32/50) is 256x240 (32x30) 1-6-3, fully compatible
	.byt 49				; R0, horizontal total chars - 1
	.byt 32				; R1, horizontal displayed chars
	.byt 37				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 30				; R6, vertical displayed chars
	.byt 30				; R7, VSYNC position - 1

; *** values for 24.576 MHz dot clock *** 32 kHz Hsync, 60.95 Hz Vsync
; mode 3 (aka 40/48S) is 320x200 (40x25) 1-6-1, 3.9uS sync, 650nS back porch (perhaps compatible)
	.byt 47				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt 26				; R7, VSYNC position - 1

; mode 4 (aka 40/48P) is 320x200 (40x25) 1-4-3, 2.6uS sync, 1.95uS back porch (likely compatible)
	.byt 47				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 36				; R3, HSYNC width (may have VSYNC in MSN) =4
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt 26				; R7, VSYNC position - 1

; mode 5 (aka 36/48) is 288x224 (36x28) 1-6-3, most likely compatible
	.byt 47				; R0, horizontal total chars - 1
	.byt 36				; R1, horizontal displayed chars
	.byt 39				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 28				; R6, vertical displayed chars
	.byt 28				; R7, VSYNC position - 1

; mode 6 (aka 32/48) is 256x240 (32x30) 1-6-3, most likely compatible
	.byt 47				; R0, horizontal total chars - 1
	.byt 32				; R1, horizontal displayed chars
	.byt 37				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 30				; R6, vertical displayed chars
	.byt 30				; R7, VSYNC position - 1

; mode 7 (aka 40/48T) is 320x200 (40x25) 1-5-2, 3.25uS sync, 1.3uS back porch (most likely compatible)
	.byt 47				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 37				; R3, HSYNC width (may have VSYNC in MSN) =5
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt 26				; R7, VSYNC position - 1

; *** glyphs ***
va_font:
#include "fonts/8x8.s"
.)
