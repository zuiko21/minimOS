; Durango-X circle routine (Midpoint Algorithm) *** unoptimised version
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230203-2213

#ifndef	USE_PLOT
#define	USE_PLOT
; *** input *** placeholder addresses
x1		= $EC				; NW corner cir_x coordinate (<128 in colour, <256 in HIRES)
y1		= x1+1				; NW corner cir_y coordinate (<128 in colour, <256 in HIRES)
radius	= y1+1				; _not included_ SE corner cir_x coordinate (<128 in colour, <256 in HIRES)
px_col	= radius+1			; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables *** 
cir_f	= px_col+1			; 16-bit
ddf_x	= cir_f+2			; maybe 8 bit is OK? seems always positive
ddf_y	= ddf_x+2			; starts negative and gets added to cir_f, thus 16-bit
cir_x	= ddf_y+2			; seems 8 bit
cir_y	= cir_x+1			; 8-bit as well

; these are for PLOT, actually
cio_pt	= cir_y+1			; screen pointer
gr_tmp	= cio_pt+2			; (temporary storage, could be elsewhere)
tmp		= gr_tmp			; hopefully works! (demo only)
#endif

dxcircle:
.(
; compute initial cir_f = 1 - radius
	LDA #1
	SEC
	SBC radius
	STA cir_f					; LSB OK
	LDA #0
	SBC #0
	STA cir_f+1					; sign extention
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
; reset cir_x & cir_y
	STZ cir_x
	LDA radius
	STA cir_y
; draw initial dots
;	LDA radius				; already there!
	CLC
	ADC y1
	TAY
	LDX x1
	JSR dxplot				; plot(x1, y1+radius)
	LDA y1
	SEC
	SBC radius
	TAY
	LDX x1
	JSR dxplot				; plot(x1, y1-radius)
	LDY y1
	LDA x1
	CLC
	ADC radius
	TAX
	JSR dxplot				; plot(x1+radius, y1)
	LDY y1
	LDA x1
	SEC
	SBC radius
	TAX
	JSR dxplot				; plot(x1-radius, y1)
; main loop while cir_x < cir_y
loop:
	LDA cir_x
	CMP cir_y
	BCC c_cont
	JMP c_end				; if cir_x >= cir_y, exit
c_cont:
; if cir_f >= 0... means MSB is positive
		BIT cir_f+1
		BMI f_neg
			DEC cir_y
			LDA ddf_y		; add 2 to ddF_y
			CLC
			ADC #2
			STA ddf_y
			TAY				; convenient LSB storage
			LDA ddf_y+1
			ADC #0
			STA ddf_y+1
			TAX				; convenient MSB storage...
			TYA				; ...for adding ddF_y to cir_f
			CLC
			ADC cir_f
			STA cir_f
			TXA
			ADC cir_f+1
			STA cir_f+1
f_neg:
		INC cir_x
		LDA ddf_x			; add 2 to ddF_x
		CLC
		ADC #2
		STA ddf_x
		TAY					; again, convenient storage...
		LDA ddf_x+1
		ADC #0
		STA ddf_x+1
		TAX
		TYA					; ...for adding ddF_x to cir_f...
		SEC					; ...plus 1!
		ADC cir_f
		STA cir_f
		TXA
		ADC cir_f+1
		STA cir_f+1
; do 8 plots per iteration
	LDA x1
	CLC
	ADC cir_x
	TAX
	LDA y1
	CLC
	ADC cir_y
	TAY
	JSR dxplot				; plot(x1+cir_x, y1+cir_y)
	LDA x1
	SEC
	SBC cir_x
	TAX
	LDA y1
	CLC
	ADC cir_y
	TAY
	JSR dxplot				; plot(x1-cir_x, y1+cir_y)
	LDA x1
	CLC
	ADC cir_x
	TAX
	LDA y1
	SEC
	SBC cir_y
	TAY
	JSR dxplot				; plot(x1+cir_x, y1-cir_y)
	LDA x1
	SEC
	SBC cir_x
	TAX
	LDA y1
	SEC
	SBC cir_y
	TAY
	JSR dxplot				; plot(x1-cir_x, y1-cir_y)
	LDA x1
	CLC
	ADC cir_y
	TAX
	LDA y1
	CLC
	ADC cir_x
	TAY
	JSR dxplot				; plot(x1+cir_y, y1+cir_x)
	LDA x1
	SEC
	SBC cir_y
	TAX
	LDA y1
	CLC
	ADC cir_x
	TAY
	JSR dxplot				; plot(x1-cir_y, y1+cir_x)
	LDA x1
	CLC
	ADC cir_y
	TAX
	LDA y1
	SEC
	SBC cir_x
	TAY
	JSR dxplot				; plot(x1+cir_y, y1-cir_x)
	LDA x1
	SEC
	SBC cir_y
	TAX
	LDA y1
	SEC
	SBC cir_x
	TAY
	JSR dxplot				; plot(x1-cir_y, y1-cir_x)
	JMP loop
c_end:
	RTS
.)
