; Durango-X pixel routines
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230203-2200

; *** input ***
; X = x coordinate (<128 in colour, <256 in HIRES)
; Y = y coordinate (<128 in colour, <256 in HIRES)
; px_col = colour in II format (17*index, HIRES reads d7 only)

; *** zeropage usage ***
; cio_pt (screen pointer)
; gr_tmp (temporary storage, could be elsewhere)

; NEW performance data
; *) remove 1t if variable in ZP
; HIRES PLOT = 23+2+48*+19 = 92t ~60 µs
; HIRES UNPLOT = 23+2+48*+22 = 95t ~62 µs
; COLOUR EVEN = 23+3+27+3+31*** = 84-87t ~55-57 µs
; COLOUR ODD = 23+3+27+6+31*** = 87-90t ~57-59 µs

-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)

#ifndef	USE_PLOT
cio_pt	= $FB				; screen pointer
gr_tmp	= cio_pt+2			; (temporary storage, could be elsewhere) cleaner this way
tmp		= gr_tmp			; hopefully works! (demo only)
#endif

dxplot:
.(
	STZ cio_pt				; common to all modes (3)
	TYA						; get Y coordinate... (2)
	LSR
	ROR cio_pt
	LSR
	ROR cio_pt				; divide by 4 instead of times 64, already OK for colour (2+5+2+5)
	BIT IO8attr				; check screen mode (4)
	BPL colplot				; * HIRES plot below * (3/2 for COLOUR/HIRES)
		LSR
		ROR cio_pt			; divide by 8 instead of times 32! (2+5)
		STA cio_pt+1		; LSB ready, temporary MSB (3)
		LDA IO8attr			; get flags... (4)
		AND #$30			; ...for the selected screen... (2)
		ASL					; ...and shift them to final position (2)
		ORA cio_pt+1
		STA cio_pt+1		; full pointer ready! (3+3)
		TXA					; get X coordinate (2)
		LSR
		LSR
		LSR					; 8 pixels per byte (2+2+2)
		TAY					; this is actual indexing offset (2)
		TXA					; X again (2)
		AND #7				; MOD 8 (2)
		TAX					; use as index (2)
		LDA pixtab, X		; get pixel within byte (4)
		BIT px_col			; check colour to plot (4*)
		BPL unplot_h		; alternative clear routine (2/3)
			ORA (cio_pt), Y		; add to previous data (5/ + 6/ + 6/)
			STA (cio_pt), Y
			RTS
unplot_h:
		EOR #$FF			; * HIRES UNPLOT * negate pattern (/2)
		AND (cio_pt), Y		; subtract pixel from previous data (/5 + /6 + /6)
		STA (cio_pt), Y
		RTS
colplot:
	STA cio_pt+1			; LSB ready, temporary MSB (3)
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
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
	STA gr_tmp				; store temporarily (4*)
	TXA						; retrieve mask... (2)
	AND px_col				; extract active colour bits (4*)
	ORA gr_tmp				; ...adding new pixel (4*)
	STA (cio_pt), Y			; EEEEEEEEK (6+6)
	RTS

; *** data ***
pixtab:
	.byt	128, 64, 32, 16, 8, 4, 2, 1		; bit patterns from offset
.)
