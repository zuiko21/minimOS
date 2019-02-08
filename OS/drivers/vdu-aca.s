; Acapulco built-in 8 KiB VDU for minimOS!
; v0.6a3
; (c) 2019 Carlos J. Santisteban
; last modified 20190208-1015

; *** TO BE DONE *** TO BE DONE *** TO BE DONE *** TO BE DONE *** TO BE DONE ***

; ***********************
; *** minimOS headers ***
; ***********************
#include "../usual.h"

.(
; *** begins with sub-function addresses table ***
	.byt	192			; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	va_err		; does not read
	.word	va_prn		; print N characters
	.word	va_init		; initialise 'device', called by POST only
	.word	va_rts		; no periodic interrupt
	.word	0			; frequency makes no sense
	.word	va_err		; D_ASYN does nothing
	.word	va_err		; no config
	.word	va_err		; no status
	.word	va_rts		; shutdown procedure does nothing
	.word	va_text		; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
srs_info:
	.asc	"Acapulco built-in VDU v0.6", 0

va_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	VA_BASE	= $6000		; standard VRAM for Acapulco
	VA_COL	= $5C00		; standard colour RAM for Acapulco
	VA_SCRL	= VA_BASE+1024	; base plus 32x32 chars, 16-bit in case is needed
	VA_SCAN	= 8			; number of scanlines (pretty hardwired)

	crtc_rs	= $DFC0		; *** hardwired 6845 addresses on Acapulco ***
	crtc_da	= $DFC1
; *** TO BE DONE *** TO BE DONE *** TO BE DONE *** TO BE DONE *** TO BE DONE ***

; *** zeropage variables ***
	v_dest	= $E8		; was local2, perhaps including this on zeropage.h?
	v_src	= $EA		; is this OK?

; ************************
; *** initialise stuff ***
; ************************
va_init:
; must set up CRTC first, depending on selected video mode!
	LDA va_mode			; get requested *** from firmware!
	AND #7				; filter relevant bits, up to 8 modes
	STA va_mode			; fix possible altered bits
	ASL					; each mode has 16-byte table
	ASL
	ASL
	ASL
	TAY					; use as index
	LDX #0				; separate counter
; reset inverse video mask!
	STX va_xor			; clear mask is true video
; load CRTC registers
vi_crl:
		STX crtc_rst		; select this register
		LDA va_data, Y		; get value for it
		STA crtc_da			; set value
		INY					; next address
		INX
		CPX #$10			; last register done?
		BNE vi_crl			; continue otherwise
; clear all VRAM!
; ...but preset standard colours before!
	LDA #$F0			; white paper, black ink
	STA va_attr			; this value will be used by CLS
; software cursor will be set by CLS routine!
	CLC					; just in case...
;	JMP va_cls			; reuse code from Form Feed, will return to caller

; ***************************************
; *** routine for clearing the screen *** takes 92526, 60 ms @ 1.536 MHz
; ***************************************
va_cls:					; * initial code takes 22t *
	LDA #>VA_BASE		; base address (2+2) assume page aligned!
	LDY #<VA_BASE		; actually 0!
	STY va_ba			; set standard start point (4+4)
	STA va_ba+1
	STY va_cur			; ...and restore home position (4+4)
	STA va_cur+1
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
; new, preset scrolling limit * takes 10t *
	LDA #>VA_SCRL		; original limit, will wrap around this constant (2)
	STA va_sch+1		; set new var (4)
	_STZA va_sch		; VRAM is page-aligned! (4)
; must clear not only VRAM, but attribute area too! * optimum init is 13t *
;	LDY #0				; assume <VA_COL is zero (2) should be if both this and VA_BASE are page-aligned
	STY v_dest			; clear pointer LSB, will stay this way (3)
	LDA #>VA_COL		; set MSB (2)
	STA v_dest+1		; eeeeeeeeeeeeek (4)
	LDA va_attr			; default colour value! (4)
vcl_c:					; * whole loop takes 4x(2559+13)-1+2 = 10289t *
		STA (v_dest), Y		; set this byte (5)
		INY					; go for next (2+3)
		BNE vcl_c
	INC v_dest+1		; check following page eeeeeeeeek (5)
	LDA v_dest+1		; how far are we? (3)
	CMP #>VA_BASE		; already at VRAM? or suitable limit (2)
		BNE vcl_c			; no, still to go (3)
; assume VRAM goes just after attribute area, thus v_dest already pointing to VA_BASE
	TYA				; zero (on Y) is the standard clear value (2)
; otherwise, do LDA #0 and TAY * whole loop takes 32x(2559+8)-1 = 82143t *
vcl_l:
		STA (v_dest), Y		; clear byte (5)
		INY
		BNE vcl_l			; finish page (2+3)
	INC v_dest+1		; next page (5)
		BPL vcl_l			; this assumes screen ends at $8000! (3)
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
; ** first of all, check whether was waiting for a colour code **
	LDX va_col			; setting some colour?
		BNE va_scol			; if not, continue with regular code
; ** then check whether control char or printable **
	CMP #' '			; printable? (2)
	BCS vch_prn			; it is! skip further comparisons (3)
; otherwise check control codes
		CMP #FORMFEED		; clear screen?
		BNE vch_nff
			JMP va_cls			; clear and return!
vch_nff:
		CMP #CR				; newline?
		BNE vch_ncr
			JMP va_cr			; modify pointers (scrolling perhaps) and return
vch_ncr:
		CMP #HTAB			; tab?
		BNE vch_ntb
			JMP va_tab			; advance cursor
vch_ntb:
		CMP #BS				; backspace?
		BNE vch_nbs
			JMP va_bs			; deleta last character
vch_nbs:
		CMP #14				; shift out?
		BNE vch_nso
			LDA #$FF			; mask for reverse video
			_BRA vso_xor		; set mask and finish
vch_nso:
		CMP #15				; shift in?
		BNE vch_nsi
			LDA #0				; mask for true video eeeeeeeeeek
vso_xor:
			STA va_xor			; set new mask
			RTS					; all done for this setting *** no need for DR_OK as BCS is not being used
vch_nsi:
		CMP #18				; DC1? (set INK)
			BEQ vch_dcx			; set proper flag
		CMP #20				; DC3? (set PAPER)
		BNE vch_npr			; *** no more control codes ***
vch_dcx:
			STA va_col			; set flag if any colour is to be set
			RTS					; all done for this setting *** no need for DR_OK as BCS is not being used
; ** set pending colour code **
va_scol:
	AND #%00001111		; filter relevant bits
	STA va_col			; temporary flag use for storing colour!
	LDA va_attr			; get current colour
	CPX #20				; is it DC3 (PAPER)?
	BNE va_sink			; assume INK otherwise
		ASL va_col			; convert to paper code
		ASL va_col
		ASL va_col
		ASL va_col
		AND #%00001111		; will respect current ink
		_BRA va_spap
va_sink:
	AND #%11110000		; will respect current paper
va_spap:
	ORA va_col			; mix with (possible shifted) new colour
	STA va_attr			; new definition
	_STZA va_col		; clear flag and we are done
	RTS					; *** no need for DR_OK as BCS is not being used
; *** non-printable neither accepted control, thus use substitution character ***
vch_npr:
		LDA #'?'			; unrecognised char
		STA io_c			; store as required
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
	LDA #<va_font		; add to base... (2+2)
	CLC
	ADC io_c			; ...the computed offset (3)
	STA v_src			; store locally (3)
	LDA #>va_font		; same for MSB (2+3)
	ADC io_c+1
;	_DEC				; in case the font has no non-printable glyphs
	STA v_src+1			; is source pointer (3)
; create local destination pointer
	LDY va_cur			; get current position (4+4)
	LDA va_cur+1
	STY v_dest			; will be destination pointer (3+3)
	STA v_dest+1
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
		AND #127			; *** check for wrapping *** eeeeeeeek
		ORA #>VA_BASE
		STA v_dest+1		; update (3)
		INY					; next font byte (2)
		CPY #VA_SCAN		; all done? (2)
		BNE vch_pl			; continue otherwise (3)
; now must set attribute accordingly!
	SEC					; subtract 8192+1024 from v_dest (MSB already in A)
	SBC #36
;	BCS vch_nw			; no wrap, is this needed?
;		AND #127			; hope this will do otherwise...
;		ORA #>VA_BASE
vch_nw:
	STA v_dest+1		; now it should be pointing to the corresponding attribute
	LDA va_attr			; get preset colour...
	_STAY(va_dest)		; ...and place it
; printing is done, now advance current position
vch_adv:
	INC va_cur			; advance to next character (6)
	BNE vch_scs			; all done, no wrap (3)
		INC va_cur+1		; or increment MSB (6)
; should set CRTC cursor accordingly
vch_scs:
	LDY #14				; cur_h register on CRTC (2)
	LDX #1				; max offset (2)
vcur_l:
		LDA va_cur, X		; get data
		STY crtc_rs			; select register
		STA crtc_da			; ...and set data
; go for next
		INY					; next reg (2)
		DEX					; will pick previous byte
		BPL vcur_l			; until finished (3/2)
; check whether scrolling is needed
	LDA va_cur+1		; check position (4)
	CMP va_sch+1		; all lines done? (4)
		BNE vch_ok			; no, just exit (3/2)
	LDA va_cur			; check LSB too... (4+4)
	CMP va_sch
		BNE vch_ok			; (3/2)
; otherwise must scroll... via CRTC
; increment base address, wrapping if needed
	LDX va_mode			; get set mode for the width table
	CLC
	LDA va_ba			; get current base... (2+4)
	ADC va_width, X		; ...and add one line (4)
	STA va_ba			; update variable LSB (4)
;	TAX					; keep in case is needed (2)
	LDA va_ba+1			; now for MSB (4)
	ADC #0				; propagate carry (2)
	CMP #>VA_SCRL		; did it wrap? (2)
	BNE vsc_nw			; no, just set CRTC and local (3/2)
;	CPX #<VA_SCRL		; all 16-bits coincide? (2)
;	BNE vsc_nw			; no, just set CRTC and local (3/2)
		LDA #>VA_BASE		; or yes, wrap value around (2)
;		LDX #<VA_BASE		; is this needed for MSB comparison??? (2)
vsc_nw:
	STA va_ba+1		; update variable MSB... (4)
;	STX va_ba			; see above! (4)
; ...and CRTC registerSSSSSS!!!!
	LDY #12				; start_h register on CRTC (2)
	LDX #1				; max offset (2)
vsc_upd:
		LDA va_ba, X		; get data
		STY crtc_rs			; select register
		STA crtc_da			; ...and set data
; go for next
		INY					; next reg (2)
		DEX					; will pick previous byte
		BPL vsc_upd			; until finished (3/2)
; update va_sch
	LDA va_sch			; get LSB (4)
	LDX va_sch+1		; see MSB (4)
	CPX #>VA_SCRL		; already at limit? (2)
	BNE vsc_blim		; not, just increment (3/2)
;	CMP #<VA_SCRL		; LSB already at limit too? (2)
;	BNE vsc_blim		; not, just increment (3/2)
		LDX #>VA_BASE		; yes, wrap to 2nd line (2)
		LDA #<VA_BASE		; add one line to this (2)
vsc_blim:
	CLC
	LDY va_mode			; get set mode for the width table
	ADC va_width, Y		; ...and add one line (4)
	STA va_sch			; update variable (4+4)
	STX va_sch+1
vch_ok:
	_DR_OK

; *** carriage return *** TO DO ***
; quite easy as 32 char per line
va_cr:
	LDX #>VA_BASE		; MSB when required
	LDA #<VA_BASE
	LDY va_mode			; get set mode for the width table
vcr_mod:
		CLC
		ADC va_width, Y		; ...and add one line (4)
		BCC vcr_chk
			INX					; MSB was incremented
vcr_chk:
		CPX va_cur+1		; near there?
			BNE vcr_mod			; no way
		CMP va_cur			; compare in full
		BCx vcr_mod			; not yet...


	STA va_cur			; eeeeeeeeek (4)
vcr_chc:
	BCC vch_ok			; seems OK (3/2)
		INC va_cur+1		; or propagate carry... (6)
		BNE vch_scs			; ...update cursor and check for scrolling, no need for BRA (3/2)

; *** tab (8 spaces) ***
va_tab:
	LDA va_cur			; get LSB (4)
	AND #%11111000		; modulo 8 (2+2)
	CLC
	ADC #8				; increment position (2)
vtb_l:
		PHA					; save desired position (3)
		LDA #' '			; will print spaces (2+3)
		STA io_c
		JSR vch_prn			; direct space printing, A holds 32 too (...)
		PLA					; recover desired address (4)
		CMP va_cur			; reached? (4)
		BNE vtb_l			; no, continue (3/2)
	_DR_OK				; yes, all done

; *** backspace ***
va_bs:
; first get cursor one position back...
	JSR vbs_bk			; will call it again at the end (...)
; ...then print a space, the regular way...
	LDA #' '			; code of space (2)
	STA io_c			; store as single char... (3)
	JSR va_prn			; print whatever is in io_c (...)
; ...and back again!
vbs_bk:
	DEC va_cur			; one position back (6)
	LDA va_cur			; check for borrow (4) eeeeeeeeek
	CMP #$FF			; did it wrap? (2)
	BNE vbs_end			; no, return or end function (3/2)
		DEC va_cur+1		; yes, propagate borrow (6) eeeeeeek
; really ought to check for possible scroll-UP...
; at least, avoid being outside feasible values
		LDA va_cur+1		; where are we? (4)
		CMP #>VA_BASE		; cannot be below VRAM base (2)
		BCS vbs_end			; no borrow, all OK (3/2)
			LDY #<VA_BASE		; get base address (2)
			LDA #>VA_BASE		; MSB too (2)
			STY va_cur			; set current (4+4)
			STA va_cur+1
			PLA					; discard return address, as nothing to print (4+4)
			PLA
			_DR_ERR(EMPTY)		; try to complain, just in case
vbs_end:
	_DR_OK				; all done, CLC will not harm at first call

; ********************
; *** several data ***
; ********************

va_width:
; line lengths on several modes, must match order from va_data!
	.byt	40, 36, 32, 40, 40, 36, 32, 40

va_data:
; CRTC registers initial values
; total of eight video modes

; *** values for 25.175 MHz dot clock *** 31.47 kHz Hsync, 59.94 Hz Vsync
; unlikely to work on 24.576 MHz crystal (30.72 kHz Hsync, 58.5 Hz Vsync)
; mode 0 (aka 40/50) is 320x200 1-6-3, *** industry standard ***
	.byt 49				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt 41				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 25				; R6, vertical displayed chars
	.byt *28				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; mode 1 (aka 36/50) is 288x224 1-6-3, fully compatible
	.byt 49				; R0, horizontal total chars - 1
	.byt 36				; R1, horizontal displayed chars
	.byt 39				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 28				; R6, vertical displayed chars
	.byt *34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; mode 2 (aka 32/50) is 256x240 1-6-3, fully compatible
	.byt 49				; R0, horizontal total chars - 1
	.byt 32				; R1, horizontal displayed chars
	.byt 37				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt 34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; *** values for 24.576 MHz dot clock *** 32 kHz Hsync, 60.95 Hz Vsync
; mode 3 (aka 40/48T) is 320x200 1-5-2, 3.25uS sync, 1.3uS back porch (most likely compatible)
	.byt 47				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt *37				; R2, HSYNC position - 1
	.byt *132			; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt 34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; mode 4 (aka 40/48P) is 320x200 1-4-3, 2.6uS sync, 1.95uS back porch (likely compatible)
	.byt 47				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt *37				; R2, HSYNC position - 1
	.byt *132			; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt 34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; mode 5 (aka 36/48) is 288x224 1-6-3, most likely compatible
	.byt 47				; R0, horizontal total chars - 1
	.byt 36				; R1, horizontal displayed chars
	.byt *37				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt 34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; mode 6 (aka 32/48) is 256x240 1-6-3, most likely compatible
	.byt 47				; R0, horizontal total chars - 1
	.byt 32				; R1, horizontal displayed chars
	.byt *37				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt 34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; mode 7 (aka 40/48S) is 320x200 1-6-1, 3.9uS sync, 650nS back porch (perhaps compatible)
	.byt 47				; R0, horizontal total chars - 1
	.byt 40				; R1, horizontal displayed chars
	.byt *37				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN)
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt *34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12/13, start address (big endian)
	.byt <VA_BASE
	.byt >VA_BASE		; R14/15, cursor position (big endian)
	.byt <VA_BASE

; *** glyphs ***
va_font:

.)
