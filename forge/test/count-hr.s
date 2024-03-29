; test of hires Durango-X screen
; (c) 2021-2022 Carlos J. Santisteban 

	* =	$400

ptr = 0

	LDA #$B0				; VRAM at 24K
	STA $8000				; set hires (later $DF80) 
	STA $DF80				; ready for new memory map
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
