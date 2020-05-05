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
					; store at bottom left places
	LSR				; makes %01010101 for rightmost pattern
	STA $601F		; store at upper right positions
	STA $6023
	STA $6027
					; store at bottom right places
	
