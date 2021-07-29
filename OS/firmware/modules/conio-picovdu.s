; firmware module for minimOS
; pico-VDU basic 16x16 firmware console 0.9.6a2
; suitable for Durango-proto (not Durango-X/SV) computer
; also for any other computer with picoVDU connected via IOSCREEN option
; new version based on Durango-X code
; (c) 2021 Carlos J. Santisteban
; last modified 20210729-1207

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
; IOSCREEN interface cannot read the VRAM... thus, no scrolling is available!
; will just wrap around the screen, preferabily clearing the two upper rows (1 page)

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

; *** *** code start, print char in Y (or ask for input) *** *** typical print overhead is 14t
	TYA						; is going to be needed here anyway (2)
	LDX fw_cbin				; check whether in binary/multibyte mode (4)
	BEQ cio_cmd				; if not, check whether command (including INPUT) or glyph (usually 3)
		CPX #BM_DLE			; just receiving what has to be printed?
			BEQ cio_gl		; print the glyph!
		_JMPX(cio_mbm-2)	; otherwise process following byte as expected, note offset
cio_cmd:
	CMP #32					; printable anyway? (2)
	BCS cio_prn				; go for it, flag known to be clear (usually 3)
		ASL					; two times
		TAX					; use as index
		CLC					; will simplify most returns as DR_OK becomes just RTS
		_JMPX(cio_ctl)		; execute from table
cio_gl:
	_STZX fw_cbin			; clear flag!
cio_prn:
; ***********************************
; *** output character (now in A) *** screen addresses are 01111yyy ysssxxxx
; ***********************************
; glyph pointer setting is always 24b, 43t
	ASL						; times eight scanlines (2+5 x3)
	ROL cio_src+1			; M=???????7, A=6543210·
	ASL
	ROL cio_src+1			; M=??????76, A=543210··
	ASL
	ROL cio_src+1			; M=?????765, A=43210···
	CLC
	ADC fw_fnt				; add font base (2+4+4)
	STA cio_src
	LDA cio_src+1			; A=?????765 (3)
	AND #7					; A=·····765 (2+4)
	ADC fw_fnt+1
;	DEC						; or add >font -1 if no glyphs for control characters
	STA cio_src+1			; pointer to glyph is ready (3)
; screen pointer setting is 12b,16t direct and 18b,23t IOSCREEN (NMOS adds 5/6 or 7/8 for IOSCREEN)
	LDY fw_ciop				; get current address (4+4)
	LDA fw_ciop+1
	STA cio_pt+1			; set pointer, good to keep MSB for increments (3)
#ifdef	IOSCREEN
	AND #%00000111			; only 2K, do not touch flags EEEEEEEEEEEEK
	ORA fw_flags			; keep inverse mode (4)
	STA IO8lh				; set MSB and flags (4)
#else
	_STZA cio_pt			; LSB always in Y, ZP pointer LSB always 0 (3/5)
#endif
	LDX #8					; number of scanlines (2)
#ifdef	NMOS
	STX fw_ctmp				; set counter (4)
	LDX #0					; prepare for alternative instruction (2)
#endif
cph_loop:
; main printing loop takes 18b,247t direct and 22b,271t IOSCREEN
; make that 20b,287t and 24b,311t IOSCREEN for NMOS
#ifdef	NMOS
		LDA (cio_src, X)	; glyph pattern (6)
#else
		LDA (cio_src)		; CMOS is faster (5)
#endif
#ifdef	IOSCREEN
		STY IO8ll			; select address low... (4)
		STA IO8wr			; ...and write data into screen (4)
#else
		STA (cio_pt), Y		; put it on screen (5)
#endif
		INC cio_src			; advance to next glyph byte (5)
		BNE cph_nw			; (usually 3, rarely 7) non-8-byte-aligned fonts need this
			INC cio_src+1
cph_nw:
		TYA					; advance to next screen raster (2+2)
		CLC
		ADC #16				; 16 bytes/raster, this will NEVER wrap (2)
		TAY					; offset ready (2)
; check some counter, no longer can rely on sign, note very different approach for NMOS
#ifdef	NMOS
		DEC fw_ctmp			; next scan (6)
#else
		DEX					; next scan (2)
#endif
		BNE cph_loop		; until 8 times completed (3)
; end of loop (8 times) 31·8-1/34·8-1, 36·8-1/39·8-1 NMOS
;	BEQ cur_r				; advance to next position! (always 3)

