; interrupt-driven music player for PSG card in Durango-X! TEST CODE
; (c) 2023 Carlos J. Santisteban
; last modified 20230705-1742


; *** hardware definitions ***
IO8attr	= $DF80
IOAen	= $DFA0
screen3	= $6000

; *** zeropage definitions ***
dest	= $F8				; memory filling

*	= $C000					; convenient 16K ROM

	SCORE	= >music

; *** interrupt service ***
#include "player.s"

; *****************
; *** TEST code ***
; *****************
	SEI						; standard stuff
	CLD
	LDX #$FF
	TXS
	STX IOAen				; turn interrupts on
	LDY #<isr				; for DevCart compatibility
	LDX #>isr
	STY $0200
	STX $0201
	LDY #<nmi
	LDX #>nmi
	STY $0202
	STX $0203
	JSR psg_init			; clear stuff!
; init screen
	LDA #%10110000			; HIRES mode
	STA IO8attr
	LDX #>screen3
;	LDY #<screen3			; actually zero
	STZ dest
	STX dest+1
	LDX #1					; initial pattern
raster:
		TXA
		LDY #31
sc_loop:
			STA (dest), Y	; fill one raster
			DEY
			BPL sc_loop
		ASL
		BCC no_wrap			; after bit 7, back to bit 0
			ROL
no_wrap:
		TAX
		LDA dest
		CLC
		ADC #32				; advance to next raster
		STA dest
		BCC raster
			INC dest+1		; next page
		BPL raster
; now should enable playback and start scrolling the screen
	LDA #3					; three channels this far
	STA pb_flag				; *** label from player.s ***
	CLI
; keep scrolling
	LDA #2
lock:
		TAX
		JSR diagonal
		TXA
		ASL
	BCC lock
		ROL
	BRA lock

; **************************
; *** interrupt handlers ***
; **************************
isr:
	PHA
	PHX
	PHY
	JSR psg_isr
	PLY
	PLX
	PLA
nmi:
	RTI

; *******************
; *** music score ***
; *******************

	.dsb	$E000-*, $FF
music:
; ch1 notes
	.byt	 12,  12,  12,  24,  24,   0,   0

	.dsb	$E100-*, $FF
; ch1 lengths [0=end]
	.byt	250, 250, 250, 250, 250, 250,   0

	.dsb	$E200-*, $FF
; ch1 volume
	.byt	 15,  15,  15,  15,  15,   0,   0

	.dsb	$E300-*, $FF
; ch1 envelope
	.byt	  1,   0, 255,   0, 255,   0,   0


	.dsb	$E000-*, $FF
; ch2 notes
	.byt	  0,  16,  16,  16,  36,  36,  36,   0

	.dsb	$E100-*, $FF
; ch2 lengths [0=end]
	.byt	125, 250, 125, 250, 250, 250, 250,   0

	.dsb	$E200-*, $FF
; ch2 volume
	.byt	  0,  15,  15,  15,  15,  15,   0,   0

	.dsb	$E300-*, $FF
; ch2 envelope
	.byt	  0,   1,   0, 255,   1, 255,   0,   0


	.dsb	$E000-*, $FF
; ch3 notes
	.byt	  0,  19,  19,  48,  48,   0,   0

	.dsb	$E100-*, $FF
; ch3 lengths [0=end]
	.byt	250, 250, 250, 250, 250, 250,   0

	.dsb	$E200-*, $FF
; ch3 volume
	.byt	  0,  15,  15,  15,  15,   0,   0

	.dsb	$E300-*, $FF
; ch3 envelope
	.byt	  0,   1, 255,   1, 255,   0,   0

; ***************
; *** ROM end ***
; ***************

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)

	.dsb	$FFFA-*, $FF
	.word	nmi
	.word	reset
	.word	isr
