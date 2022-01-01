; firmware module for minimOS
; nanoBoot loader
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211230-1656

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
	LDX #0					; reset index
to_prn:
		LDA delete, X
	BEQ continue			; end of string
		_PHX
		TAY					; print A
		JSR conio
		_PLX
		INX
		BNE to_prn			; no need for BRA
text:
	.asc	"nanoBoot?", 0
delete:
	.asc	2, 18, 2, '*', 18, STD_INK, 13, 0
continue:
.)
