; Durango-X startup sound
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-1658

.(
	test	= sys_sp		; temporary storage

	LDA #0
	STA test				; sweep counter
sweep:
		LDX #8				; sound length in half-cycles
beep_l:
			TAY				; determines frequency (2)
			STX IOBeep		; send X's LSB to beeper (4)
rb_zi:
				STY test+1	; small delay for 1.536 MHz! (3)
				DEY			; count pulse length (y*2)
				BNE rb_zi	; stay this way for a while (y*3-1)
			DEX				; toggles even/odd number (2)
			BNE beep_l		; new half cycle (3)
		STX IOBeep			; turn off the beeper!
		LDA test			; period goes down, freq. goes up
		SEC
		SBC #4				; frequency change rate
		STA test
		CMP #16				; upper limit
		BCS sweep
.)
