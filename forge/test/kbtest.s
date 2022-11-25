; Durango-X Minstrel-style keyboard test
; (c) 2022 Carlos J. Santisteban, based on work from Emilio López Berenguer
; last modified 20221125-1608

#ifndef	MULTIBOOT
	*	= $F000
#endif

	ptr	= $80				; indirect pointer
	row	= $82				; key coordinates
	col	= $83

reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X stuff
	STX $DFA0				; enable interrupt hardware, LED goes off
#ifndef	HIRES
	LDA #$38				; try colour mode
#else
	LDA #$B0				; alternative HIRES for testing
#endif
	STA $DF80
; clear screen
	LDX #$60				; screen start
	LDY #0
	TYA						; black background here
	STY ptr
cl_p:
		STX ptr+1			; update pointer
cl_b:
			STA (ptr), Y
			INY
			BNE cl_b
		INX					; next page within first half
		BPL cl_p
; loop redrawing 2x2 squares in red (not pressed) or cyan (pressed)
main:
	LDY #4					; max. row offset
	STY row
r_loop:
		LDX #9				; max. col offset
		STX col
loop:
			JSR keydraw
			DEC col
			BPL loop
		DEC row
		BPL r_loop
	BMI main				; forever

keydraw:
	LDA row
	CLC
	ADC #$70				; page of first raster used for keys
	STA ptr+1
	LDA col
	ASL						; times two (0...18), C is clear
	ADC #$D					; rightmost key is at offset $1F = $12 + $D
	STA ptr					; pointer to top byte, bottom one is +$40
; *****TEST
	LDA #2					; red
	STA (ptr)
	LDY #$40
	STA (ptr), Y
	RTS

#ifndef	MULTIBOOT
#endif

#ifndef	MULTIBOOT
#endif

#ifndef	MULTIBOOT
nmi:
irq:
	RTI						; standalone ROM disables all interrupts

	.dsb	$FFFA - *, $FF	; ROM padding

	.word	nmi
	.word	reset
	.word	irq
#endif
