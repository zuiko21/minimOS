IO8attr	= $DF80
screen	= $6000
ptr	= 3

*	= $400				; actually position-independent

	LDA #$38			; colour mode, RGB enabled
	STA IO8attr

	LDY #<screen
	LDX #>screen
	STY ptr				; create pointer
	STX ptr+1

	LDA #$99			; bluish
up:
			STA (ptr), Y
			INY
			BNE up
		INX
		STX ptr+1		; next page
		CPX #$70		; half way?
		BCC up
	LDA #$77			; yellow
down:
			STA (ptr), Y
			INY
			BNE down
		INX
		STX ptr+1
		BPL down
lock:
	BMI lock			; stay here
