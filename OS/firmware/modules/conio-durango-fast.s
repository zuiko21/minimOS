; firmware module for minimOS
; Durango-X firmware console 0.9.6b1
; 16x16 text 16 colour _or_ 32x32 text b&w
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-1841

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
; Y -> input char (if Y was 0)

; *** zeropage variables *** standard OS
; cio_src.w (pointer to glyph definitions)
; cio_pt.w (screen pointer)

; *** other variables, perhaps in ZP ***
; fw_cbyt (temporary glyph storage)
; fw_ccnt (another temporary storage)
; fw_chalf (remaining pages to write)

; *** firmware variables to be reset upon FF ***
; fw_ccol.p (SPARSE array of two-pixel combos, will store ink & paper)
;  above will use offsets 0, 1, 2, 3; 4, 8, 12; 16, 32, 48; 64, 128, 192
;  set patterns will be  00,01,10,11,01,10, 11, 01, 10, 11, 01,  10,  11 (0=paper, 1=ink)
;  * now reduced to simple 00.01.10.11 array
; fw_ciop.w (upper scan of cursor position)
; fw_fnt.w (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_cbin (binary or multibyte mode)
; fw_vbot (new, first VRAM page, allows screen switching upon FF)
; fw_vtop (new, first non-VRAM page, allows screen switching upon FF)

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
#ifdef	TESTING
-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)
-IO8blk	= $DF88				; video blanking signals
-IO9di	= $DF9A				; data input (TBD)
-IOBeep	= $DFBF				; canonical buzzer address (d0)
#endif

	TYA						; is going to be needed here anyway
	LDX fw_cbin				; check whether in binary/multibyte mode
	BEQ cio_cmd				; if not, check whether command (including INPUT) or glyph
		CPX #BM_DLE			; just receiving what has to be printed?
			BEQ cio_gl		; print the glyph!
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
; *** now check for mode and jump to specific code ***
	BIT IO8attr				; check mode, code is different, will only check d7
	BPL cpc_col				; skip to colour mode, hires is smaller
; hires version (17b for CMOS, usually 231t, plus jump to cursor-right)
cph_loop:
			_LDAX(cio_src)	; glyph pattern (5)
			EOR fw_mask		; eeeeeeeeeek (4)
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
		BEQ cur_r			; advance to next position! no need for BRA (3)
; colour version, 85b, typically 975t (77b, 924t in ZP)
; new FAST version, but no longer with sparse array
cpc_col:
	LDX #2
	STX fw_chalf			; two pages must be written (2+4*)
cpc_do:						; outside loop (done 8 times) is 8x(45+inner)+113=969, 8x(42+inner)+111=919 in ZP  (was ~1497/1407)
		_LDAX(cio_src)		; glyph pattern (5)
		EOR fw_mask			; in case inverse mode is set, much better here (4)
; *** *** glyph pattern is loaded and masked, let's try an even faster alternative, store all 4 positions premasked as sparse indexes
		TAX					; keep safe (2)
		AND #%00000011		; rightmost pixels (2)
		STA fw_sind			; fourth and last sparse index (4*, note inverted order)
		TXA					; quickly get the rest (2)
		AND #%00001100		; pixels 4-5 (2)
		LSR: LSR			; no longer sparse (2+2)
		STA fw_sind+1		; third sparse index (4*)
		TXA
		AND #%00110000		; pixels 2-3 (2+2)
		LSR: LSR
		LSR: LSR			; no longer sparse, C is clear (2+2+2+2)
		STA fw_sind+2		; second sparse index (4*)
		TXA
		AND #%11000000		; two leftmost pixels (will be processed first) (2+2)
		ROL: ROL: ROL		; no longer sparse, faster this way and ready to use as index (2+2+2)
		INC cio_src			; advance to next glyph byte (5+usually 3)
		BNE cpc_loop
			INC cio_src+1
cpc_loop:					; (all loop was 122/115t, now unrolled is 62/59t)
			TAX				; A was sparse index (2)
			LDA fw_ccol, X	; get proper colour pair (4)
			STA (cio_pt), Y	; put it on screen (6 eeek)
			INY				; next screen byte for this glyph byte (2)
; here comes the time critical part, let's try to unroll
			LDX fw_sind+2	; get next sparse index (4*)
			LDA fw_ccol, X	; get proper colour pair (4)
			STA (cio_pt), Y	; put it on screen (6 eeek)
			INY				; next screen byte for this glyph byte (2)
			LDX fw_sind+1	; get next sparse index (4*)
			LDA fw_ccol, X	; get proper colour pair (4)
			STA (cio_pt), Y	; put it on screen (6 eeek)
			INY				; next screen byte for this glyph byte (2)
			LDX fw_sind		; get next sparse index (4*)
			LDA fw_ccol, X	; get proper colour pair (4)
			STA (cio_pt), Y	; put it on screen (6 eeek)
			INY				; next screen byte for this glyph byte (2)
