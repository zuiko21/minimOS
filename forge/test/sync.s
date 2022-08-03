	* = $FF00

start:
	LDA #$38
	STA $DF80
	LDX #$60
	LDY #0
	STX $81
	STY $80
loop:
		LDA $DF88
		AND #%11000000		; vs only
		LSR			; hs=dark green, vs=red
		STA ($80), Y
		INY
		BNE loop
	INC $81
	BPL loop
	BMI start

	.dsb	$FFFC-*, $FF

	.word 	start
	.word	start

