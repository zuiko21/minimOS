; Durango-X pixel routines
; (c) 2022 Carlos J. Santisteban
; last modified 20220712-0127

; *** input ***
; X = x coordinate (<128 in colour, <256 in HIRES)
; Y = y coordinate (<128 in colour, <256 in HIRES)
; fw_mask (for inverse/emphasis mode) is $FF to delete pixel, 0 otherwise
; fw_ccol (array PP.PI.IP.II of two-pixel combos, will store ink & paper for COLOUR only)

; *** zeropage usage ***
; cio_pt (screen pointer)
; fw_cbyt (temporary storage, could be elsewhere)

-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)

dxplot:
	BIT IO8attr				; check screen mode
	BPL colplot				; * HIRES plot below *
		LDA IO8attr			; get flags...
		AND #$30			; ...for the selected screen
		LSR
		LSR
		LSR
		LSR					; just on MSB
		STA cio_pt+1
		TYA					; get Y coordinate in LSB
		ASL
		ROL cio_pt+1
		ASL
		ROL cio_pt+1
		ASL
		ROL cio_pt+1
		ASL
		ROL cio_pt+1
		ASL
		ROL cio_pt+1		; times 32! points to selected raster line
		TXA					; get X coordinate
		LSR
		LSR
		LSR					; 8 pixels per byte
		TAY					; this is actual indexing offset
		TXA					; X again
		AND #7				; MOD 8
		TAX					; use as index
		LDA pixtab, X		; get pixel within byte
		BIT fw_mask			; check if plot or unplot
		BVS unplot_h		; * HIRES PLOT below
			ORA (cio_pt), Y	; add to previous data
			STA (cio_pt), Y
			RTS
unplot_h:
		EOR #$FF			; * HIRES UNPLOT * negate pattern
		AND (cio_pt), Y		; subtract pixel from previous data
		STA (cio_pt), Y
		RTS
colplot:
	STZ cio_pt+1			; reset MSB, as screen bits will be added later
	TYA						; get Y coordinate...
	ASL
	ROL cio_pt+1
	ASL
	ROL cio_pt+1
	ASL
	ROL cio_pt+1
	ASL
	ROL cio_pt+1
	ASL
	ROL cio_pt+1
	ASL
	ROL cio_pt+1			; times 64! points to selected raster line
	STA cio_pt				; store shifted LSB
	LDA IO8attr				; get flags...
	AND #$30				; ...for the selected screen...
	ASL						; ...and shift them to final position
	ORA cio_pt+1			; add to MSB
	STA cio_pt+1
	TXA						; get X coordinate
	LSR						; in half (C is set for odd pixels)
	TAY						; this is actual indexing offset
	LDA #$F0				; mask for even pixel
	BCC evpix
		LDA #$0F			; otherwise is odd
evpix:
	TAX						; keep selected
	BIT fw_mask				; check whether plot or unplot
	BVS unplot_c
		AND fw_ccol+3		; ink bits in proper place
bytecol:
		STA fw_cbyt			; store temporarily
		TXA					; retrieve mask...
		EOR #$FF			; ...inverted!
		AND (cio_pt), Y		; keep original data in byte...
		ORA fw_cbyt			; ...adding new pixel
		RTS
unplot_c:
	AND fw_ccol				; if unplotting, get paper bits instead
	BRA bytecol

; *** data ***
pixtab:
	.dsb	128, 64, 32, 16, 8, 4, 2, 1		; bit patterns from offset
