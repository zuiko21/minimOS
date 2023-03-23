; Durango-X colour test pattern generator
; (c) 2023 Carlos J. Santisteban

* = $FE00					; single sector!
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Colour bars", 0	; C-string with filename @ [8], max 238 chars
;	.asc	"(comment)"		; optional C-string with comment after filename, filename+comment up to 238 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $F8 - *, $FF

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5800			; time, 11.00
	.word	$5673			; date, 2023/3/19
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number
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
	.dsb	$FFE1-*, $FF	; devCArt support
	JMP ($FFFC)

	.dsb	$FFFA-*, $FF	; ROM padding (6502)

	.word	reset			; NMI does restart
	.word	reset			; RESET vector
	.word	irq				; IRQ/BRK do nothing
