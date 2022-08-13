; Durango-X filled rectangles demo!
; (c) 2022 Carlos J. Santisteban
; last modified 20220813-1628

#include "fill.s"

reset:
	SEI
	CLD
	LDX #$FF
	TXS
	STX $DFA0				; will turn off LED for peace of mind
	STX col					; original colour (white)

	JSR randomize

loop:
		JSR random			; get random coordinates and colour
		JSR filled			; draw rectangle
		JMP loop			; in aeternum

; set random seed
randomize:

	RTS

; fill coordinates randomly
random:
	LDA #32		; fixed placeholders
	STA x1
	STA y1
	LDA #96
	STA x2
	STA y2

	RTS

; generate random number (TBD)
rnd:
	RTS

; *** fill and vectors ***
	.dsb	$FFFA-*, $FF

	.word reset
	.word reset
	.word reset
	
