; firmware module for minimOS
; nanoBoot loader
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-0014

.(
	LDX #0					; reset index
nb_prn:
		LDA text, X
	BEQ wait				; end of string
		_PHX
		TAY					; print A
		JSR conio
		_PLX
		INX
		BNE nb_prn			; no need for BRA
wait:						; *** placeholder, wait for a couple of seconds ***
	LDA #15					; about 3s wait
loop:
			INY
			BNE loop
		INX
		BNE loop
	_DEC
	BNE loop
	LDY #2					; cursor left
	JSR conio
	LDY #18					; set colour...
	JSR conio
	LDY #2					; ...red
	JSR conio
	LDY #'*'				; delete question mark
	JSR conio
	LDY #18					; set colour...
	JSR conio
	LDY #STD_INK			; ...white?
	JSR conio
	LDY #13
	JSR conio
	JMP continue
text:
	.asc	"nanoBoot?", 0
continue:
.)
