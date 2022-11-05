; Durango-X circle routine (Midpoint Algorithm) *** unoptimised version
; (c) 2022 Carlos J. Santisteban
; last modified 20221105-1338

#define	USE_PLOT
; *** input *** placeholder addresses
x0		= $EC				; NW corner x coordinate (<128 in colour, <256 in HIRES)
y0		= x0+1				; NW corner y coordinate (<128 in colour, <256 in HIRES)
radius	= y0+1				; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES)
px_col	= radius+1			; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables *** 
f		= px_col+1			; 16-bit
ddf_x	= f+2				; maybe 8 bit is OK? seems always positive
ddf_y	= ddf_x+2			; starts negative and gets added to f, thus 16-bit
x		= ddf_y+2			; seems 8 bit
y		= x+1				; 8-bit as well

; these are for PLOT, actually
cio_pt	= y+1				; screen pointer
fw_cbyt	= cio_pt+2			; (temporary storage, could be elsewhere)
tmp		= fw_cbyt			; hopefully works! (demo only)

dxcircle:
.(
; compute initial f = 1 - radius
	LDA #1
	SEC
	SBC radius
	STA f					; LSB OK
	LDA #0
	SBC #0
	STA f+1					; sign extention
; ddF_x = 0
	STZ ddf_x
	STZ ddf_x+1
; compute ddF_y = -2 * radius
	STZ ddf_y+1				; clear MSB for a while
	LDA radius
	ASL						; times two
	STA ddf_y				; temporary positive LSB
	ROL ddf_y+1
	LDA #0
	SEC
	SBC ddf_y				; negate
	STA ddf_y
	LDA #0
	SBC ddf_y+1
	STA ddf_y+1				; surely there's a much faster way, but...
; reset x & y
	STZ x
	LDA radius
	STA y
; draw initial dots
;	LDA radius				; already there!
	CLC
	ADC y0
	TAY
	LDX x0
	JSR dxplot				; plot(x0, y0+radius)
	LDA y0
	SEC
	SBC radius
	TAY
	LDX x0
	JSR dxplot				; plot(x0, y0-radius)
	LDY y0
	LDA x0
	CLC
	ADC radius
	TAX
	JSR dxplot				; plot(x0+radius, y0)
	LDY y0
	LDA x0
	SEC
	SBC radius
	TAX
	JSR dxplot				; plot(x0-radius, y0)
; main loop while x < y
loop:
	LDA x
	CMP y
	BCC c_cont
	JMP c_end				; if x >= y, exit
c_cont:
; if f >= 0... means MSB is positive
		BIT f+1
		BMI f_neg
			DEC y
			LDA ddf_y		; add 2 to ddF_y
			CLC
			ADC #2
			STA ddf_y
			TAY				; convenient LSB storage
			LDA ddf_y+1
			ADC #0
			STA ddf_y+1
			TAX				; convenient MSB storage...
			TYA				; ...for adding ddF_y to f
			CLC
			ADC f
			STA f
			TXA
			ADC f+1
			STA f+1
f_neg:
		INC x
		LDA ddf_x			; add 2 to ddF_x
		CLC
		ADC #2
		STA ddf_x
		TAY					; again, convenient storage...
		LDA ddf_x+1
		ADC #0
		STA ddf_x+1
		TAX
		TYA					; ...for adding ddF_x to f...
		SEC					; ...plus 1!
		ADC f
		STA f
		TXA
		ADC f+1
		STA f+1
; do 8 plots per iteration
	LDA x0
	CLC
	ADC x
	TAX
	LDA y0
	CLC
	ADC y
	TAY
	JSR dxplot				; plot(x0+x, y0+y)
	LDA x0
	SEC
	SBC x
	TAX
	LDA y0
	CLC
	ADC y
	TAY
	JSR dxplot				; plot(x0-x, y0+y)
	LDA x0
	CLC
	ADC x
	TAX
	LDA y0
	SEC
	SBC y
	TAY
	JSR dxplot				; plot(x0+x, y0-y)
	LDA x0
	SEC
	SBC x
	TAX
	LDA y0
	SEC
	SBC y
	TAY
	JSR dxplot				; plot(x0-x, y0-y)
	LDA x0
	CLC
	ADC y
	TAX
	LDA y0
	CLC
	ADC x
	TAY
	JSR dxplot				; plot(x0+y, y0+x)
	LDA x0
	SEC
	SBC y
	TAX
	LDA y0
	CLC
	ADC x
	TAY
	JSR dxplot				; plot(x0-y, y0+x)
	LDA x0
	CLC
	ADC y
	TAX
	LDA y0
	SEC
	SBC x
	TAY
	JSR dxplot				; plot(x0+y, y0-x)
	LDA x0
	SEC
	SBC y
	TAX
	LDA y0
	SEC
	SBC x
	TAY
	JSR dxplot				; plot(x0-y, y0-x)
	JMP loop
c_end:
	RTS
.)
