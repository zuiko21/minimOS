; 8 KiB micro-VDU for minimOS!
; v0.6a3
; (c) 2019-2022 Carlos J. Santisteban
; last modified 20210107-1006

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
	.asc	"8 kiB micro-VDU v0.6", 0

va_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	VA_BASE	= $6000		; screen start, not necessarily 8K-aligned if smaller screen
	VA_TOP	= $7FFF		; must specify last address, in case the whole 8K block is not used

	VA_WDTH = 36			; screen size (columns)
	VA_HGHT = 28			; screen size (rows)

	VA_NEXT	= $6120		; second line address, for scroll routines (depends on above values)
	VA_LAST	= $7E60		; last line address, for scroll routines (depends on above values)
	VA_END	= $7F80		; first free address on VRAM (depends on above values)

	VA_SCAN	= 8			; number of scanlines (pretty hardwired)

	VA_BPL	= VA_WDTH*VA_SCAN	; number of bytes per row

	crtc_rs	= VA_TOP-1		; *** 6845 addresses at VRAM end ***
	crtc_da	= VA_TOP


; define TEKTRONIX in order to enable graphic commands, otherwise printable glyphs!
#define	TEKTRONIX	_TEKTRONIX

; *** zeropage variables ***
	v_dest	= $E8		; generic writes, was local2, perhaps including this on zeropage.h? aka ptc
	v_src	= $EA		; font read, is this OK? aka ptl

; ************************
; *** initialise stuff *** should create line addresses table...
; ************************
va_init:
; first must make sure desired address range is free! TO DO TO DO

; load 6845 CRTC registers
	LDX #13				; last common register
vi_crl:
		STX crtc_rs			; select this register
		LDA va_data, X		; get value for it
		STA crtc_da			; set value
		DEX					; next address
		BPL vi_crl			; continue until done
	INX					; make sure X is zero
; reset flags! X is 0
	STX va_xor			; clear mask is true video
	STX va_flag			; reset flag eeeeeeeeeeeeek
#ifdef	TEKTRONIX
	STX va_gx			; reset graphic coordinates
	STX va_gx+1			; MSB as width is usually 288
	STX va_gy
	STX va_gflg			; graphic flags TBD, pen UP (D0=0) by default
#endif
; new, set RAM pointer to supplied font!
	LDY #<vs_font		; get supplied LSB (2) *** now using a RAM pointer
	LDA #>vs_font		; same for MSB (2)
	STY va_font			; store locally (4+4)
	STA va_font+1
; start address and software cursor will be set by CLS routine!

; CLC makes little sense even if there is no splash code
;	JSR va_cls			; reuse code from Form Feed, but needs to return for the SPLASH screen!
; **************************
; *** splash screen code ***
; **************************
; ****************************
; *** end of splash screen ***
; ****************************
; if not used may just let it fall into CLS routine ***
;	_DR_OK				; installation succeeded

; ***************************************
; *** routine for clearing the screen *** takes less than 83Kt for full 8K screen
; ***************************************
va_cls:
	LDA #>VA_BASE		; base address (2+2) NOT necessarily page aligned!
	LDY #<VA_BASE
; reset cursor to AAYY (reusing scroll code)
	JSR vsc_cok			; set hardware cursor
; clear VRAM area
	STA v_dest+1			; set pointer MSB (3)
	LDA #0				; clear value (2), as no STZ (zp), Y
	STA va_x			; ...plus coordinates as well (4+4)
	STA va_y
	STA v_dest			; keep LSB zero as will use Y as index (3)
vcl_do:
; shared entry point with scrolling!
	LDX #>VA_END			; store last page (2)
vcl_c:
		STA (v_dest), Y		; set this byte (5)
		INY					; go for next (2+3)
		BNE vcl_c
			INC v_dest+1			; check following page eeeeeeeeek (5)
			CPX v_dest+1			; already at last page? (3)
			BNE vcl_c			; no, continue as usual (3)
; otherwise, do not fill the whole page as will affect the 6845!
vcl_l:
		STA (v_dest), Y		; set this byte (5)
		INY					; go for next (2)
		CPY #<VA_END			; all visible? (2+3)
		BNE vcl_l
	_EXIT_OK			; worth it as comparisons set C (8)

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
	LDX va_flag			; something being set?
	BEQ va_nbin			; if not, continue with regular code
		_JMPX(va_xtb-16)	; otherwise process accordingly (using another table, note offset)