; ...etc
cpc_rend:					; end segment has not changed, takes 6x11 + 2x24 - 1, 113t (66+46-1=111t in ZP)
		TYA					; advance to next screen raster, but take into account the 4-byte offset (2+2+2)
		CLC
		ADC #60
		TAY					; offset ready (2)
		BNE cpc_do			; unfortunately will wrap twice! (mostly 3)
			INC cio_pt+1	; next page for the last 4 raster (5)
			DEC fw_chalf	; only one half done? go for next and last (*6+3)
		BNE cpc_do
; advance screen pointer before exit, no need for jump if cursor-right is just here!

; **********************
; *** cursor advance *** placed here for convenience of printing routine
; **********************
cur_r:
	LDA #1					; base character width (in bytes) for hires mode
	BIT IO8attr				; check mode
	BMI rcu_hr				; already OK if hires
		LDA #4				; ...or use value for colour mode
rcu_hr:
	CLC
	ADC fw_ciop				; advance pointer
	STA fw_ciop				; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
	BCC rcu_nw				; check possible carry
		INC fw_ciop+1
rcu_nw:						; will return, no need for jump if routine is placed below

; ************************
; *** support routines ***
; ************************
ck_wrap:
; check for line wrap
; address format is 011yyyys-ssxxxxpp (colour), 011yyyyy-sssxxxxx (hires)
; thus appropriate masks are %11100000 for hires and %11000000 in colour... but it's safer to check MSB's d0 too!
	LDY #%11100000			; hires mask
	BIT IO8attr				; check mode
	BMI wr_hr				; OK if we're in hires
#ifdef	SAFE
		LDA fw_ciop+1		; check MSB
		LSR					; just check d0, should clear C
			BCS cn_begin	; strange scanline, thus time for the NEWLINE (Y>1)
#endif
		LDY #%11000000		; in any case, get proper mask for colour mode
wr_hr:
	TYA						; prepare mask and guarantee Y>1 for auto LF
	AND fw_ciop				; are scanline bits clear?
		BNE cn_begin		; nope, do NEWLINE
	_DR_OK					; continue normally otherwise (better clear C)

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
	LDA #1					; hires decrement (these 9 bytes are the same as cur_r)
	BIT IO8attr
	BMI cl_hr				; right mode for the decrement EEEEEK
		LDA #4				; otherwise use colour value
cl_hr:
	STA cio_src				; EEEEEEEEEEEK
	SEC
	LDA fw_ciop
	SBC cio_src				; subtract to pointer, but...
	BMI cl_end				; ...ignore operation if went negative
		STA fw_ciop			; update pointer
cl_end:
	_DR_OK					; C known to be set, though

cn_newl:
; CR, but will do LF afterwards by setting Y appropriately
		TAY					; Y=26>1, thus allows full newline
cn_begin:
; do CR... but keep Y
; note address format is 011yyyys-ssxxxxpp (colour), 011yyyyy-sssxxxxx (hires)
; actually is a good idea to clear scanline bits, just in case
	_STZA fw_ciop			; all must clear! helps in case of tab wrapping too (eeeeeeeeek...)
; in colour mode, the highest scanline bit is in MSB, usually (TABs, wrap) not worth clearing
; ...but might help with unexpected mode change
#ifdef	SAFE
	BIT IO8attr			; was it in hires mode?
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
; *** will do LF if Y was >1 ONLY ***
cn_lf:
; do LF, adds 1 (hires) or 2 (colour) to MSB
; even simpler, INCrement MSB once... or two if in colour mode
; hopefully highest scan bit is intact!!!
	INC fw_ciop+1			; increment MSB accordingly, this is OK for hires
	BIT IO8attr			; was it in hires mode?
	BMI cn_hmok
		INC fw_ciop+1		; once again if in colour mode... 
cn_hmok:
; must check for possible scrolling!!! simply check sign ;-) ...or compare against dynamic limit
	BIT fw_ciop+1			; EEEEEK
	BPL cn_ok				; positive means no scroll
; ** scroll routine **
; rows are 256 bytes apart in hires mode, but 512 in colour mode
	LDY #<pvdu				; LSB *must* be zero, anyway
; MSB is actually OK for destination, but take from current value
	LDX fw_vbot
	STY cio_pt				; set both LSBs
	STY cio_src
	STX cio_pt+1			; destination is set
	INX						; note trick for NMOS-savvyness
	BIT IO8attr			; check mode anyway
	BMI sc_hr				; +256 is OK for hires
		INX					; make it +512 for colour
