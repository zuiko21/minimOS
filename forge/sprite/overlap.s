; priority sprites with overlap (using either mask.s or auto.s)
; (c) 2022 Carlos J. Santisteban
; last modified 20220713-1301

; *** input parameters *** ALL arrays [0...numsprites-1], where [0] is the deepest
; sprite_h	= MSB of sprite pointers
; sprite_l	= LSB of the above
; mask_h	= ditto for masks, if used
; mask_l	= LSB of the above
; sp_wid	= sprite widths - 1, in bytes!
; sp_hgt	= sprite heights - 1, in rasters
; sp_x		= sprite X positions, in pixels!
; sp_y		= sprite Y positions, in rasters

; *** output values (for sprite routines) ***
; maxoff	= number of bytes per raster to transfer - 1 (may be less than width in case of clipping)
; maxras	= number of rasters to transfer - 1 (aka sprite height-1)
; mask		= pointer to sprite mask ($00=opaque/$F0/$0F/$FF=transparent) may be offset if L-clipping
; sprite	= pointer to sprite data (PAGE ALIGNED with mask)
; screen	= pointer to screen, with offset for desired sprite position
; bg		= pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)


overlap:
	LDX #0					; reset sprite index (bottom to surface)
sloop:
;		LDA order, X		; in case of shufflable sprites!
;		TAX
;		CPX #0				; first sprite? *** not really needed, I think
		BEQ no_ov			; no overlap possible!
			LDA sp_wid, X	; otherwise check horizontal overlap
