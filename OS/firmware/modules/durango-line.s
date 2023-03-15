; Durango-X line routines (Bresenham's Algorithm) *** unoptimised version
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230203-2152

#ifndef	USE_PLOT
#define	USE_PLOT
; *** input *** placeholder addresses
x1		= $EC				; NW corner x coordinate (<128 in colour, <256 in HIRES)
y1		= x1+1				; NW corner y coordinate (<128 in colour, <256 in HIRES)
x2		= y1+1				; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES)
y2		= x2+1				; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES)
px_col	= y2+1				; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables *** 
sx		= px_col+1
sy		= sx+1
dx		= sy+1				; this is ALWAYS positive...
dy		= dx+1				; ...but this one is negative OR zero
error	= dy+2				; colour mode cannot be over 254, but 16-bit arithmetic needed
err_2	= error+2			; make room for this!

; these are for PLOT, actually
cio_pt	= err_2+2			; screen pointer
gr_tmp	= cio_pt+2			; (temporary storage, could be elsewhere)
tmp		= gr_tmp			; hopefully works! (demo only)
#endif

dxline:
.(
; compute dx, sx
	LDX #1					; temporary sx
	LDA x2
	SEC
	SBC x1					; this is NOT abs(x1-x0) yet...
	BCS set_sx				; if x0>x1...
		LDX #$FF			; sx=-1, else sx=1
		EOR #$FF			; ...and compute ABS(x1-x0) from x1-x0
		INC					; CMOS only, could use ADC #1 as C known to be clear
set_sx:
	STX sx
	STA dx
; compute dy, sy
	LDY #1					; temporary sy
	LDA y2
	LDX #$FF				; usual final dy sign!
	CMP y1					; if dy=0...
	BNE ne_dy
		INX					; ...MSB is 0 (positive)
ne_dy:
	SEC
	SBC y1					; this is NOT -abs(y1-y0) yet...
	BCS set_sy				; if y0>y1...
		LDY #$FF			; sy=-1, else sy=1
		EOR #$FF			; ...and compute ABS(y1-y0) from y1-y0
		INC					; CMOS only, could use ADC #1 as C known to be clear
set_sy:
	STY sy
	STA dy
; dy = -dy
	SEC
	LDA #0
	SBC dy
	STA dy
	STX dy+1				; definitive sign, previously computed EEEEEEEK
; compute error = dx + dy
	CLC
	ADC dx
	STA error				; error=dx+dy
	TXA						; was dy.h
	ADC #0					; dx ALWAYS positive
	STA error+1				; MSB, just in case
l_loop:
		LDX x1
		LDY y1
		JSR dxplot			; *** call primitive with X/Y, assume colours already set ***
		LDA x1
		CMP x2				; if x0==x1...
		BNE l_cont
			LDA y1			; ...and y1==y0...
			CMP y2
			BEQ l_end		; break
l_cont:
		LDA error
		ASL 				; e2=2*error
		STA err_2
		LDA error+1
		ROL
		STA err_2+1
; compute 16-bit signed difference
		SEC
		LDA err_2
		SBC dy				; don't care about result, just look for the sign on MSB
		LDA err_2+1
		SBC dy+1
; if e2<dy, N is set
		BMI if_x
then_y:						; *** do this if e2 >= dy ***
			LDX x1
			CPX x2
			BEQ if_x		; if x0==x1 break
				LDA error
				CLC
				ADC dy
				STA error	; error += dy
				LDA error+1
				ADC dy+1
				STA error+1	; MSB too EEEEEK
				LDA x1
				CLC
				ADC sx
				STA x1		; x0 += sx
if_x:
; compute 16-bit signed difference
		SEC
		LDA dx
		SBC err_2			; don't care about result, just look for the sign on MSB
		LDA #0				; dx ALWAYS positive
		SBC err_2+1
; if dx<e2, N is set -- that means if e2<=dx, N is clear
		BMI l_loop
then_x:						; *** do this if e2 <= dx ***
			LDX y1
			CPX y2
			BEQ l_loop		; if y0==y1 break
		LDA error
		CLC
		ADC dx
		STA error			; error += dx
		LDA error+1
		ADC #0				; dx ALWAYS positive
		STA error+1			; MSB too EEEEEK
		LDA y1
		CLC
		ADC sy
		STA y1				; y0 += sy
		BRA l_loop
l_end:
	RTS						; eeeek
.)
