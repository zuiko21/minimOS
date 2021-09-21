; test of hires Durango-X screen
; (c) 2021 Carlos J. Santisteban 

	* =	$400

ptr = 0

	LDA #$80
	STA $8000				; set hires (later $DF80) 
	LDY #0
	STY ptr
	TYA						; first value
repeat:
		LDX #$60			; screen start
		STX ptr+1
loop:
			STA (ptr), Y
			INY
			BNE loop
		INX
		STX ptr+1
		BPL loop
	INC						; next pattern, CMOS only
	BRA repeat
