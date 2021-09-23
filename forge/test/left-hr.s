; test of HiRes Druango-X screen
; (c) 2021 Carlos J. Santisteban 

	* =	$400

ptr = 0

	LDA #$80
	STA $8000				; set hires mode
	STA $DF80
	LDX #$60
	LDY #0
	STX ptr+1
	STY ptr
loop:
		TYA
		AND #31				; 32 bytes per line
		CMP #29
		BNE norm			; something near the edge
			TXA				; high-byte address
			BRA put
norm:
		CMP #0
		BNE blk
			LDA #%01010101	; four spaced pixels***
			CPX #$70		; modify middle lines
			BNE put
				LDA #%11000000	; just two leftmost pixels
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
