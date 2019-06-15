; miniPET built-in VGA-compatible VDU for minimOS!
; v0.6a1
; (c) 2019 Carlos J. Santisteban
; last modified 20190615-1008

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

; debug only!
	va_mode	= $400		; *** *** *** DEBUGGING ONLY *** *** ***

; define SEPARATORS in order to use a shorter table by letting 28-31 as printable!
#define	SEPARATORS	_SEPARATORS

; *** zeropage variables ***
	v_dest	= $E8		; generic writes, was local2, perhaps including this on zeropage.h? aka ptc
	v_src	= $EA		; font read, is this OK? aka ptl

; do these need to be in zeropage?
	vs_mask	= $E4		; *** local 1, splash screen only ***
	vs_cnt	= $E5		; line counter

; ************************
; *** initialise stuff *** should create line addresses table...
; ************************
va_init:
; load 6845 CRTC registers
	LDX #10
vi_crl:
		STX crtc_rs			; select this register
		LDA va_data, X		; get value for it
		STA crtc_da			; set value
		DEX					; next address
		BPL vi_crl			; continue otherwise
; new, set RAM pointer to supplied font!
	LDA #<vs_font		; get supplied LSB (2) *** now using a RAM pointer
	STA va_font			; store locally (4)
	LDA #>vs_font		; same for MSB (2+4) *** ditto for flexibility
	STA va_font+1
; software cursor will be set by CLS routine!
;	CLC					; just in case there is no splash code
	JSR va_cls			; reuse code from Form Feed, but needs to return for the SPLASH screen!

; **************************
; *** splash screen code ***
; **************************

; ****************************
; *** end of splash screen ***
; ****************************
; if not used may just use CLC above and let it fall into CLS routine ***

	_DR_OK				; installation succeeded

; ***************************************
; *** routine for clearing the screen ***
; ***************************************
va_cls:					; * initial code takes 18t *
; should create the pointer array!
	LDY #<VA_BASE		; set home position... this is faster (2+2)
	LDA #>VA_BASE
	STY va_x			; reset coordinates (4+4)
	STY va_y
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
	STY v_dest			; clear pointer LSB, will stay this way (2)
	STA v_dest+1		; eeeeeeeeeeeeek (4)
	LDA #32				; ASCII for space (2)
vcl_c:					; * whole loop takes 36x(2559+18) = 92772t *
		STA (v_dest), Y		; set this byte (5)
		INY					; go for next (2+3)
		BNE vcl_c
			INC v_dest+1		; check following page eeeeeeeeek (5)
			LDX v_dest+1		; how far are we? (3) eeeeeeeeeeek
			CPX #$88			; already at VRAM? or suitable limit (2)
		BNE vcl_c			; no, do not change A (3)
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
	CMP va_hght			; over screen size?
	BCC vat_yok
		_DR_ERR(INVALID)	; ignore if outside range
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
		_DR_ERR(INVALID)	; ignore if outside range
vat_xok:
#endif
	STA va_x			; coordinates are set
	JSR vch_scs			; set cursor
		_BRA va_mbres		; reset flag and we are done

; -------------------------------- continue here ------------------------------------
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
; *** *** scroll DOWN code just 'reversed', please check throughfully! *** ***
		LDX va_bi			; current circular index
		CPX #va_hght-1
		BNE vs_xnz2			; not last one, no wrap
			LDX #$FF			; is this OK?
vs_xnz2:
		INX					; ...plus one, now points to first line pointer
; is the staff above really needed??
		LDA va_lpl, X		; get full value
		LDY va_lph, X
		DEX					; go previous in queue
		BPL vs_bnw2			; does it need to wrap? only OK up to 127 lines
			LDX #va_hght-1
vs_bnw2:
		SEC
		SBC va_wdth			; advance one line
		BCS vs_msb			; check for wrapping
			DEY
			CPY #>VA_BASE		; is it before the screen?
			BCS vs_msb2
				LDY #>VA_SCRL-1		; wrap it all!
vs_msb2:
		STA va_lpl, X		; store new entry
		TYA					; no STY abs, X...
		STA va_lph, X
		DEX					; backoff circular pointer
		BPL vs_biok2		; does it need to wrap? only OK up to 127 lines!
			LDX #va_hght-1
; *** *** end of reference code, this ends with new circular index at X *** ***
vs_biok2:
		JMP vs_biok			; set new circular index, update CRTC, etc.
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
	LDA va_font			; add to base... (4+2) *** now using a RAM pointer
	CLC
	ADC io_c			; ...the computed offset (3)
	STA v_src			; store locally (3)
	LDA va_font+1		; same for MSB (4+3) *** ditto for flexibility
	ADC io_c+1
;	DEC					; in case the font has no non-printable glyphs
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
		LDX va_bi			; current circular index
		BNE vs_xnz			; not first one, no wrap
			LDX va_hght			; get number of lines...
vs_xnz:
		DEX					; ...minus one, now points to last line pointer
		LDA va_lpl, X		; get full value
		LDY va_lph, X
		INX					; go next in queue
		CPX va_hght			; does it need to wrap?
		BCC vs_bnw
			LDX #0
vs_bnw:
		CLC
		ADC va_wdth			; advance one line
		BCC vs_msb			; check for wrapping
			INY
			CPY #>VA_SCRL		; did it even end the screen?
			BCC vs_msb
				LDY #>VA_BASE		; wrap it all!
vs_msb:
		STA va_lpl, X		; store new entry
		TYA					; no STY abs, X...
		STA va_lph, X
		INX					; advance circular pointer
		CPX va_hght			; does it need to wrap?
		BCC vs_biok
			LDX #0
vs_biok:
		STX va_bi			; correct base index, already at X
; set new base address on CRTC
		LDY va_lph, X		; get pointer, note order
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
	LDA va_lpl, X		; get base pointer for that row
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
	.word	vch_so		; EON,  inverse video
	.word	vch_si		; EOFF, true video
	.word	vch_dcx		; DLE,  disable next control char
	.word	vch_sc		; XON,  turn cursor on
	.word	vch_dcx		; INK,  set foreground colour (uses another char) *** NOT USED
	.word	vch_hc		; XOFF, turn cursor off
	.word	vch_dcx		; PAPR, set background colour (uses another char) *** NOT USED
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
	.word	vch_ink		; 18, take byte as FG colour *** NOT USED
	.word	vch_papr	; 20, take byte as BG colour *** NOT USED
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
	.byt 49		; 47		; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 6		; 4		; R3, HSYNC width
	.byt 31		; 32		; R4, vertical total chars - 1
	.byt 13		; 5		; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt 27		; 28		; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1

; *** glyphs ***
vs_font:
#include "fonts/8x16.s"
.)
