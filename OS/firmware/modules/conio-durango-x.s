; firmware module for minimOS
; Durango-X firmware console 0.9.6a1
; 16x16 text 16 colour _or_ 32x32 text b&w
; (c) 2021 Carlos J. Santisteban
; last modified 20210727-1936

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
; first two modes are directly processed, note BM_DLE is the shifted X
#define	BM_CMD		0
#define	BM_DLE		32
; these modes are handled by indexed jump, note offset of 2
#define	BM_INK		2
#define	BM_PPR		4
#define	BM_ATY		6
#define	BM_ATX		8

; define custom initial ink, change as desired
#define	STD_INK		15
; define custom initial paper, but zero is recommended as might be reused for variable resetting!
#define	STD_PPR		0

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
	ASL						; times eight scanlines
	ROL cio_src+1			; M=???????7, A=6543210·
	ASL
	ROL cio_src+1			; M=??????76, A=543210··
	ASL
	ROL cio_src+1			; M=?????765, A=43210···
	CLC
	ADC fw_fnt				; add font base
	STA cio_src
	LDA cio_src+1			; A=?????765
	AND #7					; A=·····765
	ADC fw_fnt+1
;	DEC						; or add >font -1 if no glyphs for control characters
	STA cio_src+1			; pointer to glyph is ready
	LDA fw_ciop				; get current address
	LDX fw_ciop+1
	STA cio_pt				; set pointer
	STX cio_pt+1
	LDY #0					; reset screen offset (common)
; *** now check for mode and jump to specific code ***
	LDX fw_hires			; check mode, code is different, will only check d7 in case other flags get used
	BPL cpc_do				; skip to colour mode, hires is smaller
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
		ADC #32				; 32 bytes/raster EEEEEEEEK (2)
		TAY					; offset ready (2)
		BPL cph_loop		; offset always below 128 (8x16, 3t)
	BMI cur_r				; advance to next position!
; colour version, 59b, typically 1895t (56/1823 if in ZP, 4% faster)
cpc_do:
		_LDAX(cio_src)		; glyph pattern (5)
		STA fw_tmp			; consider impact of putting this on ZP *** (4*)
		LDX #4				; each glyph byte takes 4 screen bytes! (2)
		INC cio_src			; advance to next glyph byte (5+usually 3)
		BNE cpc_loop
			INC cio_src+1
cpc_loop:					; (all loop is done 4x52, 207t)
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
			ORA fw_ppr		; bit OFF means PAPER
cpc_msk:
			EOR fw_mask		; in case inverse mode is set (4)
			STA (cio_pt), Y	; put it on screen (5)
			INY				; next screen byte for this glyph byte (2)
			DEX				; glyph byte done? (2+3)
			BNE cpc_loop
		TYA					; advance to next screen raster, but take into account the 4-byte offset (2+2+2)
		CLC
		ADC #60
		TAY					; offset ready (2)
		BNE cpc_do			; offset will get zeroed for colour (8x32) (3, like all code is done 8x)
; advance screen pointer before exit, just go to cursor-right routine!
;	JMP cur_r				; no need for jump if cursor-right is just here!

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
; *** support routines ***
; ************************
ck_wrap:
; check for line wrap
; address format is 011yyyys-ssxxxxpp (colour), 011yyyyy-sssxxxxx (hires)
; thus appropriate masks are %11100000 for hires and %11000000 in colour... but it's safer to check MSB's d0 too!
	LDY #%11100000			; hires mask
	LDX fw_hires			; check mode
	BMI wr_hr				; OK if we're in hires
#ifdef	SAFE
		LDA fw_ciop+1		; check MSB
		LSR					; just check d0, clears C
			BNE cn_begin	; strange scanline, thus time for the NEWLINE (Y>1)
#endif
		LDY #%11000000		; in any case, get proper mask for colour mode
wr_hr:
	TYA						; prepare mask and guarantee Y>1 for auto LF
	AND fw_ciop				; are scanline bits clear?
		BNE cn_begin		; nope, do NEWLINE
	RTS						; continue normally otherwise (should I clear C?)

; ************************
; *** control routines ***
; ************************
cn_cr:
; this is the CR without LF
	LDY #1					; will skip LF routine
	BNE cn_begin

cur_l:
; cursor left, no big deal, but do not wrap if at leftmost column
; colour mode subtracts 4, but only 1 if in hires
; only if LSB is not zero, assuming non-corrupted scanline bits
; could use N flag after subtraction, as clear scanline bits guarantee its value
	LDA #1					; hires decrement
	LDX fw_hires
	BPL cl_hr				; right mode for the decrement
		LDA #4				; otherwise use colour value
cl_hr:
	SEC
	SBC fw_ciop				; subtract to pointer, but...
	BMI cl_end				; ...ignore operation if went negative
		STA fw_ciop			; update pointer
cl_end:
	_DR_OK					; C known to be set, though

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
#ifdef	NMOS
		LDA fw_ciop+1		; clear MSB lowest bit (8b/10t)
		AND #254
		STA fw_ciop+1
#else
		LDA #1				; bit to be cleared (5b/7t)
		TRB fw_ciop+1		; nice...