sc_hr:
	STX cio_src+1			; we're set, worth keep incrementing this
;	LDY #0					; in case pvdu is not page-aligned!
sc_loop:
		LDA (cio_src), Y	; move screen data ASAP
		STA (cio_pt), Y
		INY					; do a whole page
		BNE sc_loop
	INC cio_pt+1			; both MSBs are incremented at once...
	INX
	STX cio_src+1			; ...but only source will enter high-32K at the end
	CPX fw_vtop				; ...or whatever the current limit is
		BNE sc_loop

; data has been transferred, now should clear the last line
	JSR cio_clear			; cannot be inlined! Y is 0
; important, cursor pointer must get back one row up! that means subtracting one (or two) from MSB
	LDA IO8attr				; eeeeeek
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
	BIT IO8attr				; check mode
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
	LDX #0					; last index offset should be 0 for hires!
	TXA						; hires takes no account of paper colour
	LDY #31					; this is what must be added to Y each scanline, in hires
	BIT IO8attr			; check mode
	BMI bs_hr
		LDA fw_ccol			; this is two pixels of paper colour
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
; cursor up, no big deal, will stop at top row (NMOS savvy, always 23b and 39t)
	LDA IO8attr				; check mode
	ROL						; now C is set in hires!
	PHP						; keep for later?
	LDA #%00001111			; incomplete mask, just for the offset, independent of screen-block
	ROL						; but now is perfect! C is clear
	PLP						; hires mode will set C again but do it always! eeeeeeeeeeek
	AND fw_ciop+1			; current row is now 000rrrrR, R for hires only
	BEQ cu_end				; if at top of screen, ignore cursor
		SBC #1				; this will subtract 1 if C is set, and 2 if clear! YEAH!!!
		ORA fw_vbot			; EEEEEEK must complete pointer address (5b, 6t)
		STA fw_ciop+1
cu_end:
	_DR_OK					; ending this with C set is a minor nitpick, must reset anyway

