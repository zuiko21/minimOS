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
	LDA #%00100000			; check legacy ID
	STA IOkbd
;	LDA IOkbd
;	CMP #$2C
	LDA #%00000001			; first legacy column
loop:
		STA IOkbd
		JSR delay
		ASL
		CMP #%00100000		; all five columns done?
		BNE loop
	STZ IOkbd
	JSR delay				; pause at legacy condition
	JSR delay
	JSR delay
	LDA #%01000000			; check extended ID
	STA IOkbd
;	LDA IOkbd
;	CMP #$88
	LDA #%10000000			; first extended column
xloop:
			STA IOkbd
			JSR delay
			INC
			BIT #%00001000	; all 8 columns done?
			BEQ xloop
		BIT #%00010000		; will use this bit for Caps Lock flag
		BNE exit			; will end with caps lock on
			LDX #%11000000	; will turn on caps (was native)
			STX IOkbd
			LDX #%10000000	; back to standard native
			STX IOkbd
			LDA #%10010000	; set flag
			BRA xloop		; and try again
exit:
	LDA #127				; end of test, beep
beep:
		STA IOBeep
bdly:
			INX
			BNE bdly
		DEC
		BPL beep
	LDA #%00000000			; select caps lock...
	STA IOkbd
	LDA #%01000000			; ...and disable it
	STA IOkbd
	LDA #%10000000			; stay native
	STA IOkbd
lock:
	BRA lock

delay:
	LDX #0
	LDY #0
dloop:
			NOP:NOP
			INX
			BNE dloop
		INY
		BNE dloop
	RTS