#endif
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
; ** scroll routine **
; rows are 256 bytes apart in hires mode, but 512 in colour mode
	LDY #<pvdu				; LSB *must* be zero, anyway
	LDX #>pvdu				; MSB is actually OK for destination
	STY cio_pt				; set both LSBs
	STY cio_src
	STX cio_pt+1			; destination is set
	INX						; note trick for NMOS-savvyness
	LDA fw_hires			; check mode anyway
	BMI sc_hr				; +256 is OK for hires
		INX					; make it +512 for colour
sc_hr:
	STX cio_src+1			; we're set
;	LDY #0					; in case pvdu is not page-aligned!
sc_loop:
		LDA (cio_src), Y	; move screen data ASAP
		STA (cio_pt), Y
		INY					; do a whole page
		BNE sc_loop
			INC cio_pt+1	; both MSBs are incremented at once...
			INC cio_src+1	; ...but only source will enter high-32K at the end
		BPL sc_loop
; data has been transferred, now should clear the last line
	JSR cio_clear			; cannot be inlined!
; important, cursor pointer must get back one row up! that means subtracting one (or two) from MSB
	TXA						; trick... A is fw_hires
	ASL						; now C is set for hires
	LDA fw_ciop+1			; cursor MSB
	SBC #1					; with C set (hires) this subtracts 1, but 2 if C is clear! (colour)
	STA fw_ciop+1
cn_ok:
	_DR_OK					; note that some code might set C

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
	JMP ck_wrap				; will return in any case

cio_bel:
; BEL, make a beep!
; 40ms @ 1 kHz is 40 cycles
; the 500µs halfperiod is about 325t
	_CRITIC					; let's make things the right way
	LDX #79					; 80 half-cycles, will end with d0 clear
cbp_pul:
		STX IOBeep			; pulse output bit (4)
		LDY #63				; should make around 500µs halfcycle (2)
cbp_del:
			DEY
			BNE cbp_del		; each iteration is (2+3)
		DEX					; go for next semicycle
		BPL cbp_pul			; must do zero too, to clear output bit
	_NO_CRIT				; eeeeek
	RTS

cio_bs:
; BACKSPACE, go back one char and clear cursor position
	JSR cur_l				; back one char, if possible, then clear cursor position
	LDY fw_ciop
	LDA fw_ciop+1			; get current cursor position...
	STY cio_pt
	STA cio_pt+1			; ...into zp pointer
	LDX #8					; number of scanlines...
	STX fw_ctmp				; ...as temporary variable (seldom used)
; load appropriate A value (clear for hires, paper index repeated for colour)
	LDA fw_hires			; check mode
	ROL						; C set in hires
	LDA #0					; A should be zero in hires, but ignore any other flags...
	TAX						; so should be last index offset, for hires!
	LDY #31					; this is what must be added to Y each scanline, in hires
	BCS bs_hr
		LDA fw_ppr			; but the paper colour otherwise
		ASL
		ASL
		ASL
		ASL
		ORA fw_ppr
		LDX #3				; last index offset per scan (colour)
		LDY #60				; this is what must be added to Y each scanline, in colour
bs_hr:
	STX cio_src				; another temporary variable
	STY cio_src+1			; this is most used, thus must reside in ZP
	LDY #0					; eeeeeeeeek *** must be revised for picoVDU
bs_scan:
			STA (cio_pt), Y	; clear screen byte
			INY				; advance, just in case
			DEX				; one less in a row
			BPL bs_scan
		LDX cio_src			; reload this counter
		PHA					; save screen value!
		TYA
		CLC
		ADC cio_src+1		; advance offset to next scanline
		TAY
		BCC bs_scw
			INC cio_pt+1	; colour mode will cross page
bs_scw:
		PLA					; retrieved value, is there a better way?
		DEC fw_ctmp			; one scanline less to go
		BNE bs_scan
	_DR_OK					; should be done

cio_up:
; cursor up, no big deal, will stop at top row
; preliminary version (27+2b CMOS(+NMOS), 35+2t hires/45+4t colour)
; could be +1b, +2t if CLC is needed
;	LDA #%00011111			; mask for hires
;	LDY #1					; MSB increment for hires
;	LDX fw_hires			; check mode, in order to discard LSB
;	BMI cu_hr				; mask is valid for hires
;		LDA #%00011110		; otherwise load colour mask
;		INY					; now Y=2 saving one byte
;cu_hr:
;	AND fw_ciop+1			; current cursor position is now 000rrrrR, R for hires only
;	BEQ cu_end				; if at top of screen, ignore cursor
;cu_dloop:
;			_DEC			; one less, not very efficient but no big deal either
;			DEY
;			BNE cu_dloop
;		ORA #%01100000		; EEEEEEK must complete pointer address (5b, 6t)
;		STA fw_ciop+1
;cu_end:
;	RTS						; not sure if C guaranteed clear!

