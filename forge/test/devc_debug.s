; test
	*=$c000
	
reset:
	SEI
	CLD
	JMP $c100

	.dsb	$c100-*, $FF
	
	LDX #$FF
	STX $DFA0
	JMP $c200

	.dsb	$c200-*, $ff
	
	TXS
	LDX #60
	JMP $ca00		; eeek
	
	.dsb	$c300-*, $ff
	
	STZ 0
	LDY #0
	JMP $c400
	
	.dsb	$c400-*, $ff
	
page:
	STX 1
	TXA
	JMP $c500
	
	.dsb	$c500-*, $ff

byte:
	STA (0), Y
	INY
	BNE byte
	JMP $c600
	
	.dsb	$c600-*, $ff
	
	INX
	BMI no
	JMP page
no:
	BMI no

	.dsb	$c700-*, $ff
int:
	PHA
	LDA $DF80
	JMP $c800
	
	.dsb	$c800-*, $ff
	
	EOR #64
	JMP $c900
	
	.dsb	$c900-*, $ff
	
	STA $DF80
	PLA
	RTI

	.dsb	$ca00-*, $ff
	
	LDA #$3C
	JMP $cb00
	
	.dsb	$cb00-*, $ff
	
	STA $DF80
	JMP $c300

	.dsb	$FFFA-*, $FF
	
	.word	int
	.word	reset
	.word	int
