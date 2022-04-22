; video stress test for Durango-X, colour mode (x2)
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20220422-1559

; ****************************
; *** standard definitions ***
	IO8lh	= $DF80
	IO8blk	= $DF88			; new, blanking signals
	IOAen	= $DFA0
	IOBeep	= $DFB0
; ****************************

	pt		= 2				; indirect pointer
	wrap	= 4
/*
* = $400					; downloadable start address *** Commented for La Jaqueria ***

	SEI						; standard 6502 stuff, don't care about stack
	CLD
; Durango-X specific stuff

	LDA #$38				; flag init, colour, screen 3
	STA IO8lh				; set video mode */
again:
		LDA #$60
		STA pt+1
		LDY #0
		STY pt
line:
			LDA (pt)		; first byte in line
			STA wrap		; will be at the end
			LDY #1
loop:
				LDA (pt), Y		; get current byte
				DEY
				STA (pt), Y		; update screen
				INY
				INY
				CPY #64
				BNE loop
			DEY				; back to last byte in line
			LDA wrap		; place wrapped byte
			STA (pt), Y
			LDA pt			; next line
			CLC
			ADC #64			; eeeeek! colour mode
			STA pt
			BNE line
		INC pt+1
		BPL line
	BMI again				; repeat forever

