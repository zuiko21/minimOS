; Durango-X Minstrel-style keyboard test
; (c) 2022 Carlos J. Santisteban, based on work from Emilio López Berenguer
; last modified 20221126-2101

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
	LDY #3					; max. row offset EEEEEEK
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
; draw 2x2 square at (row,col) in red (not pressed) or cyan (pressed)
	LDA row
	CLC
	ADC #$70				; page of first raster used for keys
	STA ptr+1
	LDA col
	ASL						; times two (0...18), C is clear
	ADC #$D					; rightmost key is at offset $1F = $12 + $D
	STA ptr					; pointer to top byte, bottom one is +$40
	JSR readkey				; check whether selected key is pressed (C) or not
	LDA #$22				; red (free)
	BCC no_key
		LDA #$DD			; cyan (pressed)
no_key:
	LDY #0
	STA (ptr), Y			; CMOS savvy!
	LDY #$40
	STA (ptr), Y
	RTS

readkey:
;	LDA #2
;	CMP row
;	BNE free
;	LDA #6
;	CMP col
;	BNE free
	LDX col					; check keyboard column
	LDA km_col, X			; convert to matrix column
	AND #$7F				; remove last bit!
	STA $DF9B				; select column
	LDA $DF9B				; and get row pattern
	LDY row					; check keyboard row
;	BIT km_col, X			; check whether left (plus) or right (minus) half of the row, CMOS only!
	LDA km_col, X			; check whether left (plus) or right (minus) half of the row, NMOS-savvy
	BMI right
		LDA $DF9B			; retrieve pattern for NMOS!
		AND l_row, Y		; and filter from (left) matrix index
		JMP k_chk
right:
	LDA $DF9B				; retrieve pattern for NMOS!
	AND r_row, Y			; and filter from (right) matrix index
k_chk:
	BEQ free				; mostly not pressed, or...
		SEC					; that key was pressed
		BCS c_set
free:
	CLC						; otherwise is free
c_set:
	RTS

; keyboard-to-matrix conversion
km_col:
	.byt	%00000001, %00000010, %00000100, %00001000, %00010000, %10010000, %10001000, %10000100, %10000010, %10000001
l_row:
	.byt	128,	64,		16,		4
r_row:
	.byt	32,		8,		2,		1

#ifndef	MULTIBOOT
nmi:
irq:
	RTI						; standalone ROM disables all interrupts

	.dsb	$FFFA - *, $FF	; ROM padding

	.word	nmi
	.word	reset
	.word	irq
#endif
