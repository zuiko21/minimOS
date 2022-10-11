; Durango-X line routines (Bresenham's Algorithm) *** unoptimised version
; (c) 2022 Carlos J. Santisteban
; last modified 20221011-2345

#define	LINES
; *** input *** placeholder addresses
x1		= $EC				; NW corner x coordinate (<128 in colour, <256 in HIRES)
y1		= x1+1				; NW corner y coordinate (<128 in colour, <256 in HIRES)
x2		= y1+1				; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES)
y2		= x2+1				; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES)
px_col	= y2+1				; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables *** 
sx		= px_col+1
sy		= sx+1
dx		= sy+1				; I'm afraid these need 16-bit
dy		= dx+2
error	= dy+2				; colour mode cannot be over 254, but 16-bit arithmetic needed
err_n	= error+2			; make room for this! only d7 used

; these are for PLOT, actually
cio_pt	= err_n+1			; screen pointer
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
	LDX #0					; prepare sign-extention
	STA dx
	BIT #128				; eeeek
	BEQ dx_plus
		DEX
dx_plus:
	STX dx+1				; sign-extention on MSB
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
	LDY #0					; prepare sign extention
	EOR #$FF				; negate ABS
	INC
	STA dy
	BIT #128
	BEQ dy_plus
		DEY
dy_plus:
	STY dy+1				; sign-extention on MSB
	CLC
	ADC dx
	STA error				; error=dx+dy
	TYA						; was (dy+1)
	ADC #0;dx+1
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
		TAY					; Y = e2.lsb
		ROR err_n			; keep e2.d8 at err_n.d15 EEEEEK
		BIT err_n			; EEEEEEK
			BMI if_y		; e2>255, thus always greater than dy
		CPY dy
		BMI if_x			; if e2>=dy... signed EEEEEEK
if_y:
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
		BIT err_n			; check e2.d8
			BMI l_loop		; cannot be less than dx!
		CPY dx
		BEQ then_x
		BPL l_loop			; if e2<=dx...
then_x:
			LDX y1
			CPX y2
			BEQ l_loop		; if y0==y1 break
		LDA error
		CLC
		ADC dx
		STA error			; error += dx
		LDA error+1
		ADC dx+1
		STA error+1			; MSB too EEEEEK
		LDA y1
		CLC
		ADC sy
		STA y1				; y0 += sy
		BRA l_loop
l_end:
	RTS						; eeeek
.)
