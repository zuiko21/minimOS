; Durango-X line routines (Bresenham's Algorithm) *** unoptimised version
; (c) 2022 Carlos J. Santisteban
; last modified 20220930-1236

#define	LINES
; *** input *** placeholder addresses
x1		= $F0				; NW corner x coordinate (<128 in colour, <256 in HIRES)
y1		= x1+1				; NW corner y coordinate (<128 in colour, <256 in HIRES)
x2		= y1+1				; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES)
y2		= x2+1				; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES)
px_col	= y2+1				; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables *** 
sx		= px_col+1
sy		= sx+1
dx		= sy+1
dy		= dx+1
error	= dy+1				: colour mode cannot be over 254, but extra bit is needed for 2*error EEEEEK

; these are for PLOT, actually
cio_pt	= error+2			; screen pointer
fw_cbyt	= cio_pt+2			; (temporary storage, could be elsewhere)
tmp		= fw_cbyt			; hopefully works! (demo only)

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
	LDA y2
	SEC
	SBC y1					; this is NOT -abs(y1-y0) yet...
	LDY #1
	BCS set_sy				; if y0>=y1...
		LDY #$FF			; sy=-1, else sy=1
		EOR #$FF			; ...and compute ABS(y1-y0) from y0-y1, is this OK?
		INC					; CMOS only, could use ADC #1 as C known to be clear
set_sy:
	STY sy
	EOR #$FF				; negate ABS
	INC
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
			CMP y2
			BEQ l_end		; break
l_cont:
		LDA error
		ASL					; e2=2*error
		ROR error+1			; inject e2.d8 into err_h.d7 EEEEEK ******** CHECK
		TAY
		BIT err_n			; check d8...
			BMI if_y		; e2>255 (BCS no longer possible) ******* CHECK
		CPY dy
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
if_x:
		CPY dx
		BEQ then_x
		BCS l_loop			; if e2<=dx...
then_x:
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
