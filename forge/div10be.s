; divide-by-10 algorithm by Ben Eater

; input = value.w
; output = mod10 (.w?)
; string = message

divide:
; intitialise reminder to zero
	STZ mod10
	STZ mod10+1
	CLC

	LDX #16
divloop:
; rotate quotient and reminder
		ROL value
		ROL value+1
		ROL mod10
		ROL mod10+1

; AY = dividend-divisor
		SEC
		LDA mod10
		SBC #10
		TAY					; save low byte
		LDA mod10+1
		SBC #0
		BCC ignore_result	; branch if dividend < divisor
			STY mod10
			STA mod10+1
ignore_result:
		DEX
		BNE divloop
	ROL value				; shift in the last bit of quotient
	ROL value+1

lda mod10
	CLC
	ADC #'0'
	; print...
	JSR push_char

; if value != 0, continue
	LDA value
	ORA value+1
	BNE divide
; *** end, print string ***

; *** routines ***
; add char in A to beginning of string
push_char:
	PHA						; first char onto stack
	LDY #0
char_loop:
		LDX message, Y
		PLA
		STA message, Y			; pull char and add it to the string
		INY
		TXA
		PHA						; push char from string onto stack
		BNE char_loop
	PLA
	STA message, Y				; pull NULL from stack and terminate string
	RTS
