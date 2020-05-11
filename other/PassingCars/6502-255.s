; Simple 65(C)02 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020 Carlos J. Santisteban

; *** CAVEATS ***
; No execution limit
; Array up to 255 elements
; Array elements are bytes, containing either zero or any non-zero value

; *** memory use ***
total	.byt	0		; single-byte counter
array	.dsb	255, 0	; array (best NOT at page start!)

; ************
; *** CODE ***
; ************
	LDX #length			; start from the LAST element (index start at 1), going backwards
	LDY #0				; reset partial counter (Y)
	STY total			; reset total too
loop:
		LDA array-1, X	; get element from array, corrected offset (zero or otherwise)
		BEQ zero		; if not zero...
			INY			; ...increment partial counter
			BRA next	; NMOS 6502 could use BNE as well
zero:
			TYA			; else add partial counter...
			CLC
			ADC total	; ...to current total
			STA total
next:
		DEX				; go for next element
		BNE loop
; ************
