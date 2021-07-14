; firmware module for minimOS
; Durango-X firmware console 0.9.6a1
; 16x16 text 16 colour _or_ 32x32 text b&w
; (c) 2021 Carlos J. Santisteban
; last modified 20210715-0105

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
;		9	= TAB (x+8 AND 248 in any case)
;		10	= line feed (cursor down, direct jump needs no Y set)
;		11	= cursor up
;		12	= clear screen AND initialise device
;		13	= newline (actually LF after CR, eg. set Y to two or more so DEY clears Z and does LF)
;		14	= inverse video
;		15	= true video
;		16	= DLE, do not execute next control char
;		18	= set ink colour (MOD 16 in colour mode, MOD 2 in hires)*
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
;		17	= cursor on (no cursor yet?) _might show current position for a split second_
;		19	= cursor off (no cursor yet?)
;		22	= page down (?)
;		24	= backtab
;		25	= page up (?)
;		26	= switch focus (?)
;		27	= escape (?)
;		28...30	= Tektronix graphic commands
;	OUTPUT
; C ->	no available char (if Y was 0)

#include "../../usual.h"

; *** zeropage variables ***
; cio_src.w (pointer to glyph definitions)
; cio_pt.w (screen pointer)

; *** firmware variables to be reset upon FF ***
; fw_ink
; fw_paper (possibly not worth combining)
; fw_ciop.w (upper scan of cursor position)
; fw_fnt (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_hires (0=colour, 128=hires)
; fw_cbin (binary or multibyte mode)
; fw_ctmp (temporary use)
; first two modes are directly processed, note BM_BLE is the shifted X
#define	BM_CMD		0
#define	BM_DLE		32
; these modes are handled by indexed jump, note offset of 2
#define	BM_INK		2
#define	BM_PPR		4
#define	BM_ATY		6
#define	BM_ATX		8

.(
pvdu	= $6000				; base address
IO9di	= $9FFF				; data input (TBD)
IO8attr	= $8000				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE)
IOBeep	= $BFF0				; canonical buzzer address (d0)

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
; ***********************************
; *** output character (now in A) ***
; ***********************************
			ASL				; times eight scanlines
			ROL cio_src+1	; M=???????7, A=6543210·
			ASL
			ROL cio_src+1	; M=??????76, A=543210··
			ASL
			ROL cio_src+1	; M=?????765, A=43210···
			CLC
			ADC fw_fnt		; add font base
			STA cio_src
			LDA cio_src+1	; A=?????765
			AND #7			; A=·····765
			ADC fw_fnt+1
;			DEC				; or add >font -1 if no glyphs for control characters
			STA cio_src+1	; pointer to glyph is ready
			LDA fw_ciop		; get current address
			LDX fw_ciop+1
			STA cio_pt		; set pointer
			STX cio_pt+1
			LDY #0			; reset screen offset (common)
; *** now check for mode and jump to specific code ***
			LDX fw_hires	; check mode, code is different, will only check d7 in case other flags get used
			BPL cpc_do		; skip to colour mode, hires is smaller
; hires version (17b for CMOS, usually 231t, plus jump to cursor-right)
cph_loop:
				_LDAX(cio_src)		; glyph pattern (5)
				STA (cio_pt), Y		; put it on screen, note variable pointer (5)
				INC cio_src			; advance to next glyph byte (5)
				BNE cph_nw_nw		; (usually 3, rarely 7)
					INC cio_src+1
cph_nw:
				TYA					; advance to next screen raster (2+2)
				CLC
				ADC #16				; 16 bytes/raster (2)
				TAY					; offset ready (2)
				BPL cph_loop		; offset always below 128 (8x16, 3t)
			BMI cur_r				; advance to next position!
; colour version, 59b, typically 1895t (56/1823 if in ZP, 4% faster)
; if glyph pattern is	g7g6g5g4g3g2g1g0...
; and ink is			· · · · i3i2i1i0...
; and paper is			· · · · p3p2p1p0...
; must write 4 bytes...
; (Xyz=Iz if Gy is 1, Pz otherwise)
; X73X72X71X70X63X62X61X60
; X53X52X51X50X43X42X41X40
; X33X32X31X30X23X22X21X20
; X13X12X11X10X03X02X01X00
cpc_do:
				_LDAX(cio_src)		; glyph pattern (5)
				STA fw_tmp			; consider impact of putting this on ZP *** (4*)
				LDX #4				; each glyph byte takes 4 screen bytes! (2)
				INC cio_src			; advance to next glyph byte (5+usually 3)
				BNE cpc_loop
					INC cio_src+1
cpc_loop:							; (all loop is done 4x52, 207t)
					ASL fw_tmp		; extract leftmost bit from temporary glyph (6*)
					BCC cpc_pl
						LDA fw_ink	; bit ON means INK (in this case, 2+4+3=9)
						BCS cpc_rot
cpc_pl:
						LDA fw_ppr	; bit OFF means PAPER (otherwise, 3+4=7; average 8)
cpc_rot:
					ASL
					ASL
					ASL
					ASL				; colour code is now upper nibble (2+2+2+2)
					ASL fw_tmp		; extract next bit from temporary glyph (6*)
					BCC cpc_pr		; ditto for rightmost nibble (average 8)
						ORA fw_ink	; bit ON means INK
						BCS cpc_msk
cpc_pr:
						ORA fw_ppr	; bit OFF means PAPER
cpc_msk:
					EOR fw_mask		; in case inverse mode is set (4)
					STA (cio_pt), Y	; put it on screen (5)
					INY				; next screen byte for this glyph byte (2)
					DEX				; glyph byte done? (2+3)
					BNE cpc_loop
				TYA					; advance to next screen raster, but take into account the 4-byte offset (2+2+2)
				CLC
				ADC #28
				TAY					; offset ready (2)
				BNE cpc_do			; offset will get zeroed for colour (8x32) (3, like all code is done 8x)
; advance screen pointer before exit, just go to cursor-right routine!
;			JMP cur_r		; no need for jump if cursor-right is just here!

; **********************
; *** cursor advance *** placed here for convenience of printing routine
; **********************
cur_r:
	LDA #1					; base character width (in bytes) for hires mode
	LDX fw_hires			; check mode
	BMI rcu_hr				; already OK if hires
		LDA #4				; ...or use value for colour mode
rcu_hr:
	CLC
	ADC fw_ciop				; advance pointer
	BNE rcu_nw				; check possible carry
		INC fw_ciop+1
rcu_nw:
	JMP ck_wrap				; ...will return



; *** legacy code just for reference
;		AND #$7F			; in order to strip extended ASCII
; no longer checks control chars here, just glyph!
/*		CMP #FORMFEED		; reset device?
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
cls_l:
					STA (cio_pt), Y	; clear screen byte
					INY
					BNE cls_l		; continue within page
				INC cio_pt+1
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
			LDY #0			; reset offset
bs_loop:
				LDA #0		; clear value
				STA (cio_pt), Y
				TYA			; advance offset to next raster
				CLC
				ADC #16
				TAY
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
*/

; **********************
; *** keyboard input *** may be moved elsewhere
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

; ************************
; *** control routines ***
; ************************
cn_cr:
; this is the CR without LF
	LDY #1					; will skip LF routine
	BNE cn_begin

cn_newl:
; CR, but will do LF afterwards by setting Y appropriately
		TAY					; Y=13>1, thus allows full newline
cn_begin:
; do CR... but keep Y
; note address format is 011yyyys-ssxxxxpp (colour), 011yyyyy-sssxxxxx (hires)
; make LSB AND %11110000 (hires) / %11000000 (colour)
; actually is a good idea to clear scanline bits, just in case
	_STZA fw_ciop			; all must clear! helps in case of tab wrapping too (eeeeeeeeek...)
; in colour mode, the highest scanline bit is in MSB, usually (TABs, wrap) not worth clearing
; ...but might help with unexpected mode change
#ifdef	SAFE
	LDX fw_hires			; was it in hires mode?
	BMI cn_lmok
		LDA fw_ciop+1		; clear MSB lowest bit
		AND #254
		STA fw_ciop+1
cn_lmok:
#endif
; check whether LF is to be done
	DEY						; LF needed?
	BEQ cn_ok				; not if Y was 1 (use BMI if Y was zeroed for LF)
; *** will do LF if Y>1 ONLY ***
cn_lf:
; do LF, adds 1 (hires) or 2 (colour) to MSB
; even simpler, INCrement MSB once... or two if in colour mode
; hopefully highest scan bit is intact!!!
	INC fw_ciop+1			; increment MSB accordingly, this is OK for hires
	LDX fw_hires			; was it in hires mode?
	BMI cn_hmok
		INC fw_ciop+1		; once again if in colour mode... 
cn_hmok:
; must check for possible scrolling!!! simply check sign ;-)
	BPL cn_ok				; positive means no scroll
