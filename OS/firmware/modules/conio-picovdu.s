; firmware module for minimOS
; pico-VDU basic 16x16 firmware console 0.9.6a2
; suitable for Durango-proto (not Durango-X/SV) computer
; also for any other computer with picoVDU connected via IOSCREEN option
; new version based on Durango-X code
; (c) 2021 Carlos J. Santisteban
; last modified 20210727-2157

; ****************************************
; CONIO, simple console driver in firmware
; ****************************************
; template with temporary IO9 input support (no handshake!)
;	INPUT
; Y <-	char to be printed (1...255)
;	supported control codes in this version
;		0	= ask for one character (non-locking)
;		1	= start of line (CR withput LF, eg. set Y to one so DEY sets Z and skips LF routine)
;		2	= cursor left
;		6	= cursor right
;		7	= beep
;		8	= backspace
;		9	= TAB (x+8 MOD 8 in any case)
;		10	= line feed (cursor down, direct jump needs no Y set)
;		11	= cursor up
;		12	= clear screen AND initialise device
;		13	= newline (actually LF after CR, eg. set Y to anything but 1 so DEY clears Z and does LF)
;		14	= inverse video
;		15	= true video
;		16	= DLE, do not execute next control char
;		17	= cursor on (no cursor yet?) actually show current position for a split second
;		18	= set ink colour (MOD 16 for colour mode, hires will set it as well but will be ignored)*
;		19	= cursor off (no cursor yet, simply IGNORED)
;		20	= set paper colour (ditto)*
;		21	= home without clear
;		23	= set cursor position**
;		31	= back to text mode (simply IGNORED)
; commands marked * will take a second char as parameter
; command marked ** takes two subsequent bytes as parameters
; *** NOT YET supported (will show glyph like after DLE) ***
;		3	= TERM (?)
;		4	= end of screen
;		5	= end of line
;		22	= page down (?)
;		24	= backtab
;		25	= page up (?)
;		26	= switch focus (?)
;		27	= escape (?)
;		28...30	= Tektronix graphic commands
;	OUTPUT
; C ->	no available char (if Y was 0)

#include "../../usual.h"

; in Durango-proto and the standalone IOx-picoVDU, enable IOSCREEN option for IO-based access
; in case of direct mapping (Durango-L?) comment line below
#define	IOSCREEN	_IOSCREEN

; *** zeropage variables ***
; cio_src.w (pointer to glyph definitions)
; cio_pt.w (screen pointer)

