; 65816 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020 Carlos J. Santisteban

; *** CAVEATS ***
; Array up to about 65536 elements
; Execution limit is not fully accurate, stopping at 1,000,013,824 cars
; Array elements are bytes, containing either zero or any non-zero value
; 32-bit total and 16-bit partial counters

; *** memory use ***
total	.dsb	4, 0	; 32-bit total counter
array	.dsb	65536	; best on bank boundary start

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
			REP #$21	; (0/3) ...else use 16-bit memory for a moment AND clear Carry
			TYA			; (0/2) add partial...
			ADC total	; (0/4) ...to current total
			STA total	; (0/4)
			LDA total+2	; (0/4) ditto for high order word...
			ADC #0		; (0/3) ...as carry may propagate
			CMP #15259	; (0/3) already at the limit?
				BEQ over; (0/2) return -1 if so, executes at most ONCE 
			STA total+2	; (0/4)
			SEP #$20	; (0/3) back to 8-bit accesses
next:
		DEX				; (2) go for next element
		BNE loop		; (3)
	BRA end				; will preserve computed total
over:
		LDX #$FFFF		; load value as -1
		STX total		; set total counter
		STX total+2
end:
; ************
