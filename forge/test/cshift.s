; video stress test for Durango-X, colour mode
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211209-1324

; ****************************
; *** standard definitions ***
	IO8lh	= $DF80
	IO8blk	= $DF88			; new, blanking signals
	IOAen	= $DFA0
	IOBeep	= $DFB0
; ****************************
	ptr		= 2				; indirect pointer
	left	= 4
	right	= 5

* = $400					; downloadable start address

	SEI						; standard 6502 stuff, don't care about stack
	CLD
; Durango-X specific stuff

	LDA #$38				; flag init, colour, screen 3
	STA IO8lh				; set video mode
again:
		LDA #$60
		STA ptr+1
		LDY #0
		STY ptr
line:
			LDA (ptr)		; first byte in line
			STA right		; will rotate MSN in
			LDY #63
loop:
				LDX #4		; bits to be shifted
				LDA (ptr), Y		; get current byte
bits:
					ASL right		; get this from right
					ROL				; rotate into screen...
					ROL left		; ...and into left LSN
					DEX
					BNE bits
				STA (ptr), Y		; update screen
				LDA left	; move shifted bits to the other side...
				ASL
				ASL
				ASL
				ASL
				STA right	; ...into high nibble!
				DEY			; go for next byte
				BPL loop
			LDA ptr
			CLC
			ADC #64			; eeeeek! colour mode
			STA ptr
			BNE line
		INC ptr+1
		BPL line
	BMI again				; repeat forever
