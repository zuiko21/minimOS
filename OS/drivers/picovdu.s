; 2 kiB pico-VDU (direct bus version)
; v0.1a1
; (c) 2022 Carlos J. Santisteban
; last modified 20210126-0955

; *** stub with TONS of things to do ***
#ifndef	HEADERS
#include "../macros.h"
; *** experimental variables **
	* = $E0
io_c	.dsb	2			; ASCII and temporary
pv_fpt	.dsb	2			; ZP pointers
pv_spt	.dsb	2
pv_fgl	.dsb	1			; flags
pv_fch	.dsb	1
pv_x	.dsb	1			; coordinates
pv_y	.dsb	1
font	.dsb	2			; font pointer (not necessarily in ZP)
#endif

	.text
	* = $400
pv_pch:
; ** print char **
	_STZA pv_fgl			; clear this flag (rightmost glyph, odd ASCII)
	_STZA pv_fch			; this one too (rightmost char, odd column)
	_STZA io_c+1			; clear MSB
; compute glyph pointer
	LDA io_c				; get ASCII
	LSR						; two chars per byte!
	ROR pv_fgl				; store C into flag d7
	ASL
	ASL						; takes 8 scanlines per COUPLE of chars
	ROL io_c+1
	ASL
	ROL io_c+1
	ASL
	ROL io_c+1
	CLC
	ADC font				; add font base (could be immediate)
	STA pv_fpt				; create read pointer
	LDA io_c+1				; ditto for MSB
	ADC font+1
	STA pv_fpt
; compute screen pointer
	_STZA pv_spt			; clear LSB!
	LDA pv_y				; get row (0...15)
	LSR						; 8 scanlines per row, but 16 bytes per scanline, shift one byte left and one bit right
	ROR pv_spt				; may create carry
; following code is valid for the $7800 fixed (and especially page-aligned) start address
;	CLC						; already clear thanks to ROR above!
	ADC #$78				; screen base address MSB
	STA pv_spt+1			; MSB is ready, but...
	LDA pv_x				; column (0...31)
	LSR						; two columns per byte (0...15)
	ROR pv_fch				; d7 on in case of an odd column
	ORA pv_spt				; MSB is only 0 or 128! D6-D4 will change each scanline!
	STA pv_spt				; ready
; put glyph data on screen
; first extract and shift appropriate glyph
	LDY #0
pv_scn:
		LDA (pv_fpt), Y		; get two conscutive glyphs data
		BIT pv_fgl			; check flags, is it the leftmost glyph?
		BMI pv_lgl			; no, just keep the LSN...
			LSR				; ...or shift MSN down
			LSR
			LSR
			LSR
pv_lgl:
		AND #$0F			; only MSN
		BIT pv_fch			; will be printed here or to the left?
		BMI pv_lch			; if here, do nothing...
			ASL				; ...or shift it back
			ASL
			ASL
			ASL
pv_lch:
		STA io_c+1			; temporary glyph storage
; then mask screen contents and put glyph on it
; * could check here for inverse mode, but check masking *
		LDA #$0F			; keep rightmost char, print to the left
		BIT pv_fch			; is that the place?
		BPL pv_msk			; yes, stay so
			EOR #$FF		; no, switch mask location
pv_msk:
#ifndef	NMOS
		AND (pv_spt)		; AND mask with current screen data
		ORA io_c+1			; OR with glyph pattern
		STA (pv_spt)		; and place it back into screen
#else
		LDX #0				; NMOS version, no macro! Could set X first
		AND (pv_spt, X)
		ORA io_c+1
		STA (pv_spt, X)		; not worth using the macro, as X is already 0
#endif
; advance to next scanline, both screen and font
		INY					; font pointer set!
		LDA pv_spt			; screen pointer LSB
		CLC
		ADC #16				; next scanline
		STA pv_spt			; do not care about carry
		CPY #8				; are we done?
		BNE pv_scn
; ** should update coordinates! **
