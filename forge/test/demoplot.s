; Durango-X lines demo!
; (c) 2022 Carlos J. Santisteban
; last modified 20220927-1803

*	= $F000


#include "../../OS/firmware/modules/durango-plot.s"

seed	= $FE
magic	= $002D

#define	HIRES

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
	STX px_col				; original colour (white)
#ifdef	HIRES
	LDA #$B0
#else
	LDA #$38
#endif
	STA IO8attr

	JSR randomize

loop:
		JSR random			; get random coordinates and colour
		LDX x1
		LDY y1
		JSR dxplot			; draw line
		JMP loop			; in aeternum

; set random seed
randomize:
	LDX #$88
	STX seed
	INX
	STX seed+1
	RTS

; fill coordinates randomly
random:
; if mondrian
	JSR rnd
	AND #LIMIT
	STA x1
	JSR rnd
	AND #LIMIT
	STA y1
	JSR rnd
#ifndef	HIRES
;	LSR
;	LDA #0
;	SBC #0		; $FF if C was clear, 0 if set
;	if /hires
	AND #15
	STA tmp
	ASL
	ASL
	ASL
	ASL
	ORA tmp
#endif
	STA px_col
	RTS

; generate random number
rnd:
	LDA seed
		BEQ lo_z
	ASL seed
	LDA seed+1
	ROL
	BCC no_eor
do_eor:
;		EOR #>magic
		STA seed+1
do_eor2:
		LDA seed
		EOR #<magic
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
	
