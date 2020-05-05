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
		