; *** firmware variables to be reset upon FF ***
; fw_ink and fw_paper NO LONGER NEEDED
; fw_ciop.w (upper scan of cursor position)
; fw_fnt (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_flags (0=colour, 64=invers, was the older fw_hires, NO MORE FLAGS ALLOWED as must be ORed for IO8lh)
; fw_cbin (binary or multibyte mode)
; fw_ctmp (temporary use)
; first two modes are directly processed, note BM_DLE is the shifted X
#define	BM_CMD		0
#define	BM_DLE		32
; these modes are handled by indexed jump, note offset of 2
; first of these modes just ignores the colour code, as no colours to be set, note new codes
#define	BM_INK		2
#define	BM_ATY		4
#define	BM_ATX		6
; no custom initial colours!

.(
pvdu	= $7800				; base address
IO8attr	= $8000				; this address is not only for I/O, but d6 is the INVERSE mode
#ifdef	IOSCREEN
IO8lh	= $8000				; I/O Screen addresses, this one must be ORed with fw_flags!
IO8ll	= $8001
IO8wr	= $8002
#endif
IO9di	= $9FFF				; data input (TBD)
IOBeep	= $BFF0				; canonical buzzer address (d0)

; *** *** code start, print char in Y (or ask for input) *** ***
	TYA						; is going to be needed here anyway
	LDX fw_cbin				; check whether in binary/multibyte mode
	BEQ cio_cmd				; if not, check whether command (including INPUT) or glyph
		CPX #BM_DLE			; just receiving what has to be printed?
			BEQ cio_gl		; print the glyph!
		_JMPX(cio_mbm-2)	; otherwise process following byte as expected, note offset
cio_cmd:
	CMP #32					; printable anyway?
	BCS cio_prn				; go for it, flag known to be clear
;		AND #31				; if arrived here, it MUST be below 32!
		ASL					; two times
		TAX					; use as index
		CLC					; will simplify most returns as DR_OK becomes just RTS
		_JMPX(cio_ctl)		; execute from table
cio_gl:
	_STZX fw_cbin			; clear flag!
cio_prn:

/*
; ***********************************
; *** output character (now in A) ***
; ***********************************
;		AND #$7F			; in order to strip extended ASCII
		CMP #FORMFEED		; reset device?
		BNE cn_nff			; no, just print it
; * clear screen, not much to be inited *
			LDY #<pvdu		; initial address
			LDX #>pvdu		; valid MSB for IOSCREEN, black-on-white mode (%01111xxx) instead of inverse for Pacman (%00001xxx)
			STY cio_pt		; set ZP pointer
			STX cio_pt+1
			STY fw_ciop		; worth resetting global pointer (cursor) here (conio.h?)
			STX fw_ciop+1
;			LDY #0			; no need to reset index
			TYA				; clear accumulator
cls_p:
#ifdef	IOSCREEN
				STX IO8lh	; set page on I/O device
#endif
cls_l:
#ifndef IOSCREEN
					STA (cio_pt), Y	; clear screen byte
#else
					STY IO8ll
					STA IO8wr
#endif
					INY
					BNE cls_l		; continue within page
#ifndef	IOSCREEN
				INC cio_pt+1
#else
				INX
#endif
				BPL cls_p	; same as cls_l if not using IOSCREEN
			_DR_OK
; continue evaluating control codes
cn_nff:
		CMP #BS				; backspace?
		BNE cn_nbs
; * clear previous char *
; coordinates are stored 01111yyy y000xxxx
; y will remain constant, xxxx may go down to zero
; if xxxx is zero, do nothing... but better clear first char in line
; will never cross page!
; with no cursor, best to clear current char after backing
			LDA fw_ciop		; get LSB (yrrrxxxx)
			AND #$F			; check xxxx
			BEQ bs_clr		; already at line start
				DEC fw_ciop	; back one character (cannot be xxxx=0 as already checked for that)
bs_clr:
			LDA fw_ciop		; get current address (perhaps after backing)
			LDX fw_ciop+1
			STA cio_pt		; set pointer
			STX cio_pt+1
#ifdef	IOSCREEN
			STX IO8lh		; preset I/O address
			STA IO8ll
#endif
			LDY #0			; reset offset
bs_loop:
				LDA #0		; clear value
#ifndef	IOSCREEN
				STA (cio_pt), Y
#else
				STA IO8wr
#endif
				TYA			; advance offset to next raster
				CLC
				ADC #16
				TAY
#ifdef	IOSCREEN
				CLC			; I/O LSB is offset + base LSB
				ADC cio_pt	; works because no page will cross between rasters!
				STA IO8ll
				TYA			; recheck Y for N flag
#endif
				BPL bs_loop	; offset always below 128 (8x16)
			_DR_OK
cn_nbs:
		CMP #CR				; new line?
		BNE cn_ncr
#ifdef	NMOS
cn_cr:						; NMOS version needs this extra LDA for linewrap
#endif
			LDA fw_ciop		; current position (LSB)
; *** common code with line wrap ***
#ifndef	NMOS
cn_cr:
#endif
			AND #$80		; the actual CR eeeeeeeek
			CLC
			ADC #$80		; then LF
			STA fw_ciop
			BCC cn_cre		; check carry
				INC fw_ciop+1
				BPL cn_cre
; ** this far, no scrolling, just wrap **
					LDA #>pvdu
					STA fw_ciop+1
cn_cre:
			_DR_OK
cn_ncr:
		CMP #DLE			; check for DLE
		BNE cn_ndle
; *** set binary mode ***
			INC fw_cbin		; set binary mode, safe enough if reset with STZ
cn_ndle:
; anything else?
; *** PRINT GLYPH HERE ***
		CMP #32				; check whether printable
		BCC cn_end			; skip if < 32 (we are NOT in binary mode)
cp_do:						; otherwise it is printable, or had received DLE
			ASL				; times eight
			ROL cio_src+1	; M=???????7, A=6543210·
			ASL
			ROL cio_src+1	; M=??????76, A=543210··
			ASL
			ROL cio_src+1	; M=?????765, A=43210···
			CLC
			ADC #<font		; add font base
			STA cio_src
			LDA cio_src+1	; A=?????765
			AND #7			; A=·····765
			ADC #>font
;			DEC				; or add >font -1 if no glyphs for control characters
			STA cio_src+1	; pointer to glyph is ready
			LDA fw_ciop		; get current address
			LDX fw_ciop+1
			STA cio_pt		; set pointer
			STX cio_pt+1
#ifdef	IOSCREEN
			STX IO8lh		; preset I/O address
			STA IO8ll
#endif
			LDY #0			; reset offset
cp_loop:
				_LDAX(cio_src)	; glyph pattern
#ifndef	IOSCREEN
				STA (cio_pt), Y
#else
				STA IO8wr
#endif
				INC cio_src	; advance raster in font data, single byte
				BNE cp_nras
					INC cio_src
cp_nras:
				TYA			; advance offset to next raster
				CLC
				ADC #16
				TAY
#ifdef	IOSCREEN
				CLC			; I/O LSB is offset + base LSB
				ADC cio_pt
				STA IO8ll
				TYA			; recheck Y for N flag
#endif
				BPL cp_loop	; offset always below 128 (8x16)
; advance screen pointer before exit
			INC fw_ciop
			LDA fw_ciop
#ifndef	NMOS
			BIT #%01110000	; check possible linewrap (CMOS, may use AND plus LDA afterwards)
#else
			AND #%01110000
#endif
			BEQ cn_newl
cn_end:
				_DR_OK		; make sure C is clear
cn_newl:
#ifdef	NMOS
			DEC fw_ciop		; eeeeeek
#else
			DEC
#endif
			BNE cn_cr		; code shared with CR
; *** *** *** *** END OF OLD CODE *** *** *** ***
*/

; **********************
; *** keyboard input ***
; **********************
; IO9 port is read, normally 0
; any non-zero value is stored and returned the first time, otherwise returns empty (C set)
; any repeated characters must have a zero inbetween, 10 ms would suffice (perhaps as low as 5 ms)
cn_in:
	LDY IO9di				; get current data at port
	BEQ cn_empty			; no transfer is in the making
		CPY fw_io9			; otherwise compare with last received
	BEQ cn_ack				; same as last, keep trying
		STY fw_io9			; this is received and different
		_DR_OK				; send received
cn_empty:
	STY fw_io9				; keep clear
cn_ack:
	_DR_ERR(EMPTY)			; set C instead eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek

; **************************************************
; *** table of pointers to control char routines ***
; **************************************************
cio_ctl:
	.word	cn_in			; 0, INPUT mode
	.word	cn_cr			; 1, CR
	.word	cur_l			; 2, cursor left
	.word	cio_prn			; 3 ***
	.word	cio_prn			; 4 ***
	.word	cio_prn			; 5 ***
	.word	cur_r			; 6, cursor right
	.word	cio_bel			; 7, beep
	.word	cio_bs			; 8, backspace
	.word	cn_tab			; 9, tab
	.word	cn_lf			; 10, LF
	.word	cio_up			; 11, cursor up
	.word	cio_ff			; 12, FF clears screen and resets modes
	.word	cn_newl			; 13, newline
	.word	cn_so			; 14, inverse
	.word	cn_si			; 15, true video
	.word	md_dle			; 16, DLE, set flag
	.word	cio_cur			; 17, show cursor position
	.word	md_col			; 18, IGNORE following colour
	.word	ignore			; 19, ignore XOFF (as there is no cursor to hide)
	.word	md_col			; 20, IGNORE following colour
	.word	cio_home		; 21, home (what is done after CLS)
	.word	cio_prn			; 22 ***
	.word	md_atyx			; 23, ATYX will set cursor position
	.word	cio_prn			; 24 ***
	.word	cio_prn			; 25 ***
	.word	cio_prn			; 26 ***
	.word	cio_prn			; 27 ***
	.word	cio_prn			; 28 ***
	.word	cio_prn			; 29 ***
	.word	cio_prn			; 30 ***
	.word	ignore			; 31, IGNORE back to text mode

; *** table of pointers to multi-byte routines ***
cio_mbm:
	.word	md_std			; 2= ink or paper to be set, just to IGNORE the second byte
	.word	cn_sety			; 4= Y to be set, then advance mode to 6
	.word	cn_atyx			; 6= X to be set and return to normal

font:
#include "../../drivers/fonts/8x8.s"
.)