; alternative (NMOS savvy, always 23b and 39t)
	LDA fw_hires			; check mode
	ROL						; now C is set in hires!
	PHP						; keep for later?
	LDA #%00001111			; incomplete mask...
	ROL						; but now is perfect! C is clear
	PLP						; hires mode will set C again but do it always! eeeeeeeeeeek
	AND fw_ciop+1			; current row is now 000rrrrR, R for hires only
	BEQ cu_end				; if at top of screen, ignore cursor
		SBC #1				; this will subtract 1 if C is set, and 2 if clear! YEAH!!!
		ORA #%01100000		; EEEEEEK must complete pointer address (5b, 6t)
		STA fw_ciop+1
cu_end:
	_DR_OK					; ending this with C set is a minor nitpick, must reset anyway

; FF, clear screen AND intialise values!
cio_ff:
; note that firmware must set fw_hires AND hardware register appropriately at boot!
; we don't want a single CLS to switch modes, although a font reset is acceptable, set it again afterwards if needed
; * things to be initialised... *
; fw_ink
; fw_paper (possibly not worth combining)
; fw_fnt (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_cbin (binary or multibyte mode)

	_STZA fw_cbin			; standard, character mode
	_STZA fw_mask			; true video
	_STZA fw_ppr			; black background (ignored in hires)
; might use STA and LDA # with desired background colour, instead of the above
;	LDA #STD_PPR
;	STA fw_ppr
	LDA #STD_INK			; white foreground or as desired
	STA fw_ink				; ignored in hires
	LDY #>font				; standard font address
	LDA #<font
	STY fw_fnt				; set firmware pointer (will need that again after FF)
	STA fw_fnt+1
; standard CLS, reset cursor and clear screen
	JSR cio_home			; reset cursor and load appropriate address
	STY cio_pt				; set pointer (LSB=0)...
	STA cio_pt+1
;	LDY #0					; usually not needed if screen is page-aligned!
;	JMP cio_clear			; ...and clear whole screen, will return to caller
cio_clear:
; ** generic screen clear-to-end routine, just set cio_pt with initial address and Y to zero **
; this works because all character rows are page-aligned
; otherwise would be best keeping pointer LSB @ 0 and setting initial offset in Y, plus LDA #0
; anyway, it is intended to clear whole rows
	TYA						; A should be zero in hires...
	LDX fw_hires
	BMI sc_clr				; eeeeeeeeek
		LDA fw_ppr			; but the paper colour otherwise
		ASL
		ASL
		ASL
		ASL
		ORA fw_ppr
sc_clr:
		STA (cio_pt), Y		; clear all remaining bytes
		INY
		BNE sc_clr
			INC cio_pt+1
		BPL sc_clr			; colour mode needs an extra page to clear
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

cio_cur:
; XON, we have no cursor, but show its position for a moment
; at least a full frame (40 ms or ~62kt)
	LDY fw_ciop				; get current position pointer
	LDX fw_ciop+1
	STY cio_pt
	LDY #224				; offset for last scanline at cursor position... in hires
	LDA fw_hires			; are we in colour mode? that offset won't be valid!
	BMI ccur_ok				; hires mode, all OK
		INX					; otherwise, must advance pointer MSB
		LDY #192			; new LSB offset
ccur_ok:
	STX cio_pt+1			; pointer complete
	JSR xon_inv				; invert current contents (will return to caller the second time!)
	TYA						; keep this offset!
	LDY #49					; about 40 ms, or a full frame
xon_del:
			INX
			BNE xon_del		; each iteration is (2+3), for full X is near 1.28kt
		DEY					; go for next cycle
		BNE xon_del
	TAY						; retrieve offset
xon_inv:
	LDA (cio_pt), Y			; revert to original
	EOR #$FF
	STA (cio_pt), Y
ignore:
	RTS						; *** note generic exit ***

cio_home:
; just reset cursor pointer, to be done after (or before!) CLS
	LDY #<pvdu				; base address for all modes, actually 0
	LDA #>pvdu
	STY fw_ciop				; just set pointer
	STA fw_ciop+1
	RTS						; C is clear, right?

; *******************************
; *** some multibyte routines ***
; *******************************
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
#ifdef	SAFE
	CMP #32					; check for not-yet-supported pixel coordinates
		BCC not_px			; must be at least 32, remember stack balance!
#endif
	AND #31					; filter coordinates, note +32 offset is deleted as well
	LDX fw_hires			; if in colour mode, further filtering
	BMI do_set
		AND #15				; max colour coordinate
do_set:
	RTS						; if both coordinates setting is combined, could be inlined

#ifdef	SAFE
not_px:
; must ignore pixel coordinates, just rounding up to character position
	PLA
	PLA						; discard coordinate checking return address!
	RTS						; that's all, as C known clear
#endif

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
	.word	md_ink			; 18, set ink from next char
	.word	ignore			; 19, ignore XOFF (as there is no cursor to hide)
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
	.word	ignore			; 31, IGNORE back to text mode

; *** table of pointers to multi-byte routines ***
cio_mbm:
	.word	cn_ink			; 2= ink to be set
	.word	cn_ppr			; 4= paper to be set
	.word	cn_sety			; 6= Y to be set, advance mode to 8
	.word	cn_atyx			; 8= X to be set and return to normal

font:
#include "../../drivers/fonts/8x8.s"
.)
