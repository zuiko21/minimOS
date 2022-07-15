; masked sprites routine demo for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220713-1152


; *** input parameters *** (all destroyed, except maxoff)
; maxoff	= number of bytes per raster to transfer - 1 (may be less than width in case of clipping)
; maxras	= number of rasters to transfer - 1 (aka sprite height-1)
; mask		= pointer to sprite mask ($00=opaque/$F0/$0F/$FF=transparent) may be offset if L-clipping
; sprite	= pointer to sprite data (PAGE ALIGNED with mask)
; screen	= pointer to screen, with offset for desired sprite position
; bg		= pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)

; *** CAVEAT! transparent pixels MUST be zero (although zero is OK for opaque pixels)

; *** code for non-overlapping colour sprite *** X intact!
raster:
	LDY maxoff				; get maximum byte offset
loop:
		LDA (mask), Y		; get mask data for those two pixels
		BNE transp			; zero means no transparency, thus forget about background!
draw:
			ORA (sprite), Y	; take all data from sprite *** note all transparent pixels MUST be 0, but not always the opposite!
			STA (screen), Y	; and store it appropriately
			DEY
			BPL loop
; go for next raster
		LDA screen
		CLC
		ADC #$40			; next raster on screen is 64 bytes ahead
		STA screen
		STA bg				; *** screen and bg MUST be page aligned, which makes sense (only MSB differs)
		BCC sc_ok
			INC screen+1	; possible page crossing
			INC bg+1		; see note above ***
sc_ok:
		LDA sprite			; get sprite pointer (not necessarily at start)
		CLC
		ADC spr_wid			; add number of bytes from sprite width
		STA sprite
		STA mask			; *** having mask and sprite page-aligned helps, otherwise use a similar separate procedure
		BCC sp_ok
			INC sprite+1	; possible page crossing
			INC mask+1		; see note above ***
sp_ok:
		DEC maxras			; one less raster
		BPL raster
	RTS
; *** this version is optimised for opaque pixels, otherwise change BNE transp for BEQ draw and place afterwards the following AND (opaques will take +1t, but transparency -4t)
transp:
	AND (bg), Y				; show background where transparent *** may take from screen instead
	BRA draw				; add sprite data
