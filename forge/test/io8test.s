; test of preliminary connection
; (c) 2021 Carlos J. Santisteban

	* =	$400
	
loop:
	STA $8003
	JSR delay
	INX
	BNE loop
	INY
	BNE loop
	INC
	BRA loop
delay:
	RTS
