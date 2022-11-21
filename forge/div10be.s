; divide-by-10 algorithm by Ben Eater

; input = value.w
; output = mod10 (.w?)
; string = message

; assume value & mod10 in ZP, string in regular RAM
; 73b, 847t PER DIVISION ~0.55 ms
divide:
; intitialise reminder to zero
	STZ mod10				; (10 in CMOS per division)
	STZ mod10+1
	CLC

	LDX #16
divloop:
; rotate quotient and reminder
		ROL value			; (16* 5*4)
		ROL value+1
		ROL mod10
		ROL mod10+1

; AY = dividend-divisor
		SEC					; (16* (2+3+2+2+3+2))
		LDA mod10
		SBC #10
		TAY					; save low byte
		LDA mod10+1
		SBC #0
		BCC ignore_result	; branch if dividend < divisor (either 16* 3 or 16* (2+3+3)) 
			STY mod10
			STA mod10+1
ignore_result:
		DEX					; (16* (2+3)-1)
		BNE divloop
	ROL value				; shift in the last bit of quotient (2*5)
	ROL value+1

	LDA mod10				; (3+2+2+6+*+3+3+3)
	CLC
	ADC #'0'
	; print...
	JSR push_char

; if value != 0, continue
	LDA value
	ORA value+1
	BNE divide
; *** end, print string ***
	RTS


; *** routines ***
; add char in A to beginning of string (20+n*31-1) ~96t
push_char:
	PHA						; first char onto stack
	LDY #0
char_loop:
		LDX message, Y
		PLA
		STA message, Y		; pull char and add it to the string
		INY
		TXA
		PHA					; push char from string onto stack
		BNE char_loop
	PLA
	STA message, Y			; pull NULL from stack and terminate string
	RTS
