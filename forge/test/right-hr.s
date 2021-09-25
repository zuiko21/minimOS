; test of HiRes Druango-X screen
; (c) 2021 Carlos J. Santisteban 

	* =	$400

ptr = 0

	LDA #$B0
	STA $8000				; hires mode
	STA $DF80
	LDX #$60
	LDY #0
	STX ptr+1
	STY ptr
loop:
		TYA
		AND #31				; 32 bytes per line
		CMP #15
		BNE norm			; something in the middle
			TXA				; high-byte address
			BRA put
norm:
		CMP #31				; seeking for the last column
		BNE blk
			LDA #%01010101	; four spaced pixels
			BNE put
blk:
		LDA #0
put:
		STA (ptr), Y
		INY
		BNE loop
	INX
	STX ptr+1
	BPL loop
lock:
	BMI lock
