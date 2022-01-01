; video stress test for Durango-X
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211221-2316

; ****************************
; *** standard definitions ***
	IO8lh	= $DF80			; will become $DF80
	IO8blk	= $DF88			; new, blanking signals
	IOAen	= $DFA0			; will become $DFA0
	IOBeep	= $DFB0			; will become $DFB0
; ****************************
	ptr		= 2				; indirect pointer

* = $400					; downloadable start address

	SEI						; standard 6502 stuff, don't care about stack
	CLD
; Durango-X specific stuff

	LDA #$F0				; flag init, hires, screen 3, plus int off
	STA IO8lh				; set video mode
	STA IOAen				; ...and interrupts

again:
		LDA #$60
		STA ptr+1
		LDY #0
		STY ptr
line:
			LDY #0			; for NMOS compatibility
			LDA (ptr), Y	; index not needed
			ASL
			LDY #31
loop:
				LDA (ptr), Y
				ROL
				STA (ptr), Y
				DEY
				BPL loop
			LDA ptr
			CLC
			ADC #32
			STA ptr
			BNE line
		INC ptr+1
		BPL line
	BMI again
