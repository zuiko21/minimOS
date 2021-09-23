; test of hires Durango-X font
; (c) 2021 Carlos J. Santisteban 

	* =	$400

; zeropage usage
ptr		= 0
org		= 2
ink		= 4
paper	= 5
fd		= 6
cnt		= 7

; code & I/O location
io8flags	= $8000			; was $8000
font		= $500			; page aligned!

; init stuff
	LDY #0
	STY io8flags			; set colour mode 
	STY paper				; reset background colour, assume 0
	STY ptr
	STY org					; assume font is page-aligned
	LDX #$60				; screen start
	STX ptr+1
	LDX #>font				; font start
	STX org+1

; ****************************
; go for it!

row:
		LDA #8
		STA cnt				; preset raster count
raster:
			LDY #0			; reset horizontal offset
			STY ink			; reset horizontal colour!
char:
				LDA (org)	; CMOS, LDAX is suitable replacement
				STA fd		; font byte read
				LDX #4		; four screen bytes each font byte
fourb:
					ASL fd	; extract leftmost bit
					BCC nleft		; was clear
						LDA ink		; or use foreground colour
						BRA sleft
nleft:
					LDA paper
sleft:
					ASL		; put the colour into leftmost pixel
					ASL
					ASL
					ASL
					ASL fd	; extract next bit
					BCC nright		; was clear
						ORA ink		; or use foreground colour
						BRA sright
nright:
					ORA paper
sright:
					STA (ptr), Y	; store byte
					INY				; advance address
					DEX				; one less for each font byte
					BNE fourb
				LDA org
				CLC
				ADC #8		; next char is 8 bytes ahead in font
				STA org		; assume page-aligned, otherwise carry might occur!
				INC ink		; each char in a different colour
				CPY #64		; end of raster?
				BNE char
; new raster, must reset screen offset
			TYA				; it is 64 already
			CLC
			ADC ptr			; ptr += Y
			STA ptr
			BCC rnw
				INC ptr+1	; will happen every 4 rasters!
rnw:
; now get back 16 chars but advance one raster
			LDA org
			SEC
			SBC #127		; 16*8-1
			STA org			; should not wrap...
; before next raster, check out row change
			DEC cnt			; one less raster
			BNE raster
; all rasters done, go for next row
		LDA org
		CLC
		ADC #120			; advance 15 chars, as eventually advanced 1
		STA org
		BCC lnw
			INC org+1
lnw:
		INC paper
		LDA paper
		CMP #16				; all lines done?
		BNE row

; ****************************
; ended, keep psychedelic bars
	LDA #0					; keep colour mode...
lock:
; inverse bars 
	STA io8flags			; set flags
	LDX #4
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	CLC
	ADC #64					; toggle inverse mode... and resolution
	BRA lock
fill:
	.dsb	$500-*, $FF

* = font

#include "../../OS/drivers/fonts/8x8.s"


