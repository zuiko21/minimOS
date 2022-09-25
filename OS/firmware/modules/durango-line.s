; Durango-X line routines (Bresenham's Algorithm) *** unoptimised version
; (c) 2022 Carlos J. Santisteban
; last modified 20220925-1812

; *** input *** placeholder addresses
x1		= $F4				; NW corner x coordinate (<128 in colour, <256 in HIRES)
y1		= x1+1				; NW corner y coordinate (<128 in colour, <256 in HIRES)
x2		= y1+1				; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES)
y2		= x2+1				; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES)
px_col	= y2+1				; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables *** for PLOT, actually
cio_pt	= px_col+1			; screen pointer
fw_cbyt	= cio_pt+2			; (temporary storage, could be elsewhere)

dxline:
.(
	LDA x2
	SEC
	SBC x1					; this is NOT abs(x1-x0) yet...
	LDX #1
	BCS set_sx				; if x0>=x1...
		LDX #$FF			; sx=-1, else sx=1
		EOR #$FF			; ...and compute ABS(x1-x0) from x1-x0
		INC					; CMOS only, could use ADC #1 as C known to be clear
set_sx:
	STX sx
	STA dx
	LDA y1
	SEC
	SBC y2					; this is NOT -abs(y1-y0) yet...
	LDY #1
	BCC set_sy				; if y0>=y1...
		LDY #$FF			; sy=-1, else sy=1
		EOR #$FF			; ...and compute -ABS(y1-y0) from y0-y1, is this OK?
		INC					; CMOS only, could use ADC #0 as C known to be set
set_sy:
	STY sy
	STA dy
	CLC
	ADC dx
	STA error				; error=dx+dy
l_loop:
		LDX x1
		LDY y1
		JSR dxplot			; *** call primitive with X/Y, assume colours already set ***
		LDA x1
		CMP x2				; if x0==x1...
		BNE l_cont
			LDA y1			; ...and y1==y0...
			CMP y1
			BEQ l_end		; break
l_cont:
		LDA error
		ASL					; e2=2*error
		TAY
			BCS if_y		; e2>255
		CMP dy
		BCC if_x			; if e2>=dy...
if_y:
			LDX x1
			CPX x2
			BEQ if_x		; if x0==x1 break
				LDA error
				CLC
				ADC dy
				STA error	; error += dy
				LDA x1
				CLC
				ADC sx
				STA x1		; x0 += sx
				TYA
if_x:
		CMP dx
		BEQ then_x
		BCS l_loop			; if e2<=dx...
			LDX y1
			CPX y2
			BEQ l_loop		; if y0==y1 break
		LDA error
		CLC
		ADC dx
		STA error			; error += dx
		LDA y1
		CLC
		ADC sy
		STA y1				; y0 += sy
		BRA l_loop
l_end:
	RTS						; eeeek
.)
