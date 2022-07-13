; self-masked sprites routine demo for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220713-1226

; *** input parameters *** (all destroyed, except maxoff)
; maxoff	= number of bytes per raster to transfer - 1 (may be less than width in case of clipping)
; maxras	= number of rasters to transfer - 1 (aka sprite height-1)
; sprite	= pointer to sprite data *** recommended index for transparency is ZERO, but may be changed
; screen	= pointer to screen, with offset for desired sprite position
; bg		= pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)

; *** code for non-overlapping colour self-masked sprite ***
auto:
	LDY maxoff				; get maximum byte offset
loop:
		LDA (sprite), Y		; get sprite data for those two pixels
		TAX					; keep it, and use as index for transparency table
		LDA trtab, X		; get mask
		BNE transp			; zero means no transparency, thus forget about background!
opaque:
			TXA				; retrieve sprite data
draw:
			STA (screen), Y	; store sprite data
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
		BCC sp_ok
			INC sprite+1	; possible page crossing
sp_ok:
		DEC maxras			; one less raster
		BPL raster
	RTS
; *** this version is optimised for opaque pixels ***
transp:
	AND (bg), Y				; show background where transparent *** may take from screen instead
; *** add this commented code if transparency uses any non-zero index
;	STA tmp					; store filtered background data
;;	LDA trtab, X			; get mask again
;;	EOR #$FF				; invert as we're filtering allowed sprite data
;;	AND (sprite), Y			; was already at X, alas!
; if another 'opacity' table is used, replace double-comment code above by the following double-comment
;;	TXA						; retrieve sprite data
;;	AND optab, X			; apply opacity
; following instruction is to be used with that commented code (non-zero transparency) only
;	ORA tmp					; combine with visible background...
	ORA (sprite), Y			; ...but use this instead if ZERO is the transparent index!
	BRA draw				; reflect on screen

; *** transparency data table(s) ***
trtab:
; use $0 for opaque nibbles, $F for transparent. If ZERO is the transparency index, as recommended, make table like this
;	.byt	$FF, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
;	.byt	$0F, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	.byt	$0F, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
; ...and so on until 256 bytes! If, say, white ($F) is the transparen index, it goes...
;	.byt	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0F
; ...until the last line which will be
;	.byt	$F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $FF

optab:
; in case of optimised non-zero transparency option (double-comment) repeat trtab with inverse values (EOR #$FF)

