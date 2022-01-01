; (c) 2013-2022 Carlos J. Santisteban
* = $F800

reset:	SEI
		CLD
		LDX #$FF
		TXS
		STX $6FF2
		STX $6FF3
		STZ $6FF0
		STZ $6FF1
		LDA #$E0
		STA $6FFC
		STZ $6FFB
		sed
		LDX #0
		LDY #0
loop:	DEX
		BNE loop
		DEY
		BNE loop
		INC $6FF1
		BNE loop
		INC $6FF0
		BRA loop
		
nmi:	CLD
		LDA #$CA
		STA $6FF0
		LDA #$FE
		STA $6FF1
delay:	DEX
		BNE delay
		DEY
		BNE delay
		LDA $6FFC
		EOR #%00100000
		STA $6FFC
		BRA delay

irq:	RTI		
		
* = $FFFA
		.word nmi
		.word reset
		.word irq