; *** TBD TBD TBD ***
cn_ok:
	RTS	; note that some TAB wrapping might set C

cn_tab:
; advance column to the next 8x position (all modes)
; this means adding 8 to LSB in hires mode, or 32 in colour mode
; remember format is 011yyyys-ssxxxxpp (colour), 011yyyyy-sssxxxxx (hires)
	LDA #%11111000			; hires mask first
	STA fw_ctmp				; store temporarily
	LDA #8					; lesser value in hires mode
	LDX fw_hires			; check mode
	BMI hr_tab				; if in hires, A is already correct
		ASL fw_ctmp
		ASL fw_ctmp			; shift mask too, will set C
		ASL
		ASL					; but this will clear C in any case
hr_tab:
	ADC fw_ciop				; this is LSB, contains old X...
	AND fw_ctmp				; ...but round down position from the mask!
	STA fw_ciop
; not so fast, must check for possible line wrap... and even scrolling!
; must use a subroutine for this, as cur-right needs it too!!! *************** already done?
	LDY #%11100000			; hires scanline mask
	LDX fw_hires			; check mode
	BMI tw_hr				; mask is OK for hires, and no need to look at MSB
#ifdef	SAFE
		LDA fw_ciop+1		; have a look at highest scan bit!
		LSR					; ...which is lowest MSB
			BCS cn_begin	; just a normal NEWLINE (Y>1, but C is set)(consider AND#1,BNE)
#endif
		LDY #%11000000		; fix it otherwise, ASL is not worth as sets C (same bytes)
tw_hr:
	TYA						; guaranteed Y>1 in any case
	AND fw_ciop				; is any of the scanline bits high? must wrap!     
		BNE cn_begin		; just a normal NEWLINE (Y>1, cannot guarantee A)
	RTS

; SO, set inverse mode
cn_so:
	LDA #$FF				; OK for all modes?
	STA fw_mask				; set value to be EORed
	RTS

; SI, set normal mode
cn_si:
	_STZA fw_mask			; clear value to be EORed
	RTS

md_dle:
; DLE, set binary mode
;	LDX #BM_DLE				; already set if 32
	STX fw_cbin				; set binary mode and we are done
	RTS

; *** some multibyte routines ***
cn_ink:						; 2= ink to be set
	AND #15					; even if hires will just use d0, keep whole value for this hardware
	STA fw_ink
md_std:
	_STZA fw_cbin			; back to standard mode
	RTS

cn_ppr:						; 4= paper to be set
	AND #15					; same as ink
	STA fw_ppr				; could use some trickery to use a common routine taking X as index
	_BRA md_std

cn_sety:					; 6= Y to be set, advance mode to 8
	JSR coord_ok			; common coordinate check as is a square screen
	STA fw_ciop+1			; note temporary use of MSB as Y coordinate
	LDX #BM_ATX
	STA fw_cbin				; go into X-expecting mode
	RTS

coord_ok:
	AND #31					; filter coordinates, note +32 offset is deleted as well
	LDX fw_hires			; if in colour mode, further filtering
	BMI do_set
		AND #15				; max colour coordinate
do_set:
	RTS						; if both coordinate setting combined, could be inlined

cn_atyx:					; 8= X to be set and return to normal
	JSR coord_ok
	LDX fw_hires			; if in colour mode, each X is 4 bytes ahead
	BMI do_atx
		ASL
		ASL
		ASL fw_ciop+1		; THIS IS BAD *** KLUDGE
		ASL fw_ciop+1
do_atx:
	STA fw_ciop				; THIS IS BAD *** KLUDGE
	LDA fw_ciop+1			; add to recomputed offset the VRAM base address
;	CLC
	ADC #>pvdu
	STA fw_ciop+1
	_BRA md_std

; *** support routines ***
ck_wrap:
; check for line wrap
; pointer LSB *MUST* be x000xxxx in colour mode, 000xxxxx in hires **** NOOOOO *** CHECK ASAP ******
	LDA #%11100000			; binary mask for hires
	LDX fw_hires
	BMI wr_ok				; if in colour mode, shift mask accordingly
		LSR					; C remains clear
wr_ok:
	TAY						; keep this mask just in case
	AND fw_ciop				; check scanline bits in pointer LSB
	BEQ no_wrap				; all zero, no wrapping
		TYA					; otherwise, retrieve mask...
		EOR #$FF			; ...reversed
		AND 
no_wrap:
	RTS						; is this OK? C clear?

; **************************************************
; *** table of pointers to control char routines ***
; **************************************************
cio_ctl:
	.word	cn_in			; 0, INPUT mode
	.word	cn_cr			; 1, CR
	.word	; 2, cursor left
	.word	cio_prn			; 3 ***
	.word	cio_prn			; 4 ***
	.word	cio_prn			; 5 ***
	.word	cur_r			; 6, cursor right
	.word	; 7, beep
	.word	; 8, backspace
	.word	cn_tab			; 9, tab
	.word	cn_lf			; 10, LF
	.word	; 11, cursor up
	.word	; 12, FF clears screen and resets modes
	.word	cn_newl			; 13, newline
	.word	cn_so			; 14, inverse
	.word	cn_si			; 15, true video
	.word	md_dle			; 16, DLE, set flag
	.word	cio_prn			; 17 ***
	.word	md_ink			; 18, set ink from next char
	.word	cio_prn			; 19 ***
	.word	md_ppr			; 20, set paper from next char
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
	.word	cn_end			; 31, IGNORE back to text mode

; *** table of pointers to multi-byte routines ***
cio_mbm:
	.word	cn_ink			; 2= ink to be set
	.word	cn_ppr			; 4= paper to be set
	.word	cn_sety			; 6= Y to be set, advance mode to 8
	.word	cn_atyx			; 8= X to be set and return to normal

font:
#include "../../drivers/fonts/8x8.s"
.)
