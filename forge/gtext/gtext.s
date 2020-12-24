; print text on arbitrary pixel boundaries
; 65C02-version
; (c) 2020 Carlos J. Santisteban
; last modified 20201224-1156

; assume 8x8 pixel font, bitmap or planar VRAM layout
; this code assumes C64-style VRAM layout, but could use Amstrad layout as well, just changing the y-offset LUT

; *** zero page variables ***

f_ptr	.dsb	2			; indirect pointer for font reading
v_ptr	.dsb	2			; indirect pointer for screen writing

; *** variables not necessarily in ZP ***
x_pos	.dsb	2			; 16-bit x-position, little-endian
y_pos	.dsb	2			; 16-bit y-position, little-endian *** likely to use the LSB only ***
char	.dsb	1			; ASCII to be printed

mask	.dsb	2			; shiftable 16-bit mask for printing
scan	.dsb	2			; copy of font scanline to be shifted

; *** required constants *** may be in RAM for versatilty

	FONT	= $E000			; font definition start address
	VRAM	= $6000			; screen start address

	.text

; *** init code, before any printing ***

init:
	LDA #<FONT				; use base address for pointer
	STA f_ptr
; needs to fill offset tables! TO DO
	RTS						; anything else to do?

; ********************
; *** actual stuff ***
; ********************

print:
	STZ f_ptr+1				; reset for temporary use
	LDA char				; get ascii
	ASL						; 16-bit rotation, three times
	ROL f_ptr+1
	ASL
	ROL f_ptr+1
	ASL
	ROL f_ptr+1
	TAY						; keep offset LSB as index (always < 248)
	LDA #>FONT				; prepare MSB too
	CLC
	ADC f_ptr+1				; add offset to base
	STA f_ptr+1
; with C64-style, VRAM offset is (x-x MOD 8)+INT(y/8)*320, thus the remaining is the pointer LSB, other layouts will differ
	LDA x_pos				; get X position again, now for the rest
	AND #248
;	CLC
;	ADC #<VRAM				; in case is not page aligned (rare)
	STA v_ptr				; still missing Y-offset
;	LDA y_pos+1				; in case Y.H is relevant
;	STA v_ptr+1
	LDA y_pos
;	ASL v_ptr+1				; if used, the following istruction is to be ROL instead
	ASL						; divide-by-eight
;	ASL v_ptr+1				; the same, three times
	ASL
;	ASL v_ptr+1
	ASL
		
s_loop:
		LDA (f_ptr), Y		; get font data
		STA scan			; put on LSB...
		STZ scan+1			; ...with clear MSB
		STZ mask			; mask is 0 where printed...
		LDA #$FF			; ...and 1 where original pixel is to be kept
		STA mask+1
		LDA x_pos			; get X position, just for the bit-offset
		AND #7
		TAX					; number of pixels to shift within byte
x_loop:
			ASL scan		; rotate font data...
			ROL scan+1
			ASL mask		; ...and mask
			ROL masl+1
			DEX
			BPL x_loop
		
