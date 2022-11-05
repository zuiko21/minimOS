; Durango-X non-filled rectangles demo!
; (c) 2022 Carlos J. Santisteban
; last modified 20221105-1652

#include "hollow.s"
seed	= $FE

;#define	HIRES		_HIRES
;#define	MONDRIAN	_MONDRIAN

#ifdef	HIRES
#define	LIMIT	255
#else
#define	LIMIT	127
#endif

reset:
	SEI
	CLD
	LDX #$FF
	TXS
	STX $DFA0				; will turn off LED for peace of mind
	STX col					; original colour (white)
#ifdef	HIRES
	LDA #$B0
#else
	LDA #$38
#endif
	STA IO8attr

	JSR randomize

loop:
		JSR random			; get random coordinates and colour
		JSR rect			; draw rectangle
		JMP loop			; in aeternum

; set random seed
randomize:
#ifdef	MONDRIAN
	LDX #$88
	STX seed
	INX
	STX seed+1
#else
	LDA #1
	STA x1
	STA y1
	LDA #3
	STA x2
	STA y2
	LDA #0
	STA col
#endif
	RTS

; fill coordinates randomly
random:
#ifdef	MONDRIAN
	JSR rnd
	AND #LIMIT
	STA x1
	JSR rnd
	AND #LIMIT
	STA x2
	JSR rnd
	AND #LIMIT
	STA y1
	JSR rnd
	AND #LIMIT
	STA y2
	JSR rnd
#ifdef	HIRES
#ifndef	TEXTURE
	LSR
	LDA #0
	SBC #0		; $FF if C was clear, 0 if set
#endif
#else
	AND #15
	STA tmp
	ASL
	ASL
	ASL
	ASL
	ORA tmp
#endif
	STA col
#else
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
#ifdef	HIRES
	EOR #$FF
#else
	CLC
	ADC #$11
	BCC col_ok
		LDA IO8attr
;		EOR #64
		STA IO8attr
		LDA #0
col_ok:
#endif
	STA col
#endif
	RTS

; *** generate random number ***
; based on code from https://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
rnd:
	LDA seed
		BEQ lo_z
	ASL seed
	LDA seed+1
	ROL
	BCC no_eor
do_eor:
		STA seed+1
do_eor2:
		LDA seed
		EOR #$2D
		STA seed
	RTS
lo_z:
	LDA seed+1
		BEQ do_eor2
	ASL
	BEQ no_eor
	BCS do_eor
no_eor:
	STA seed+1
	RTS

; *** fill and vectors ***
	.dsb	$FFFA-*, $FF

	.word reset
	.word reset
	.word reset
	
