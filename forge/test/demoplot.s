; Durango-X lines demo!
; (c) 2022 Carlos J. Santisteban
; last modified 20220925-1833

*	= $F000


#include "../../OS/firmware/modules/durango-plot.s"

seed	= $FE

;#define	HIRES		_HIRES

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
	JSR rnd
	AND #LIMIT
	STA x1
	JSR rnd
;	BEQ ddd
	JSR rnd
	JSR rnd
	AND #LIMIT
ddd:
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

; generate random number (TBD)
rnd:
	JSR get_rnd
	LSR
	LSR
;	LSR
	TAX
rnd_loop:
		JSR get_rnd
		DEX
		BNE rnd_loop
	RTS
get_rnd:
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


; *** fill and vectors ***
	.dsb	$FFFA-*, $FF

	.word reset
	.word reset
	.word reset
	
