; 65816 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020-2022 Carlos J. Santisteban

; *** CAVEATS ***
; Array up to about 65536 elements
; No execution limit
; Array elements are bytes, containing either zero or any non-zero value
; 32-bit total and 16-bit partial counters

; *** memory use ***
total	.dsb	4, 0	; 32-bit total counter
array	.dsb	65535
size	=	65535

; ************
; *** CODE ***
; ************
	REP #$10			; use 16-bit indexes...
	SEP #$20			; ...but 8-bit memory/accumlator
	LDX #length			; backwards loop, as usual
	LDY #0				; reset partial (16-bit)...
	STY total			; ...and total (32-bit) counters
	STY total+2
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
			LDA total+2	; (0/4) ditto for high order word...
			ADC #0		; (0/3) ...as carry may propagate
			STA total+2	; (0/4)
			SEP #$20	; (0/3) back to 8-bit accesses
next:
		DEX				; (2) go for next element
		BNE loop		; (3)
; ************
; 43 bytes, 17 or 42 cycles per iteration
; assuming variables in zeropage
