; firmware module for minimOS
; Chihuahua firmware console 0.9.6b12
; for picoVDU 32x32 text b&w
; (c) 2021-2024 Carlos J. Santisteban
; last modified 20240527-1220

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
;		17	= cursor on [NEW]
;		18	= set ink colour [IGNORED]*
;		19	= cursor off [NEW]
;		20	= set paper colour [IGNORED]*
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
; Y -> input char (if Y was 0)

; *** zeropage variables *** standard OS
; cio_src.w (pointer to glyph definitions)
; cio_pt.w (screen pointer)

; *** other variables, perhaps in ZP ***
; fw_cbyt (temporary glyph storage)
; fw_ccnt (another temporary storage) *** NO LONGER USED
; fw_chalf (remaining pages to write)

; *** firmware variables to be reset upon FF ***
; no more fw_ccol.p
; fw_ciop.w (upper scan of cursor position)
; fw_fnt.w (pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_cbin (binary or multibyte mode, must be reset prior to first use)
; fw_vbot (first VRAM page, but no real screen switching upon FF)
; fw_vtop (first non-VRAM page, but no real screen switching upon FF)
; fw_scur ([NEW] flag D7=cursor ON)

; *** experimental BOLD emphasis instead of inverse ***
;#define	SO_BOLD

; first two modes are directly processed, note BM_DLE is the shifted X
#define	BM_CMD		0
#define	BM_DLE		32
; these modes are handled by indexed jump, note offset of 2
#define	BM_INK		2
#define	BM_PPR		4
#define	BM_ATY		6
#define	BM_ATX		8

; initial colours already defined in init file
.(
;-kb_asc	= $020A				; standard keyboard driver address

	TYA						; is going to be needed here anyway
	LDX fw_cbin				; check whether in binary/multibyte mode
	BEQ cio_cmd				; if not, check whether command (including INPUT) or glyph
		CPX #BM_DLE			; just receiving what has to be printed?
	BEQ cio_gl				; print the glyph!
; *** beware, multibyte commands CANNOT receive 0, keep mode but jump to input routine instead ***
		TYA					; * check parameter again
	BEQ cio_cmd				; * no zero for multibyte, just process as usual (will go into input)
		_JMPX(cio_mbm-2)	; otherwise process following byte as expected, note offset
cio_cmd:
	CMP #32					; printable anyway?
	BCS cio_prn				; go for it, flag known to be clear
		ASL					; if arrived here, it MUST be below 32! two times
		TAX					; use as index
		CLC					; will simplify most returns as DR_OK becomes just RTS
		_JMPX(cio_ctl)		; execute from table
cio_gl:
	_STZX fw_cbin			; clear flag!
cio_prn:
; ***********************************
; *** output character (now in A) ***
; ***********************************
; *** should check here for procrastinated scroll!
	PHA
	JSR chk_scrl
	PLA
; actual glyph printing procedure
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
	ADC fw_fnt+1			; in case no glyphs for control codes, this must hold actual MSB-1
	STA cio_src+1			; pointer to glyph is ready
	LDY fw_ciop				; get current address
	LDA fw_ciop+1
	STY cio_pt				; set pointer
	STA cio_pt+1
	LDY #0					; reset screen offset (common)
; hires version (17b for CMOS, usually 231t, plus jump to cursor-right)
cph_loop:
			_LDAX(cio_src)	; glyph pattern (5)
#ifndef	SO_BOLD
			EOR fw_mask		; in case inverse mode is set, much better here (4)
#else
			LSR				; shift left...
			AND fw_mask		; ...but only in case we're in SHIFT OUT
			ORA (cio_src)	; CMOS only, would get original byte in any case
#endif
			STA (cio_pt), Y	; put it on screen (5)
			INC cio_src		; advance to next glyph byte (5)
			BNE cph_nw		; (usually 3, rarely 7)
				INC cio_src+1
cph_nw:
			TYA				; advance to next screen raster (2+2)
			CLC
			ADC #32			; 32 bytes/raster EEEEEEEEK (2)
			TAY				; offset ready (2)
			BNE cph_loop	; offset will just wrap at the end EEEEEEEK (3)
; ...but should NOT delete (XOR) previous cursor, as has disappeared while printing
		BEQ cio_inx			; advance cursor without clearing previous

; ************************
; *** support routines ***
; ************************
cio_inx:
; *** advance one character position ***
	LDA #1					; base character width (in bytes) for hires mode
	CLC
	ADC fw_ciop				; advance pointer
	STA fw_ciop				; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
	BCC rcu_nw				; check possible carry
		INC fw_ciop+1
rcu_nw:						; will return
;	RTS

ck_wrap:
; *** check for line wrap ***
; address format is 011yyyyy-sssxxxxx (hires)
; thus appropriate mask is %11100000 for hires... but it's safer to check MSB's d0 too!
	LDY #%11100000			; hires mask
	TYA						; prepare mask and guarantee Y>1 for auto LF
	AND fw_ciop				; are scanline bits clear?
		BNE do_cr			; was cn_begin		; nope, do NEWLINE
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_ckw
		JSR draw_cur		; ...must draw new one
do_ckw:
	_DR_OK					; continue normally otherwise (better clear C)

chk_scrl:
; *** *** new scroll check *** ***
; simply compare against dynamic limit
	LDA fw_ciop+1			; EEEEEK
	CMP fw_vtop
	BCC cn_ok				; below limit means no scroll, safer?
; ** scroll routine **
; rows are 256 bytes apart in hires mode, but 512 in colour mode
		LDY #<0				; LSB *must* be zero, anyway
; MSB is actually OK for destination, but take from current value
		LDX fw_vbot
		STY cio_pt			; set both LSBs
		STY cio_src
		STX cio_pt+1		; destination is set
		INX					; note trick for NMOS-savvyness
sc_hr:
		STX cio_src+1		; we're set, worth keep incrementing this
;		LDY #0				; in case pvdu is not page-aligned!
sc_loop:
			LDA (cio_src), Y	; move screen data ASAP
			STA (cio_pt), Y
			INY				; do a whole page
			BNE sc_loop
		INC cio_pt+1		; both MSBs are incremented at once...
		INX					; ...but only source will enter high-32K at the end
		CPX fw_vtop			; ...or whatever the current limit is
			BNE sc_hr
; data has been transferred, now should clear the last line
		JSR cio_clear		; cannot be inlined! Y is 0
; important, cursor pointer must get back one row up! that means subtracting one (or two) from MSB
		LDA IO8attr			; eeeeeek
		ASL					; now C is set for hires
		LDA fw_ciop+1		; cursor MSB
		SBC #1				; with C set (hires) this subtracts 1, but 2 if C is clear! (colour)
		STA fw_ciop+1
; *** end of actual scrolling routine
		BIT fw_scur				; if cursor is on... [NEW]
		BPL cn_ok
			JSR draw_cur		; ...must draw new one
cn_ok:
	RTS

; ************************
; *** control routines ***
; ************************
cn_newl:
; * * CR, but will do LF afterwards by setting Y appropriately * *
	TAY						; Y=26>1, thus allows full newline
	JSR cn_begin			; do CR+LF and actually scroll if needed
	JMP chk_scrl			; will return

cn_lf:
; * * do LF * *, adds 1 (hires) to MSB
	JSR cur_lf				; do actual LF...
	JMP chk_scrl			; ...check and return

cn_cr:
; * * this is the CR without LF * *
	LDY #1					; will skip LF routine
;	BNE cn_begin

cn_begin:
; *** do CR... but keep Y ***
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cr
		PHY					; CMOS only eeeeeek
		JSR draw_cur		; ...must delete previous one
		PLY
do_cr:
; note address format is 011yyyyy-sssxxxxx (hires)
; actually is a good idea to clear scanline bits, just in case
	_STZA fw_ciop			; all must clear! helps in case of tab wrapping too (eeeeeeeeek...)
; check whether LF is to be done
	DEY						; LF needed?
		BEQ cn_hmok			; not if Y was 1 (use BMI if Y was zeroed for LF)
; *** will do LF if Y was >1 ONLY ***
	BNE do_lf				; [NEW]
; actual LF done here
cur_lf:
; even simpler, INCrement MSB once... or two if in colour mode
; hopefully highest scan bit is intact!!!
		BIT fw_scur			; if cursor is on... [NEW]
		BPL do_lf
			JSR draw_cur	; ...must delete previous one
do_lf:
; *** LF must check for procrastinated scroll as well
	INC fw_ciop+1			; increment MSB accordingly, this is OK for hires
cn_hmok:
; *** scroll no longer here
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cnok
		JSR draw_cur		; ...must draw new one
do_cnok:
	_DR_OK					; note that some code might set C

cur_r:
; * * cursor advance * *
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cur_r
		JSR draw_cur		; ...must delete previous one
do_cur_r:
	JSR cio_inx				; advance to next char
;	JSR ck_wrap				; check for line wrap...
	JMP chk_scrl			; ...but scroll if needed, and return

cur_l:
; * * cursor left * * no big deal, but now wraps if at leftmost column
; colour mode subtracts 4, but only 1 if in hires
; only if LSB is not zero, assuming non-corrupted scanline bits
; could use N flag after subtraction, as clear scanline bits guarantee its value
; but check for wrapping otherwise
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cur_l
		JSR draw_cur		; ...must delete previous one
do_cur_l:
	LDA #1					; hires decrement (these 9 bytes are the same as cur_r)
	STA cio_src				; EEEEEEEEEEEK
	SEC
	LDA fw_ciop
	SBC cio_src				; subtract to pointer, but...
; *** new wrap-around code ***
	BPL cl_ok				; positive after subtraction means no wrapping
; otherwise must get up to previous row, not just its bottom scanline
; just clear LSB for HIRES... in colour, clear d0 on MSB as well > actually subtract 2
		LDX fw_ciop+1		; update row into MSB
		DEX
		LDA #$1F			; will reset LSB to rightmost column afterwards (for HIRES)
		CPX fw_vbot			; check if at top of screen... which is bottom of memory
	BCC cl_end				; do nothing if already there
		STX fw_ciop+1		; update MSB as it changed!
cl_ok:
		STA fw_ciop			; update pointer (usually just LSB)
; *** standard code follows ***
cl_end:
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cle
		JSR draw_cur		; ...must draw new one
do_cle:
	_DR_OK					; C known to be set, though

cn_tab:
; * * advance column to the next 8x position * * (all modes)
; this means adding 8 to LSB in hires mode, or 32 in colour mode
; remember format is 011yyyys-ssxxxxpp (colour), 011yyyyy-sssxxxxx (hires)
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_tab
		JSR draw_cur		; ...must delete previous one
do_tab:
	JSR chk_scrl			; check whether procrastinated!
	LDA #%11111000			; hires mask first
	STA fw_ctmp				; store temporarily
	LDA #8					; lesser value in hires mode
	ADC fw_ciop				; this is LSB, contains old X...
	AND fw_ctmp				; ...but round down position from the mask!
	STA fw_ciop
; not so fast, must check for possible line wrap... and even scrolling!
	JMP ck_wrap				; will return in any case

cio_bel:
; * * BEL, make a beep! * *
; easier way is to just enable audio output for the T1-IRQ (125 Hz), maybe more than 40 ms
; say, 160 ms is 20 cycles, seems OK
	PHP
	CLI						; enable interrupts, just in case
; should I check for PB7 output?
	LDA VIA+DDRB
	ORA #%10000000			; make sure PB7 is output
	STA VIA+DDRB
; first, turn speaker on
	LDA VIA+ACR
 	TAY						; keep original ACR value
	ORA #%11000000			; change T1 to PB7 square wave, make sure continuous interrupts are on
	STA VIA+ACR
; wait some time while sounding
	LDA ticks				; time reference
	CLC
	ADC #40					; 40x4 = 160 mS later
cb_loop:
		CMP ticks
		BNE cb_loop			; loop until 160 ms have passed
; turn off speaker (faster)
	STY VIA+ACR				; change T1 back to continuous interrupts
	LDA VIA+IORB
	ORA #%10000000			; keep PB7 high, just in case
	STA VIA+IORB
	PLP						; just in case interrupts were shut off
	RTS

cio_bs:
; * * BACKSPACE * * go back one char and clear cursor position
	JSR cur_l				; back one char, if possible, then clear cursor position
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_bs
		JSR draw_cur		; ...must delete previous one
do_bs:
	LDY fw_ciop
	LDA fw_ciop+1			; get current cursor position...
	STY cio_pt
	STA cio_pt+1			; ...into zp pointer
	LDX #8					; number of scanlines...
	STX fw_ctmp				; ...as temporary variable (seldom used)
; load appropriate A value (clear for hires, paper index repeated for colour)
	LDX #0					; last index offset should be 0 for hires!
	TXA						; hires takes no account of paper colour
	LDY #31					; this is what must be added to Y each scanline, in hires
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
	BIT fw_scur				; if cursor is on... [NEW]
	BPL end_bs
		JSR draw_cur		; ...must delete previous one
end_bs:
	_DR_OK					; should be done

cio_up:
; * * cursor up * * no big deal, will stop at top row (NMOS savvy, always 23b and 39t)
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cup
		JSR draw_cur		; ...must delete previous one
do_cup:
	LDA #%00011111			; complete mask?
	AND fw_ciop+1			; current row is now 000rrrrR, R for hires only
	BEQ cu_end				; if at top of screen, ignore cursor
		SBC #1				; this will subtract 1 if C is set, and 2 if clear! YEAH!!!
;		AND #%00011111		; may be safer with alternative screens
		ORA fw_vbot			; EEEEEEK must complete pointer address (5b, 6t)
		STA fw_ciop+1
cu_end:
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_cu_end
		JSR draw_cur		; ...must draw new one
do_cu_end:
	_DR_OK					; ending this with C set is a minor nitpick, must reset anyway

cio_ff:
; * * FF, clear screen AND intialise values! * *
; note that firmware must set IO8attr hardware register appropriately at boot!
; we don't want a single CLS to switch modes, although a font reset is acceptable, set it again afterwards if needed
; * things to be initialised... *
; fw_ccol, note it's an array now (restore from PAPER-INK previous setting)
; fw_fnt (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_cbin (binary or multibyte mode, but must be reset BEFORE first FF)

	STZ fw_mask				; true video *** no real need to reset this
;	STZ fw_cbin				; standard character mode *** not much sense anyway
;	JSR rs_col				; restore array from whatever is at fw_ccol[1] (will restore fw_cbin)
	LDY #<cio_fnt			; supplied font address
	LDA #>cio_fnt
	STY fw_fnt				; set firmware pointer (will need that again after FF)
	STA fw_fnt+1
; standard CLS, reset cursor and clear screen
	JSR cio_home			; reset cursor and load appropriate address
; recompute MSB in A according to hardware
	LDA #$60
	TAX						; keep bottom of VRAM
	CLC
	ADC #$20				; compute top
	STA fw_vtop				; eeeeek
	TXA
	STA fw_vbot				; store new variable
	STA fw_ciop+1			; must correct this one too
	STY cio_pt				; set pointer (LSB=0)...
	STA cio_pt+1
;	LDY #0					; usually not needed as screen is page-aligned! ...and clear whole screen, will return to caller
cio_clear:
; ** generic screen clear-to-end routine, just set cio_pt with initial address and Y to zero **
; this works because all character rows are page-aligned
; otherwise would be best keeping pointer LSB @ 0 and setting initial offset in Y, plus LDA #0
; anyway, it is intended to clear whole rows
	TYA						; A should be zero in hires, and Y is known to have that
sc_clr:
		STA (cio_pt), Y		; clear all remaining bytes
		INY
		BNE sc_clr
	INC cio_pt+1			; next page
	LDX cio_pt+1			; but must check variable limits!
	CPX fw_vtop
		BNE sc_clr
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_ff
		JSR draw_cur		; ...must draw new one, as the one from home was cleared
do_ff:
	RTS

cn_so:
; * * SO, set inverse mode * *
	LDA #$FF				; OK for all modes?
	STA fw_mask				; set value to be EORed
	RTS

cn_si:
; * * SI, set normal mode * *
	_STZA fw_mask			; clear value to be EORed
	RTS

md_dle:
; * * DLE, set binary mode * *
;	LDX #BM_DLE				; X already set if 32
	STX fw_cbin				; set binary mode and we are done
ignore:
	RTS						; *** note generic exit ***

cio_cur:
; * * XON, we now have cursor! * *
	LDA #128				; flag for cursor on
#ifndef	NMOS
	TSB fw_scur				; check previous flag (and set it now)
#else
	BIT fw_scur
	PHP
	ORA fw_scur
	STA fw_scur
	PLP
#endif
	BNE ignore				; if was set, shouldn't draw cursor again
		JMP draw_cur		; go and return

cio_curoff:
; * * XOFF, disable cursor * *
#ifndef	NMOS
	LDA #128				; flag for cursor on
	TRB fw_scur				; check previous flag (and clear it now)
	BNE ignore				; if was set, shouldn't draw cursor again
#else
	LDA fw_scur
	PHP
	AND #127
	STA fw_scur
	PLP
	BPL ignore
#endif
		JMP draw_cur		; go and return

md_col:
; just set binary mode for receiving ink or paper! *** just ignored
	LDX #BM_INK				; next byte will set, say, ink
	STX fw_cbin				; set multibyte mode and we are done
	RTS

cio_home:
; just reset cursor pointer, to be done after (or before!) CLS
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_home
		JSR draw_cur		; ...must draw new one
do_home:
	LDY #0					; base address for all modes, actually 0 EEEEEK
	LDA fw_vbot				; current screen setting!
	STY fw_ciop				; just set pointer
	STA fw_ciop+1
	RTS						; C is clear, right?

md_atyx:
; prepare for setting y first
	LDX #BM_ATY				; next byte will set Y and then expect X for the next one
	STX fw_cbin				; set new mode, called routine will set back to normal
	RTS

draw_cur:
; draw (XOR) cursor [NEW]
	LDX fw_ciop+1			; get cursor position
	CPX fw_vtop				; outside bounds?
		BCS no_cur			; do not attempt to write!
	LDY fw_ciop
	STY cio_pt				; set pointer LSB (common)
	STX cio_pt+1			; set pointer MSB
	LDY #224			; seven rasters down
	LDX #1				; single byte cursor
dc_loop:
		LDA (cio_pt), Y		; get screen data...
		EOR #$FF			; ...invert it...
		STA (cio_pt), Y		; ...and update it
		INY					; next byte in raster
		DEX
		BNE dc_loop
no_cur:
	RTS						; should I clear C?

; *******************************
; *** some multibyte routines ***
; *******************************
; set INK, 19b + common 55b, old version was 44b *** NONE
; set PAPER, 18b + common 55b, old version was 42b *** NONE
cn_col:
md_std:
	_STZA fw_cbin			; back to standard mode
	RTS

cn_sety:					; 6= Y to be set, advance mode to 8
	PHA						; eeeeeek [NEW]
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_sety
		JSR draw_cur		; ...must delete previous one
do_sety:
	PLA						; [NEW]
	JSR coord_ok			; common coordinate check as is a square screen
#ifdef	SAFE
	LDX fw_vbot
	CPX #$10				; is base address $1000? (8K system)
	BNE y_noth
		AND #7			; even further filtering in colour!
y_noth:
#endif
	STA fw_ciop+1			; *** note temporary use of MSB as Y coordinate ***
	LDX #BM_ATX
	STX fw_cbin				; go into X-expecting mode EEEEEEK
	RTS

coord_ok:
#ifdef	SAFE
	CMP #32					; check for not-yet-supported pixel coordinates
		BCC not_px			; must be at least 32, remember stack balance!
#endif
	AND #31					; filter coordinates, note +32 offset is deleted as well
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
	STA fw_ciop				; THIS IS BAD *** KLUDGE but seems to work
	LDA fw_ciop+1			; add to recomputed offset the VRAM base address, this was temporarily Y offset
	CLC						; not necessarily clear in hires?
	ADC fw_vbot
	STA fw_ciop+1
	BIT fw_scur				; if cursor is on... [NEW]
	BPL do_atyx
		JSR draw_cur		; ...must draw new one
do_atyx:
	_BRA md_std

; **********************
; *** keyboard input *** may be moved elsewhere
; **********************
; IO9 port is read, normally 0
; any non-zero value is stored and returned the first time, otherwise returns empty (C set)
; any repeated characters must have a zero inbetween, 10 ms would suffice (perhaps as low as 5 ms)
cn_in:
	LDY $020A				; standard address for generated ASCII code
; *** should this properly address a matrix keyboard?
	BEQ cn_empty			; no transfer is in the making
cn_chk:
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
	.word	ignore			; 3 ***
	.word	ignore			; 4 ***
	.word	ignore			; 5 ***
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
	.word	cio_cur			; 17, show cursor
	.word	md_col			; 18, set ink from next char (ignored)
	.word	cio_curoff		; 19, hide cursor
	.word	md_col			; 20, set paper from next char (ignored)
	.word	cio_home		; 21, home (what is done after CLS)
	.word	ignore			; 22 ***
	.word	md_atyx			; 23, ATYX will set cursor position
	.word	ignore			; 24 ***
	.word	ignore			; 25 ***
	.word	ignore			; 26 ***
	.word	ignore			; 27 ***
	.word	ignore			; 28 ***
	.word	ignore			; 29 ***
	.word	ignore			; 30 ***
	.word	ignore			; 31, IGNORE back to text mode

; *** table of pointers to multi-byte routines *** order must check BM_ definitions!
cio_mbm:
	.word	cn_col			; 2= ink to be set (does nothing)
	.word	cn_col			; 4= paper to be set (does nothing)
	.word	cn_sety			; 6= Y to be set, advance mode to 8
	.word	cn_atyx			; 8= X to be set and return to normal

+cio_fnt:					; *** export label for init! ***
#include "../drivers/fonts/8x8.s"
.)