; *** *** much closer control code, may be elsewhere *** ***
; * * expects row byte... * *
vch_atyx:
	SEC
	SBC #' '			; from space and beyond
; compute new Y pointer...
#ifdef	SAFE
; note that any byte below 32 MUST be ignored if gtext is not supported!
	BCC va_ngy			; just ignore this byte, keep waiting for MSB
	CMP #VA_HGHT			; over screen size?
	BCC vat_yok
		_DR_ERR(INVALID)	; ignore if outside range
vat_yok:
#endif
	STA va_y			; set new value
	INC va_flag			; flag expects second coordinate... routine pointer placed TWO bytes after!
	INC va_flag
va_ngy:
	_DR_OK				; just wait for the next coordinate

; * * ...and then expects column byte, note it is now 25, no longer 24! * *
vch_atcl:
	SEC
	SBC #' '			; from space and beyond
; add X and set cursor...
#ifdef	SAFE
; note that any byte below 32 MUST be ignored if gtext is not supported!
	BCC va_ngy			; just ignore this byte, keep waiting for MSB
	CMP #VA_WDTH			; over screen size?
	BCC vat_xok
		_DR_ERR(INVALID)	; ignore if outside range
vat_xok:
#endif
	STA va_x			; coordinates are set
	_STZA va_flag			; reset flag
	JMP vch_scs			; set cursor... and return

; * * take byte as FG colour * * set inverse if zero!
vch_ink:
	_STZX va_flag			; clear flag before!
	TAX					; check whether zero
	BNE vch_cend			; no, just ignore
		_BRA vch_so			; yes, enable inverse
; * * take byte as BG colour * * disable inverse if zero (vch_ink reuses some code)
vch_papr:
	_STZX va_flag			; clear flag before!
	TAX					; check whether zero
		BEQ vch_si			; yes, disable inverse
vch_cend:
	RTS						; *** no need for DR_OK as BCS is not being used

; ** check whether control char or printable **
va_nbin:
#ifdef	TEKTRONIX
	CMP #' '			; printable? (2)
#else
	CMP #28					; printable? including unsupported graphic commands (2)
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
	CMP #VA_WDTH			; over line length?
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
; otherwise, scroll up... TO DO
vcu_nt:
	DEC va_y			; one row up
	JMP vch_scs			; update cursor and exit (already checked for scrolling, may skip that)

; * * here come the special modes * *
vch_g27:
	LDA #27					; special offset for PLOT mode
	BNE vch_dcx			; ...and set offset (no need for BRA)
vch_g31:
	LDA #31					; special offset for INCG mode
	BNE vch_dcx			; ...and set offset (no need for BRA)
vch_rst:
	LDA #0				; clear flag, back to text mode
; * * request for extra bytes (if offset matches ASCII) * *
vch_dcx:
	STA va_flag			; set flag if any colour or coordinate is to be set
	RTS					; all done for this setting *** no need for DR_OK as BCS is not being used

; * * direct glyph printing (was above) * * should be close to actual printing
vch_dle:				; * process byte as glyph *
	_STZX va_flag		; ...but reset flag! eeeeeeeek^2
	_BRA vch_prn		; NMOS might use BEQ instead, but not for CMOS!

; * * non-printable neither accepted control, thus use substitution character * *
vch_npr:
	LDA #'?'			; unrecognised char
	STA io_c			; store as required and...

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
; * call common routine to compute address from coordinates *
	JSR vs_ptr			; create destination pointer
; copy from font to VRAM
	LDY #VA_SCAN-1		; scanline counter (2)
vch_pl:
		LDA (v_src), Y		; get glyph data (5)
		EOR va_xor			; apply mask! (4)
		STA (v_dest), Y		; store into VRAM (5)
; advance to next scanline
		DEY					; next (previous) font byte (2)
		BNE vch_pl			; continue otherwise (3)
; printing is done, now advance current position
	JMP vch_rght		; *** this is actually cursor right! ***
vch_scs:
; check whether scrolling is needed
; it is assumed that only UPCU may issue a scroll up, thus not checked here
	LDA va_y		; actual row
	CMP #VA_HGHT		; over last line?
	BNE vch_ok		; no, just exit (3/2)
