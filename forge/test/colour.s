; Durango-X colour test pattern generator
; (c) 2023 Carlos J. Santisteban

* = $C000					; 16K ROM
	.dsb	$FF00-*, $FF	; filler for 256-byte code

	ptr	= $80				; ZP vector

reset:
	SEI
	CLD						; usual 6502 stuff, but won't bother with stack
	LDA #$38				; colour RGB mode, screen 3 as usual
	STA $DF80				; set video mode

	LDX #$60				; screen 3 start
	LDY #0
	STY ptr
	STX ptr+1				; set pointer
r_loop:
		LDX #7				; colour table index
c_loop:
			LDA table, X	; get index
			LDY #7			; bar width offset
b_loop:
				STA (ptr), Y
				DEY
				BPL b_loop	; complete bar raster
			LDA ptr
			CLC
			ADC #8			; next bar
			STA ptr
			BCC same_page
				INC ptr+1
same_page:
			DEX
			BPL c_loop		; try next colour
		LDA ptr+1			; already at next raster, check bounds
		BPL r_loop
; test pattern is generated, now do some LED flashing
lock:
			INX
			BNE lock
		INY
		BNE lock			; typical ~0.2 seconds delay
	INC						; toggle...
	STA $DFA0				; ...interrupt status, thus error LED
	JMP lock

; *** colour table ***
table:
	.byt	0, $88, $22, $AA, $55, $DD, $77, $FF

irq:
	RTI						; IRQ (if happens!) and BRK do nothing

; *** end of ROM ***
	.dsb	$FFD6-*, $FF	; ROM padding (minimOS)
	.asc	"DmOS"			; standard signature

	.dsb	$FFFA-*, $FF	; ROM padding (6502)

	.word	reset			; NMI does restart
	.word	reset			; RESET vector
	.word	irq				; IRQ/BRK do nothing
