; PASK test for Durango-X
; (c) 2022 Carlos J. Santisteban

* = $FF00

reset:
	SEI
	CLD
	LDX #$FF
	TXS
	STX $DFA0
	LDA #$38
	STA $DF80
	LDY #0
	STY $80
do:
		LDX #$60
page:
			STX $81
loop:
				LDA $DF9A
				STA ($80), Y
				INY
				BNE loop
			INX
			BPL page
		BMI do

	.dsb	$FFFA-*, $FF

	.word reset
	.word reset
	.word reset
