; Durango-X pixel routines
; (c) 2022 Carlos J. Santisteban
; last modified 20220920-1422

; *** input ***
; X = x coordinate (<128 in colour, <256 in HIRES)
; Y = y coordinate (<128 in colour, <256 in HIRES)
; px_col = colour in II format (17*index, HIRES reads d7 only)

; *** zeropage usage ***
; cio_pt (screen pointer)
; fw_cbyt (temporary storage, could be elsewhere)

; OLD version performance:
; code size = 96 bytes, plus 256(C) + 520(HR) of tables
; HIRES PLOT = 12+2+38+2+17 = 71t ~46 µs (63t-41µs w/pixpos)
; HIRES UNPLOT = 12+2+38+3+19 = 74t ~48 µs (66t-43µs w/pixpos)
; COLOUR PLOT = 12+3+31!+5+29 = 80t ~52 µs
; COLOUR UNPLOT = 12+3+31!+10+29 = 85t ~55 µs

; *) remove 1t if variable in ZP
; !) add 1t for odd pixels

; PIXPOS option:
; code size = 93 bytes, plus 256(C) + 768(HR) bytes of tables
; 8t / 5.2µs less in HIRES, unchanged for colour mode

-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)

dxplot:
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	BIT IO8attr				; check screen mode (4)
	BPL colplot				; * HIRES plot below * (3/2 for COLOUR/HIRES)
		ORA hradd_h, Y		; get line start MSB, including screen base! (4+3)
		STA cio_pt+1
		LDA hradd_l, Y		; same for LSB (4)
		STA cio_pt			; base pointer ready! (3)
		TXA					; get X coordinate (2) *** with another table, could be LDY pixpos, X
		LSR
		LSR
		LSR					; 8 pixels per byte (2+2+2) ***
		TAY					; this is actual indexing offset (2) ***
		TXA					; X again (2) *** pixpos table would replace until here
		AND #7				; MOD 8 (2)
		TAX					; use as index (2)
		LDA pixtab, X		; get pixel within byte (4)
		BIT px_col			; check if plot or unplot (4*)
		BPL unplot_h		; * HIRES PLOT below (2/3 for PLOT/UNPLOT)
			ORA (cio_pt), Y	; add to previous data (5/ + 6/ + 6/)
			STA (cio_pt), Y
			RTS
unplot_h:
		EOR #$FF			; * HIRES UNPLOT * negate pattern (/2)
		AND (cio_pt), Y		; subtract pixel from previous data (/5 + /6 + /6)
		STA (cio_pt), Y
		RTS
colplot:
	ORA coladd_h, Y			; get line start MSB, including screen base! (4+3)
	STA cio_pt+1
	LDA coladd_l, Y			; same for LSB (4)
	STA cio_pt				; base pointer ready! (3)
	TXA						; get X coordinate (2)
	LSR						; in half (C is set for odd pixels) (2)
	TAY						; this is actual indexing offset (2)
	LDA #$0F				; _inverse_ mask for even pixel (2)
	LDX #$F0				; and colour mask for it (2)
	BCC evpix
		LDA #$F0			; otherwise is odd (3/2+2+2 for even/odd)
		LDX #$0F
evpix:
	AND (cio_pt), Y			; keep original data in byte... (5)
	STA fw_cbyt				; store temporarily (4*)
	TXA						; retrieve mask... (2)
	AND px_col				; extract active colour bits (4*)
	ORA fw_cbyt				; ...adding new pixel (4*)
	STA (cio_pt), Y			; EEEEEEEEK (6+6)
	RTS

; *** data ***
pixtab:
	.byt	128, 64, 32, 16, 8, 4, 2, 1		; bit patterns from offset *** pixpos would continue for a full page
coladd_l:
	.byt	0, $40, $80, $C0, 0, $40, $80, $C0	; ...total 128 bytes of this sequence
coladd_h:
	.byt	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2	; ...and so on, note screen base will be added later
hradd_l:
	.byt	0, $20, $40, $60, $80, $A0, $C0, $E0	; ...up to 256 values
hradd_h:
	.byt	0,   0,   0,   0,   0,   0,   0,   0	; ...then all 1's, then 2, etc. up to $1F
