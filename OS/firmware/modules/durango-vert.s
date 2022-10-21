; Durango-X vertical line routine
; (c) 2022 Carlos J. Santisteban
; last modified 20221021-1230

; *** INPUT ***
; px_col.b	= colour in II format (17*index, HIRES reads d7 only)
; X		= x coordinate (fixed)
; Y		= initial (top) Y coordinate
; y_cnt	= number of vertical pixels (line height)
; *** temporary use ***
; cio_pt as usual in ZP
; tmp_col anywhere, best in ZP
; byt_l anywhere, best in ZP (new size optimisation)

v_line:
.(
	_STZA cio_pt			; clear LSB
	TYA						; get Y coordinate... (2)
	LSR
	ROR cio_pt
	LSR
	ROR cio_pt				; divide by 4 instead of times 64, already OK for colour (2+5+2+5)
	BIT IO8attr				; check screen mode (4)
	BPL col_vl				; * HIRES V line below * (3/2 for COLOUR/HIRES)
hr_vl:
		LSR
		ROR cio_pt			; MSB divided by 8 is like LSB times 32
		STA cio_pt+1
		STA cio_pt+1		; LSB ready, temporary MSB (3)
		LDA IO8attr			; get flags... (4)
		AND #$30			; ...for the selected screen... (2)
		ASL					; ...and shift them to final position (2)
		ORA cio_pt+1		; add to MSB (3+3)
		STA cio_pt+1
		TXA					; get X coordinate (2)
		LSR
		LSR
		LSR					; pixel-to-byte (DIV 8)
		TAY					; now as offset
		TXA					; get X coordinate (2)
		AND #7				; MOD 8
		TAX					; as index
		LDA hkeep, X		; for the bit-position table (preserve)
		TAX					; mask for pixel preserve
		EOR #$FF			; inverse is drawn pixel position
		BIT px_col			; check colour
		BMI do_plot			; if black, UNPLOT
			INC				; CMOS only, could use LDA #0 instead
do_plot:
		STA tmp_col			; plotting mask ready
		LDA #32				; bytes per line in HIRES
		BNE set_wid			; reuse common code, no need for BRA
col_vl:
	STA cio_pt+1			; LSB ready, temporary MSB (3)
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
	TXA						; get X coordinate (2)
	LSR						; in half (C is set for odd pixels) (2)
	TAY						; this is actual indexing offset (2)
	LDA #$F0				; active mask for even pixel (2)
	LDX #$0F				; and bits to be preserved
	BCC evpix
		TXA					; otherwise is odd (3/2+2+2 for even/odd)
		LDX #$F0
evpix:
	AND px_col				; compute desired colour pattern
	STA tmp_col				; store as mask
	LDA #32					; bytes per line in colour
set_wid:
	STA byt_l
v_loop:
		TXA						; get preservation mask
		AND (cio_pt), Y			; extract relevant bits
		ORA tmp_col				; and add constant new ones!
		STA (cio_pt), Y
		LDA cio_pt
		CLC
		ADC byt_l				; bytes per line (common routine)
		STA cio_pt
		BCC no_page				; possible carry
			INC cio_pt+1
no_page:
		DEC y_cnt			; one line less
		BNE v_loop
	RTS
; *** DATA, kept bit-position table (HIRES only) ***
hkeep:
	.byt	127, 191, 223, 239, 247, 251, 253, 254