; *** *** scroll routine *** ***
		DEC va_y		; scrolling moves cursor up (6)
; pointer setup
		LDY #>VA_BASE		; base address (2+2) NOT necessarily page aligned!
		LDA #<VA_BASE
		STY v_dest+1		; set pointer MSB (3)
		STA v_dest		; destination is ready (3)
		LDY #>VA_NEXT		; second line address (2+2)
		LDA #<VA_NEXT
		STY v_src+1		; set pointer MSB (3)
		STA v_src		; source is ready (3)
; scrolling loop
		LDX #>VA_LAST	; screen limit for easier comparision (2)
		LDY #0			; reset index (2)
vsc_dl:
			LDA (v_src), Y	; read source value... (5)
			STA (v_dest), Y	; ...and copy it (5)
			INY				; next (2)
			BNE vsc_dl		; complete page (3)
				INC v_src+1		; or jump to next page (5+5)
				INC v_dest+1
				CPX v_sec+1		; check page limit (3)
			BNE vsc_dl		; not last, go for next page (3)
; second loop for the very last bytes
vsc_ll:
			LDA (v_src), Y	; read source value... (5)
			STA (v_dest), Y	; ...and copy it (5)
			INY				; next (2)
			CPY #<VA_LAST		; last byte of last page? (2)
			BNE vsc_ll		; continue until the end (3)
; clear last visible line
		LDX #>VA_LAST		; last line address (2+2)
		LDY #<VA_LAST
		STX v_dest+1		; set pointer MSB (3)
		LDA #0			; clear value (2)
		STA v_dest		; pointer is ready, will use Y as LSB (3)
		JSR vcl_do		; finish clearing from CLS!
; *** *** end of scroll routine *** ***
vch_ok:
; set cursor position from separate coordinates
	JSR vs_ptr			; compute address at v_dest, A holds MSB
	LDY v_dest			; retrieve LSB
; set CRTC registers, expects MSB on A and LSB on Y (reused by CLS)
vch_cok:
	LDX #14				; cur_h register on CRTC (2)
	STX crtc_rs			; select register
	STA crtc_da			; ...and set data MSB
; go for next
	INX					; next reg (2)
	STX crtc_rs			; select register
	STY crtc_da			; ...and set data LSB
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
	CMP #VA_WDTH			; over the limit?
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

; **********************************
; *** Tektronix graphic routines ***
; **********************************
#ifdef	TEKTRONIX
vch_plt:		; 27, plot routine (was ASCII 28) ** TO DO **
	_DR_ERR(UNAVAIL)	; placeholder

vch_drw:		; 29, draw routine (same as ASCII!) ** TO DO **
	_DR_ERR(UNAVAIL)	; placeholder

vch_inc:		; 31, incremental plotting (was ASCII 30)
	TAX					; check for null
		BEQ vig_rts			; will be simply ignored!
	CMP #' '			; pen up?
		BEQ vig_pu
	CMP #'P'			; pen down?
		BEQ vig_pd
	CMP #'D'			; north?
		BEQ vig_n
	CMP #'E'			; north east?
		BEQ vig_ne
	CMP #'A'			; east?
		BEQ vig_e
	CMP #'I'			; south east?
		BEQ vig_se
	CMP #'H'			; south?
		BEQ vig_s
 	CMP #'J'			; south west?
		BEQ vig_sw
	CMP #'B'			; west?
		BEQ vig_w
	CMP #'F'			; north west?
		BEQ vig_nw			; otherwise unrecognised command, just print it
	_STZA va_flag			; back to text mode
vig_rts:
	_DR_OK

; incremental commands follow
; * PEN UP *
vig_pu:
	LDA va_gflg			; graphic flags
	AND #254				; clear bit 0
	STA va_gflg			; update flag
	RTS
; * PEN DOWN *
vig_pd:
	LDA va_gflg			; graphic flags
	ORA #1				; set bit 0
	STA va_gflg			; update flag
	RTS				; ** must print current position ** TO DO
; * NORTH *
vig_n:
	INC va_gy			; up
	JSR vig_chy
	_BRA vig_pix
; * NORTH EAST *
vig_ne:
	INC va_gy			; up
	JSR vig_chy			; check bounds... and continue NE into EAST code
