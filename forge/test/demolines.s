; Durango-X lines demo!
; (c) 2022 Carlos J. Santisteban
; last modified 20220927-1859

*	= $F000

#include "../../OS/firmware/modules/durango-line.s"
#include "../../OS/firmware/modules/durango-plot.s"

seed	= $FE

;#define	HIRES

#ifdef	HIRES
#define	LIMIT	255
#else
#define	LIMIT	63
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
		LDY y2
;		JSR dxplot
		JSR dxline			; draw line
/*
kkk:
ldx #$60
ldy #0
sty cio_pt
lda px_col
lll:
	stx cio_pt+1
jjj:
		sta (cio_pt),y
		iny
		bne jjj
	inx
	bpl lll
www:
bit $df88
bvc www
inc px_col
bra kkk*/
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
	STA x2
	JSR rnd
	AND #LIMIT
	STA y1
	JSR rnd		; comment for horizontal only
	AND #LIMIT
	STA y2
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
	
