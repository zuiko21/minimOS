; Durango-X line routines (Brresenham's Algorithm")
; (c) 2022 Carlos J. Santisteban
; last modified 20220914-0002

; *** input ***
	*	= $F4				; *** placeholder (zpar2) ***

x1:		.byt	0			; NW corner x coordinate (<128 in colour, <256 in HIRES)
y1:		.byt	0			; NW corner y coordinate (<128 in colour, <256 in HIRES)
x2:wid:	.byt	0			; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES)
							; alternatively, width (will be converted into x1,x2 format
y2:hei:	.byt	0			; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES)
							; alternatively, height (will be converted into y1,y2 format
col:	.byt	0			; pixel colour, in II format (17*index), HIRES expects 0 (black) or $FF (white), actually zpar

; *** zeropage usage and local variables ***
	*	= $E4				; *** placeholder (local1) ***

cio_pt:	.word	0			; screen pointer

; *** other variables (not necessarily in zero page) ***


; *** zeropage usage *** whatever PLOT uses

dxline:
.(
	LDX #1
	LDA x2
	SEC
	SBC x1					; *** this is NOT abs(x1-x0)
	BCS set_sx				; if x0>=x1...
		LDX #$FF			; sx=-1, else sx=1
set_sx:
	STX sx
	STA dx
	LDY #1
	LDA y1
	SEC
	SBC y2					; *** this is NOT -abs(y1-y0)
	BCC set_sy				; if y0>=y1...
		LDY #$FF			; sy=-1, else sy=1
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
.)
