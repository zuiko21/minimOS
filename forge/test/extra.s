; test of Durango-X extra features
; (c) 2021-2022 Carlos J. Santisteban 

* = $400					; adequate space

	LDA #$38				; colour mode
	LDX #0
	LDY #0
loop:
	STA $DF80				; set flags
	STA $DFA0				; not addressable, but make LED blink
	NOP
	LDA $DF80				; read them back!
	INX
	BNE loop
	INY
	BNE loop
	CLC
	ADC #$10
	AND #$F0
	BNE loop

blank:
	LDA $DF88			; new blanking flags
	ROL
	ROL
	ROL
	STA $DFB0			; beep whatever frame is
	BRA blank
	
	LDA #%00010101
	CLC
blink:
	STA $DFA0
	LDX #0
	LDY #0
bloop:
	INX
	BNE bloop
	INY
	BNE bloop
	ROR
	BNE blink
