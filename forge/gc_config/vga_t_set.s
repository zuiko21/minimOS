; graphic card auto-configuration firmware module
; suitable for Tampico and perhaps Acapulco computers
; (c) 2020 Carlos J. Santisteban
; last modified 20200505-0926

; first of all, preconfigure CRTC to desired first mode
; *** TO DO **

; clear the screen
	LDX #$60		; Tampico & Acapulco screen takes $6000-$7FFF in line-doubled mode
	LDY #0			; will reset index too
	TYA				; clear value
	STX z_pt+1		; set zeropage pointer
	STY z_pt
vs_cls:
		STA (z_pt), Y	; clear screen byte
		INY				; go for next byte in page
		BNE vs_cls
			INC z_pt+1		; next page
		BPL vs_cls		; fortunately, it's until the last "positive" address!

; *******************************************************************************
; *** now let's place some patterns at the corners of every screen resolution ***
; *******************************************************************************
; 170 for left side, 85 for the right (via LSR/ASL)
; $6000 is upper left on ALL modes
; add 31, 35 or 39 for upper right ($601F, $6023 & $6027)
; bottom is much more difficult... base scanline offset is 7168 (7 Ki) or $8C00
; but must add (rows-1)*cols for the left, adding (cols-1) for the right

	LDA #%10101010	; leftmost pattern
	STA $6000		; upper left is always the same address
	STA $7FA0		; store at bottom left places (f/32, 40 & 36)
	STA $7FC0
	STA $7FCC
	LSR				; makes %01010101 for rightmost pattern
	STA $601F		; store at upper right positions (32, 36 & 40)
	STA $6023
	STA $6027
	STA $7FBF		; store at bottom right places (32, 40 & 36)
	STA $7FE7
	STA $7FEF

; with suitable patterns on screen, make a 10s timeout
; if CR is pressed, keep current mode and go on
; if timeout expired, set safe mode (36-D) and go on
; every time SPC is pressed, cycle between modes and reset timer
; suggested order is:
; 40 (40x25, VGA industry standard timing)
; 36 (36x28, standard timing)
; 32-L (32x30, VSYNC set for Leading edge)
; 32-T (32x30, VSYNC set for Trailing edge)
; 40-DS (40x25 on 24.576 MHz dotclock and shorter sync)
; 36-D (36x28 on 24.576, SAFEST mode)
; 32-DL (32x30 on 24.576, VSYNC set for Leading edge)
; 32-DT (32x30 on 24.576, VSYNC set for Trailing edge)
