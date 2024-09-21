; extended keyboard test
; (c) 2024 Carlos J. Santisteban

; *** raw executable at $1000 *** use -x 0x1000 for transfer
*		= $1000

IOkbd	= $DF9B
IOBeep	= $DFB0

start:
	SEI
	LDY #<start
	LDX #>start
	STY $202
	STX $203
	LDA #%10000000			; select caps lock...
	STA IOkbd
	LDA #%11000000			; ...and enable it
	STA IOkbd
	JSR delay
	JSR delay
	JSR delay
	LDA #%00000000			; select caps lock...
	STA IOkbd
	LDA #%01000000			; ...and disable it
	STA IOkbd
	LDA #%10000000			; native for a moment
	STA IOkbd
	JSR delay
	JSR delay
	JSR delay
	LDA #%00000000			; reset
loop:
		STA IOkbd
		JSR delay
		INC
		BNE loop
	STZ IOkbd
	LDA #127
beep:
		STA IOBeep
bdly:
			INX
			BNE bdly
		DEC
		BPL beep
lock:
	BRA lock

delay:
	LDX #0
	LDY #0
dloop:
			INX
			BNE dloop
		INY
		BNE dloop
	RTS
