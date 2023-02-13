; ejemplo cargador en devCart con ROM antigua
; (c) 2023 Carlos J. Santisteban

org	= $80		; puntero origen
dest	= $82		; puntero destino

carga	= $400		; dirección de carga de la imagen (alineada)
rom	= $8400		; destino de la imagen (alineada)

*	= rom		; establece primera dirección

	SEI		; por si acaso
	LDY #<rom	; ambas deben ser igual a cero
	LDA #>carga	; página origen
	LDX #>rom	; página destino
	STY org
	STY dest	; byte bajo punteros
	STA org+1	; byte alto origen
loop_p:
	  STX dest+1	; byte alto destino
loop_b:
	    LDA (org), Y
	    STA (dest), Y	; copia byte
	    INY
	    BNE loop_b
	  INC org+1	; siguiente página
	  INX
	  CPX #$DF	; ¿escribirá en I/O?
	  BNE no_io
	    INC org+1
	    INX		; sáltatela
no_io:
	  TXA
	  BMI loop_p	; la ROM son direcciones negativas
	LDA #%01100000	; modo RAM, protegida
	STA $DFC0	; establece modo cartucho (la RAM ya está activa)
	JMP ($FFFC)	; ¡RESET en la imagen cargada!

; ...resto de la imagen ROM, incuyendo vectores
	.dsb	$FF00-*, $EA; relleno

reset:
	LDY #0
	STY dest
	STY dest+1
	TYA
loop:
		STA (dest), Y
		INY
		BNE loop
	    INC dest+1
	    BPL loop

	LDA #$38
blink:
	    STA $DF80
	    INX
	    BNE blink
	EOR #64
	LDX #14
	NOP
	BRA blink
delay:
	RTS
none:
	RTI

	.dsb	$FFFA-*, $FF

	.word	none
	.word	reset
	.word	none
