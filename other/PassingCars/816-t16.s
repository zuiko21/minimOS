; 65816 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020 Carlos J. Santisteban

; *** CAVEATS ***
; Array up to about 65536 elements
; 16-bit total and partial counters
; No execution limit
; Array elements are bytes, containing either zero or any non-zero value

; *** memory use ***
total	.word	0		; 16-bit total counter
array	.dsb	65536	; best on bank boundary start

; ************
; *** CODE ***
; ************
	
	REP #$10			; use 16-bit indexes...
	SEP #$20			; ...but 8-bit memory/accumlator
	LDX #length			; backwards loop, as usual
	LDY #0				; reset partial...
	STY total			; ...and total counters
loop:
		LDA @array-1, X	; (5) get array element
		BEQ zero		; (2/3) if it's 1... [timing as above]
			INY			; (2/0) ...increment partial
			BRA next	; (3/0)
zero:
			REP #$20	; (0/3) ...else use 16-bit memory for a moment
			TYA			; (0/2) add partial...
			CLC			; (0/2) ...for the first time...
			ADC total	; (0/4) ...to current total
			STA total	; (0/4)
			SEP #$20	; (0/3) back to 8-bit accesses
next:
		DEX				; (2) go for next element
		BNE loop		; (3)
; ************
