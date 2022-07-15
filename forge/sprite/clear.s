; sprite clearing routine for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220713-1307

; *** input parameters *** (all destroyed, except maxoff)
; maxoff	= number of bytes per raster to transfer - 1 (may be less than width in case of clipping)
; maxras	= number of rasters to transfer - 1 (aka sprite height-1)
; screen	= pointer to screen, with offset for desired sprite position
; bg		= pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)

; *** code for clearing colour sprite *** X intact!
clear:
	LDY maxoff				; get maximum byte offset
cloop:
		LDA (bg), Y			; get background for those two pixels
		STA (screen), Y		; and store them appropriately
		DEY
		BPL cloop
; go for next raster
		LDA screen
		CLC
		ADC #$40			; next raster on screen is 64 bytes ahead
		STA screen
		STA bg				; *** screen and bg MUST be page aligned, which makes sense (only MSB differs)
		BCC cl_ok
			INC screen+1	; possible page crossing
			INC bg+1		; see note above ***
cl_ok:
		DEC maxras			; one less raster
		BPL clear
	RTS