; * EAST *
vig_e:
	INC va_gx			; right (LSB)
	BNE vig_eok
		INC va_gx+1
vig_eok:
	JSR vig_chx
	_BRA vig_pix			; plot it, if pen is down
; * SOUTH EAST *
vig_se:
	DEC va_gy			; down
	JSR vig_chy			; check bounds!
	_BRA vig_e			; ...continue with EAST code
; * SOUTH *
vig_s:
	DEC va_gy			; down
	JSR vig_chy
	_BRA vig_pix			; plot it, if pen is down
; * SOUTH WEST *
vig_sw:
	DEC va_gy			; down
	JSR vig_chy			; check bounds!
	_BRA vig_w			; ...continue with WEST code
; * NORTH WEST *
vig_nw:
	INC va_gy			; up
	JSR vig_chy			; check bounds... and continue into WEST code
; * WEST *
vig_w:
	DEC va_gx			; left (LSB)
	CMP #255			; check carry
	BNE vie_wok			; check MSB
		DEC va_gx+1
vie_wok:
	JSR vig_chx			; check bounds... and continue into plotting routine
; *** place dot if pen is down ***
vig_pix:
	LDA va_gflg			; check bit 0
	LSR					; pen down?
		BCC vig_rts			; no, just return
; compute address and set plot
vig_dot:
	_STZA v_src			; reset scanline in row
	_STZA v_src+1			; ...and pixel in byte
	LDA #VA_HGHT*VA_SCAN	; total lines, OK if less than 255!
	SEC
	SBC va_gy			; mirrored Y coordinate! off by 1?
	LSR					; divide by 8...
	ROR v_src			; ...and keep the raster part on MSb
	LSR
	ROR v_src
	LSR
	ROR v_src
	TAX					; row coordinate
	LDA va_gx			; X coordinate is OK
	LSR					; divide by 8...
	ROR v_src+1			; ...and keep the pixel in byte part on MSb
	LSR
	ROR v_src+1
	LSR
	ROR v_src+1
	JSR vs_rc			; compute byte address within row
; is the following OK?
	LDA v_src+1			; now get pixel position in byte (MSB)
	LSR					; turn into LSB for counter
	LSR
	LSR
	LSR
	LSR
	TAX 					; use as table index

	LDA v_bmsk, X		; new table-driven bit mask...
; what about Y? should it take the raster?
	ORA (v_dest), Y		; add previous bits (Y is zero!)
	STA (v_dest), Y		; ...and store new pattern
	JMP vig_rts			; is this OK?

; ** bounds checking (unified) **
; horizontal
vig_chx:
	LDX va_gx
	LDY va_gx+1			; MSB too!
	CPX #255			; below zero?
	BNE vcx_hi			; no
		TYA					; did it wrap?
		BPL vcx_ok			; no, ok
			INX					; ...or back to min
			INY
		BEQ vcx_set
vcx_hi:
;	TYA					; is MSB set? *** should compare against max MSB
	CPY #>(8*VA_WDTH)	; max MSB?
	BNE vcx_ok			; no, all ok (was BEQ, see above)
		CPX #<(8*VA_WDTH)	; over the limit? (usually 32, 288-256)
	BNE vcy_ok			; no, all OK
; * this is only needed if width is multiple of 256 *
		TXA					; has just wrapped?
		BNE vcx_npw			; no, just correct LSB
			DEY
vcx_npw:
; * end of code, remove if (width MOD 256) is not zero *
		DEX					; ...or back to max
vcx_set:
		STX va_gx			; correct value if needed
		STY va_gx+1			; not always needed!
vcx_ok:
	RTS
; vertical (valid up to 255 lines!)
vig_chy:
	LDX va_gy
	CPX #255			; below zero?
	BNE vcy_hi			; no
		INX					; ...or back to min
		BEQ vcy_set
vcy_hi:
	CPX #VA_SCAN*VA_HGHT		; over the top? uaually 224
	BNE vcy_ok			; no, all OK
		DEX					; ...or back to max
vcy_set:
		STX va_gy			; correct value if needed
vcy_ok:
	RTS
#endif

; **********************
; *** other routines ***
; **********************
; create local destination pointer
; original code was 49b, <89t
; tables take 56 bytes (for 36x28 mode) but this code is 26b, <38t
vs_ptr:
	LDA va_x		; current column
	LDX va_y		; current row
