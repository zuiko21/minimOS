; masked sprites demo for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220714-2336

; *** routine parameters *** (all destroyed, except maxoff)
; maxoff	= number of bytes per raster to transfer - 1 (may be less than width in case of clipping)
; maxras	= number of rasters to transfer - 1 (aka sprite height-1)
; mask		= pointer to sprite mask ($00=opaque/$F0/$0F/$FF=transparent) may be offset if L-clipping
; sprite	= pointer to sprite data (PAGE ALIGNED with mask)
; screen	= pointer to screen, with offset for desired sprite position
; bg		= pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)

; *** variables and pointers ***

IO8attr	= $DF80				; video mode register
screen3	= $6000				; standard screen address

; *** zeropage definitions ***
; screen	= pointer to screen, with offset for desired sprite position
; bg		= pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)

; *** ROM starts with binaries ***
	* = $C000

background:
	.bin	0, 8192, "../../other/data/elvira.sv"	; background picture

; should be $E000
sprites:
	.bin	0, 2240, "../../other/data/sprites.sv"	; sprite data (28*32, 448 bytes each)
	.dsb	$E900-*, $FF							; ended at $E8C0, mask MUST be page-aligned!
masks:
	.bin	0, 2240, "../../other/data/mask.sv"		; mask data (28*32, 448 bytes each)

; *** data structures ***

; *** initialisation code ***
demo:
	LDA #$38
	STA IO8attr				; set colour mode, screen 3
; copy background to screen
	LDA #>screen3
	LDX #>background
	LDY #0
	STA screen+1			; set screen pointer (will be used by sprites)
	STX bg+1				; also background
	STY screen
	STY bg					; page-aligned, and index is reset!
copy:
		LDA (bg), Y
		STA (screen), Y		; copy background into screen
		INY
		BNE copy
			INC bg+1		; in case of page crossing...
			INC screen+1	; ...look for end of screen ($8000)
		BPL copy

	.dsb	$FFFA - *, $DB	; ROM filling

	.word demo
	.word demo
	.word demo
