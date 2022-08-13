; Durango-X filled rectangles demo!
; (c) 2022 Carlos J. Santisteban
; last modified 20220813-1714

#include "fill.s"
seed	= $FF

reset:
	SEI
	CLD
	LDX #$FF
	TXS
	STX $DFA0				; will turn off LED for peace of mind
	STX col					; original colour (white)
	LDA #$38
	STA IO8attr

	JSR randomize

loop:
		JSR random			; get random coordinates and colour
		JSR filled			; draw rectangle
		JMP loop			; in aeternum

; set random seed
randomize:
	LDX #$88
	STX seed
	INX
	STX seed+1
/*	LDA #0
	STA x1
	STA y1
	LDA #2
	STA x2
	STA y2
	LDA #0
	STA col */
	RTS

; fill coordinates randomly
random:
	JSR rnd
	AND #127
	STA x1
	JSR rnd
	AND #127
	STA x2
	JSR rnd
	AND #127
	STA y1
	JSR rnd
	AND #127
	STA y2
	JSR rnd
	AND #15
	STA tmp
	ASL
	ASL
	ASL
	ASL
	ORA tmp
	STA col
/*
	INC x1
	INC y1
	INC x1
	INC y1
	INC x2
	INC x2
	INC y2
	INC y2
	INC x2
	INC x2
	INC y2
	INC y2
	BPL within
		JSR randomize
within:
	LDA col
	CLC
	ADC #$11
	BCC col_ok
		LDA IO8attr
;		EOR #64
		STA IO8attr
		LDA #0
col_ok:
	STA col */
	RTS

; generate random number (TBD)
rnd:
	LDA seed
	AND #2
	STA tmp				; hope this is OK
	LDA seed+1
	AND #2
	EOR tmp
	CLC
	BEQ rg_z
		SEC
rg_z:
	ROR seed+1				; is this OK?
	ROR seed
	LDA seed				; returns MSB
	RTS
	RTS

; *** fill and vectors ***
	.dsb	$FFFA-*, $FF

	.word reset
	.word reset
	.word reset
	