; ** common entry point with A=column, X=row **
vs_rc:
	LDY vla_h, X		; is index for MSB table
	ASL
	ASL
	ASL			; 8 bytes per char
	BCC vs_xnc		; if offset is over one page...
		INY				; ...increment MSB
		CLC
vs_xnc:
	ADC vla_l, X		; add offset to table LSB
	STA v_dest		; LSB is ready
	TYA				; this is MSB
	ADC #0			; add eventual carry
	STA v_dest+1		; pointer is ready
	RTS

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
	.word	vch_dcx		; INK,  set foreground colour (set inverse video if zero)
	.word	vch_hc		; XOFF, turn cursor off
	.word	vch_dcx		; PAPR, set background colour (disable inverse video if zero)
	.word	va_home		; HOME, move cursor to top left without clearing
	.word	va_cls		; PGDN, page down, may issue a FF
	.word	vch_dcx		; ATYX, takes two more chars!
	.word	vch_npr		; BKTB, no direct effect on screen
	.word	vch_npr		; PGUP, no direct effect on screen, might do CLS anyway
	.word	vch_npr		; STOP, no effect on screen
	.word	vch_npr		; ESC,  no effect on screen (this far!)
; here come the ASCII separators, now the Tektronix 4014 graphic commands!
#ifdef	TEKTRONIX
	.word	vch_g27		; PLOT, set points (offset 27 instead of 28)
	.word	vch_dcx		; DRAW, draw lines (offset 29!)
	.word	vch_g31		; INCG, incremental plotting (offset 31 intead of 30)
	.word	vch_rst		; TEXT, back to text mode
#endif

va_xtb:
; new table for extra-byte codes
; note offset as managed X codes are 16, 18, 20 and 23, thus padding byte
	.word	vch_dle		; 16, process byte as glyph
	.word	vch_ink		; 18, take byte as FG colour (discard if not zero)
	.word	vch_papr	; 20, take byte as BG colour (discard if not zero)
	.byt	$FF			; *** padding as ATYX is 23, not 22 ***
	.word	vch_atyx	; 23, expects row byte
	.word	vch_atcl	; 25, expects column byte, note it is no longer 24!
; *** special offsets for tektronix commands! ***
#ifdef	TEKTRONIX
	.word	vch_plt		; 27, plot routine (was ASCII 28)
	.word	vch_drw		; 29, draw routine (same as ASCII!)
	.word	vch_inc		; 31, incremental plotting (was ASCII 30)
#endif

va_data:
; CRTC registers initial values

; *** values for 25.175 MHz dot clock *** 31.47 kHz Hsync, 59.94 Hz Vsync
; unlikely to work on 24.576 MHz crystal (30.72 kHz Hsync, 58.5 Hz Vsync)

; standard mode is 288x224 (36x28) 1-6-3, fully compatible
	.byt 49				; R0, horizontal total chars - 1
	.byt 36				; R1, horizontal displayed chars
	.byt 39				; R2, HSYNC position - 1
	.byt 38				; R3, HSYNC width (may have VSYNC in MSN) =6
	.byt 31				; R4, vertical total chars - 1
	.byt 13				; R5, total raster adjust
	.byt 28				; R6, vertical displayed chars
	.byt 28				; R7, VSYNC position - 1
	.byt $50			; R8, non-interlaced and 1 ch. skew
	.byt 15				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable
	.byt 15				; R11, cursor end raster
	.byt >VA_BASE		; R12, start address MSB
	.byt <VA_BASE		; R13, start address LSB
; cursor address (R14-R15) to be set by CLS