; **********************
; *** cursor advance *** placed here for convenience of printing routine
; **********************
cur_r:
	INC fw_ciop				; advance pointer, should NEVER wrap
;	BNE ck_wrap				; ...will return

; ***************************
; *** check for line wrap *** placed here for convenience of printing routine
; ***************************
ck_wrap:
	LDY #%01110000			; scanline mask
	TYA						; prepare mask and guarantee Y>1 for auto LF
	AND fw_ciop				; are scanline bits clear?
		BNE cn_begin		; nope, do NEWLINE
	RTS						; continue normally otherwise (should I clear C?)

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

; ************************
; *** control routines ***
; ************************
cn_cr:
; *** this is the CR without LF ***
	LDY #1					; will skip LF routine
	BNE cn_begin

cur_l:
; *** cursor left, no big deal, but do not wrap if at leftmost column ***
	LDX fw_ciop				; try decrementing pointer by 1
	DEX
	TXA						; keep it in case it's valid
	AND #%01110000			; check any scanline bits
	BEQ cl_end				; ignore operation if any went high
		STX fw_ciop			; ...update pointer otherwise
cl_end:
	RTS						; C known to be clear!

cn_newl:
; *** CR, but will do LF afterwards by setting Y appropriately ***
		TAY					; Y=26>1, thus allows full newline
cn_begin:
; *** do CR... but keep Y ***
; make LSB AND %1···0000 and, if LF is to be done, add 128
; actually is a good idea to clear scanline bits, just in case
#ifdef	NMOS
		LDA fw_ciop			; clear LSB lowests bits (8b/10t)
		AND #128
		STA fw_ciop
#else
		LDA #127			; bits to be cleared (5b/7t)
		TRB fw_ciop			; nice...
#endif
; check whether LF is to be done
	DEY						; LF needed?
	BEQ cn_ok				; not if Y was 1 (use BMI if Y was zeroed for LF)
; *** will do LF if Y>1 ONLY ***
cn_lf:
; do LF, adds 128 to LSB
; hopefully scan bits are intact!!!
	LDA fw_ciop				; get pointer LSB
	ADC #128				; C known to be clear! could use EOR as well?
	STA fw_ciop				; update...
	BCC cn_hmok				; ...taking care of possible  carry, BPL should do
		INC fw_ciop+1
cn_hmok:
; must check for possible scrolling!!! simply check MSB sign ;-)
	BIT fw_ciop+1
	BPL cn_ok				; positive means no scroll
; ** scroll routine ** not for IOSCREEN
#ifdef	IOSCREEN
; just wrap the screen and clear... just the first two rows?
		JSR cio_home		; reset cursor, sets AA.YY
		AND #%00000111		; only 2K, do not touch flags EEEEEEEEEEEEK
		ORA fw_flags		; keep inverse mode (4)
		STA IO8lh			; set MSB and flags (4)
;		LDY #0				; reset index, will do a whole page (two rows) should be already 0
		TYA					; will set zero everywhere
csc_loop:
			STY IO8ll		; set address...
			STA IO8wr		; ...and data
			INY
			BNE csc_loop	; until done (BPL will just clear one row)
		RTS					; is C really clear?
#else
; actuall scroll, only memory mapped
; rows are 128 bytes apart
		LDA #<pvdu				; LSB *must* be zero, anyway
		TAY						; reset index too
		LDX #>pvdu				; MSB is actually OK for destination
		STA cio_pt				; set both LSBs
		ORA #128				; set bit 7 for source, was known to be zero
		STA cio_src				; source is $7880
		STX cio_pt+1			; MSBs are the same
		STX cio_src+1			; we're set
sc_loop:
			LDA (cio_src), Y	; move screen data ASAP (in all modes)
			STA (cio_pt), Y
			INY					; do a whole page
			BNE sc_loop
				INC cio_pt+1	; both MSBs are incremented at once...
				INC cio_src+1	; note that when this goes negative, half a page of ROM has been copied!
			BPL sc_loop
; data has been transferred, now should clear the last line
		DEC cio_src+1			; since LSB is $80, this points to RAMTOP-128, and Y is 0
		TYA						; A also clear
sc_clear:
			STA (cio_src), Y	; ad hoc loop, note use of source pointer b/c offset LSB
			INY
			BPL sc_clear		; just the last 128 bytes!
; important, cursor pointer must get back one row up! it is $7F80, actually
		STY fw_ciop			; Y is already $80
		LDA cio_src+1		; this known to be $7F
		STA fw_ciop+1
cn_ok:
	_DR_OK					; note that some code might set C


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
