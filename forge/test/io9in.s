; Durango IO9 test (input)
; (c) 2021 Carlos J. Santisteban

* = $400

	LDA #%10110000			; HIRES, non-inverse
	STA $DF80
loop:
		LDA $DF90			; pick whatever is in the port
		LDX #0
fill:
			STA $7000, X	; fill that value
			INX
			BNE fill
		BEQ loop			; forever