; *** line addresses tables ***
; LSB
vla_l:
	.byt	<VA_BASE		; row 0 (or VA_BASE) is usually $6000
	.byt	<VA_BASE+VA_BPL		; row 1 (or VA_NEXT) $6120
	.byt	<VA_BASE+2*VA_BPL	; row 2 or $6240
	.byt	<VA_BASE+3*VA_BPL	; row 3 or $6360
	.byt	<VA_BASE+4*VA_BPL	; row 4 or $6480
	.byt	<VA_BASE+5*VA_BPL	; row 5 or $65A0
	.byt	<VA_BASE+6*VA_BPL	; row 6 or $66C0
	.byt	<VA_BASE+7*VA_BPL	; row 7 or $67E0
	.byt	<VA_BASE+8*VA_BPL	; row 8 or $6900
	.byt	<VA_BASE+9*VA_BPL	; row 9 or $6A20
	.byt	<VA_BASE+10*VA_BPL	; row 10 or $6B40
	.byt	<VA_BASE+11*VA_BPL	; row 11 or $6C60
	.byt	<VA_BASE+12*VA_BPL	; row 12 or $6D80
	.byt	<VA_BASE+13*VA_BPL	; row 13 or $6EA0
	.byt	<VA_BASE+14*VA_BPL	; row 14 or $6FC0
	.byt	<VA_BASE+15*VA_BPL	; row 15 or $70E0
	.byt	<VA_BASE+16*VA_BPL	; row 16 or $7200
	.byt	<VA_BASE+17*VA_BPL	; row 17 or $7320
	.byt	<VA_BASE+18*VA_BPL	; row 18 or $7440
	.byt	<VA_BASE+19*VA_BPL	; row 19 or $7560
	.byt	<VA_BASE+20*VA_BPL	; row 20 or $7680
	.byt	<VA_BASE+21*VA_BPL	; row 21 or $77A0
	.byt	<VA_BASE+22*VA_BPL	; row 22 or $78C0
	.byt	<VA_BASE+23*VA_BPL	; row 23 or $79E0
	.byt	<VA_BASE+24*VA_BPL	; row 24 or $7B00
	.byt	<VA_BASE+25*VA_BPL	; row 25 or $7C20
	.byt	<VA_BASE+26*VA_BPL	; row 26 or $7D40
	.byt	<VA_BASE+27*VA_BPL	; row 27 (or VA_LAST) $7E60

; MSB
vla_h:
	.byt	>VA_BASE		; row 0 (or VA_BASE) is usually $6000
	.byt	>VA_BASE+VA_BPL		; row 1 (or VA_NEXT) $6120
	.byt	>VA_BASE+2*VA_BPL	; row 2 or $6240
	.byt	>VA_BASE+3*VA_BPL	; row 3 or $6360
	.byt	>VA_BASE+4*VA_BPL	; row 4 or $6480
	.byt	>VA_BASE+5*VA_BPL	; row 5 or $65A0
	.byt	>VA_BASE+6*VA_BPL	; row 6 or $66C0
	.byt	>VA_BASE+7*VA_BPL	; row 7 or $67E0
	.byt	>VA_BASE+8*VA_BPL	; row 8 or $6900
	.byt	>VA_BASE+9*VA_BPL	; row 9 or $6A20
	.byt	>VA_BASE+10*VA_BPL	; row 10 or $6B40
	.byt	>VA_BASE+11*VA_BPL	; row 11 or $6C60
	.byt	>VA_BASE+12*VA_BPL	; row 12 or $6D80
	.byt	>VA_BASE+13*VA_BPL	; row 13 or $6EA0
	.byt	>VA_BASE+14*VA_BPL	; row 14 or $6FC0
	.byt	>VA_BASE+15*VA_BPL	; row 15 or $70E0
	.byt	>VA_BASE+16*VA_BPL	; row 16 or $7200
	.byt	>VA_BASE+17*VA_BPL	; row 17 or $7320
	.byt	>VA_BASE+18*VA_BPL	; row 18 or $7440
	.byt	>VA_BASE+19*VA_BPL	; row 19 or $7560
	.byt	>VA_BASE+20*VA_BPL	; row 20 or $7680
	.byt	>VA_BASE+21*VA_BPL	; row 21 or $77A0
	.byt	>VA_BASE+22*VA_BPL	; row 22 or $78C0
	.byt	>VA_BASE+23*VA_BPL	; row 23 or $79E0
	.byt	>VA_BASE+24*VA_BPL	; row 24 or $7B00
	.byt	>VA_BASE+25*VA_BPL	; row 25 or $7C20
	.byt	>VA_BASE+26*VA_BPL	; row 26 or $7D40
	.byt	>VA_BASE+27*VA_BPL	; row 27 (or VA_LAST) $7E60

; on 36x28 screens, $7F80-7FFD are free (last two used by CRTC I/O)

; *** glyphs ***
vs_font:
#include "fonts/8x8.s"
.)
