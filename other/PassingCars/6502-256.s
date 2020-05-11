; Simple 65(C)02 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020 Carlos J. Santisteban

; *** CAVEATS ***
; No execution limit
; Array up to 256 elements
; Array elements are bytes, containing either zero or any non-zero value

; *** memory use ***
total	.byt	0		; single-byte counter
array	.dsb	256, 0	; array

; ************
; *** CODE ***
; ************
	LDX #length-1		; start from the LAST element, going backwards
	LDY #0				; reset partial counter (Y)
	STY total			; reset total too
loop:
		LDA array, X	; get element from array (zero or otherwise)
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
		CPX #$FF
		BNE loop
; ************