; FF, clear screen AND intialise values!
cio_ff:
; note that firmware must set IO8attr hardware register appropriately at boot!
; we don't want a single CLS to switch modes, although a font reset is acceptable, set it again afterwards if needed
; * things to be initialised... *
; fw_ccol, note it's an array now
; fw_fnt (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_cbin (binary or multibyte mode, but must be reset BEFORE first FF)

	_STZA fw_cbin			; standard, character mode
	_STZA fw_mask			; true video

	LDA #STD_INK			; preload standard colour combos
	JSR set_ink				; these will clear fw_cbin
	LDA #STD_PPR
	JSR set_paper
	LDY #<cio_fnt			; supplied font address
	LDA #>cio_fnt
	STY fw_fnt				; set firmware pointer (will need that again after FF)
	STA fw_fnt+1
; standard CLS, reset cursor and clear screen
	JSR cio_home			; reset cursor and load appropriate address
; recompute MSB in A according to hardware
	LDA IO8attr
	AND #%00110000
	ASL
	TAX						; keep bottom of VRAM
	ADC #$20				; C was clear b/c ASL
	STA fw_vtop				; eeeeek
	TXA
#ifdef	SAFE
	BNE ff_ok
		LDA #%00010000		; base address for 8K systems is 4K
ff_ok:
#endif
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
	BIT IO8attr
	BMI sc_clr				; eeeeeeeeek
		LDA fw_ccol			; EEEEEEEEK, this gets paper colour byte
sc_clr:
		STA (cio_pt), Y		; clear all remaining bytes
		INY
		BNE sc_clr
	INC cio_pt+1			; next page
	LDX cio_pt+1			; but must check variable limits!
	CPX fw_vtop
		BNE sc_clr
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
;	LDX #BM_DLE				; X already set if 32
	STX fw_cbin				; set binary mode and we are done
	RTS

cio_cur:
; XON, we have no cursor, but show its position for a moment
	LDY fw_ciop				; get current position pointer
	LDX fw_ciop+1
	STY cio_pt
	LDY #224				; offset for last scanline at cursor position... in hires
	BIT IO8attr				; are we in colour mode? that offset won't be valid!
	BMI ccur_ok				; hires mode, all OK
		INX					; otherwise, must advance pointer MSB
		LDY #192			; new LSB offset
ccur_ok:
	STX cio_pt+1			; pointer complete
	JSR xon_inv				; invert current contents (will return to caller the second time!)
	LDX #5					; 5 frames (0.1s)
xon_del:
			BIT IO8blk		; check blanking
			BVS xon_del		; in case we are already blanking
xon_wait:
			BIT IO8blk		; check blanking
			BVC xon_wait	; wait for it
		DEX					; next frame
		BNE xon_del
xon_inv:
	LDA (cio_pt), Y			; revert to original
	EOR #$FF
	STA (cio_pt), Y
ignore:
	RTS						; *** note generic exit ***

md_ink:
; just set binary mode for receiving ink! *** could use some tricks to unify with paper mode setting
	LDX #BM_INK				; next byte will set ink
	STX fw_cbin				; set multibyte mode and we are done
	RTS

md_ppr:
; just set binary mode for receiving paper! *** check above for simpler alternative
	LDX #BM_PPR				; next byte will set ink
	STX fw_cbin				; set multibyte mode and we are done
	RTS

cio_home:
; just reset cursor pointer, to be done after (or before!) CLS
	LDY #<pvdu				; base address for all modes, actually 0
	LDA fw_vbot				; current screen setting!
	STY fw_ciop				; just set pointer
	STA fw_ciop+1
	RTS						; C is clear, right?

md_atyx:
; prepare for setting y first
	LDX #BM_ATY				; next byte will set Y and then expect X for the next one
	STX fw_cbin				; set new mode, called routine will set back to normal
	RTS

; *******************************
; *** some multibyte routines ***
; *******************************
cn_ink:						; 2= ink to be set
	AND #15					; even if hires will just use d0, keep whole value for this hardware
set_ink:
	STA fw_cbyt				; temporary storage
	ASL
	ASL
	ASL
	ASL						; ink again, but in high nibble
	STA fw_ccnt				; another temporary storage (high nibble)
	ORA fw_cbyt				; twice
	STA fw_ccol+3			; both INK
	LDA fw_ccol+2			; this was old ink-paper
	AND #$0F				; keep paper only
	ORA fw_ccnt				; now it's INK-PAPER
	STA fw_ccol+2
	LDA fw_ccol+1			; this is paper and old ink
	AND #$F0				; keep paper only
	ORA fw_cbyt				; now it's PAPER-INK
	STA fw_ccol+1
md_std:
	_STZA fw_cbin			; back to standard mode
	RTS

cn_ppr:						; 4= paper to be set
	AND #15					; same as ink
set_paper:
	STA fw_cbyt				; temporary storage
	ASL
	ASL
	ASL
	ASL						; paper again, but in high nibble
	STA fw_ccnt				; another temporary storage (high nibble)
	ORA fw_cbyt				; twice
	STA fw_ccol				; both PAPER (all versions)
	LDA fw_ccol+1			; this is old paper and ink
	AND #$0F				; keep ink only
	ORA fw_ccnt				; now it's PAPER-INK
	STA fw_ccol+1
	LDA fw_ccol+2			; this was ink and old paper
	AND #$F0				; keep ink only
	ORA fw_cbyt				; now it's INK-PAPER
	STA fw_ccol+2
	_BRA md_std

cn_sety:					; 6= Y to be set, advance mode to 8
	JSR coord_ok			; common coordinate check as is a square screen
#ifdef	SAFE
	LDX fw_vbot
	CPX #$10				; is base address $1000? (8K system)
	BNE y_noth
		AND #15				; max lines for hires mode in 8K RAM
		BIT IO8attr			; check mode again
		BPL y_noth
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
	BIT IO8attr				; if in colour mode, further filtering
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
	BIT IO8attr				; if in colour mode, each X is 4 bytes ahead ***
	BMI do_atx
		ASL
		ASL
		ASL fw_ciop+1		; THIS IS BAD *** KLUDGE but seems to work (had one extra)
do_atx:
	STA fw_ciop				; THIS IS BAD *** KLUDGE but seems to work
	LDA fw_ciop+1			; add to recomputed offset the VRAM base address, this was temporarily Y offset
	CLC						; not necessarily clear in hires?
	ADC fw_vbot
	STA fw_ciop+1
	_BRA md_std

; **********************
; *** keyboard input *** may be moved elsewhere
; **********************
; IO9 port is read, normally 0
; any non-zero value is stored and returned the first time, otherwise returns empty (C set)
; any repeated characters must have a zero inbetween, 10 ms would suffice (perhaps as low as 5 ms)
cn_in:
	LDY IO9di				; get current data at port *** must set lower address nibble
; *** should this properly address a matrix keyboard?
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

; *** table of pointers to multi-byte routines *** order must check BM_ definitions!
cio_mbm:
	.word	cn_ink			; 2= ink to be set
	.word	cn_ppr			; 4= paper to be set
	.word	cn_sety			; 6= Y to be set, advance mode to 8
	.word	cn_atyx			; 8= X to be set and return to normal

+cio_fnt:					; *** export label for init! ***
#include "../../drivers/fonts/8x8.s"
.)
