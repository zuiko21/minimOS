; Delay test for Durango-X (HIRES mode)
; (c) 2022 Carlos J. Santisteban
; last modified 20221126-1911

; *** some global definitions ***
IO8flags	= $DF80

; *** zeropage variables ***
.zero
*	= $80					; was uz

pt			.word	0		; screen pointer
tmp			.byt	0		; temporary usage

; *** test code ***
.text
#ifndef	MULTIBOOT
*	= $FF00					; ROMmable
#endif

start:
; standard 6502 stuff
	SEI
	CLD
	LDX #$FF
	TXS
; minimal hardware init
	STX $DFA0				; turn LED off
	LDA #$B0				; HIRES mode, true video, screen 3
	STA IO8flags			; set hardware mode register
; init variables
	LDX #$60				; screen 3 address
	LDY #0
	TYA						; initial value is 0
	STY pt					; set pointer
; clear screen, just in case
cl_p:
		STX pt+1
clear:
			STA (pt), Y
			INY
			BNE clear
		INX
		BPL cl_p
; draw vertical limits
	LDX #31					; 32 bytes per line
	LDA #$FF				; all white
; some fix bytes
	STA $6200				; left border test
	STA $641F				; right border test
	STA $6800				; enable test
	STA $7B00				; left border test, down
	STA $7D1F				; right border test, down
hloop:
		STA $6000, X		; top raster
		STA $7FE0, X		; bottom raster
		DEX
		BPL hloop
; add serrations in between
; left side
	LDX #6					; 7 bytes per corner
ls_loop:
		ASL					; remove rightmost bit
		LDY tl_off, X		; get offset to top left
		STA $6000, Y		; all within a page
		STA $641F, Y		; same pattern for right border test
		STA $7D1F, Y
		STA $6800, Y		; enable test
		LDY bl_off, X		; bottom left offset
		STA $7F00, Y
		DEX
		BPL ls_loop
; right side
	TXA						; actually $FF eeeeeeeek
	LDX #6					; 7 bytes per corner
rs_loop:
		LSR					; remove leftmost bit
		LDY tl_off, X		; get offset to top left
		STA $601F, Y		; all within a page, note offset
		STA $6200, Y		; left border test
		STA $7B00, Y
		LDY bl_off, X		; bottom left offset
		STA $7F1F, Y
		DEX
		BPL rs_loop
; disable test
	LDX #7					; max offset from table
	STX tmp
ramp:
		LDX tmp
		LDA bl_off, X		; get offset
		CLC
		ADC tmp				; every line advances one byte
		TAY					; set start
		LDA #16
		SEC
		SBC tmp
		TAX
		LDA #$FF
toend:
			STA $7810, Y	; store this byte...
			INY
			DEX				; until some fixed column
			BNE toend
		DEC tmp				; next raster
		BPL ramp
; some lateral marks
	LDX #7
side:
		LDA #128			; left pixel
		LDY bl_off, X
		STA $6D00, Y
		LDA #1				; right pixel
		STA $721F, Y
		DEX
		BPL side
; pixel rendering test
	LDX #0
pixels:
		LDA #$55
		STA $6F00, X
		LDA #$AA
		STA $7000, X
		INX
		BNE pixels
lock:
	BEQ lock				; NMOS savvy

; *** tables ***
tl_off:						; offset to top left, add 31 for right
	.byt	224, 192, 160, 128, 96, 64, 32

bl_off:						; bottom left offset, add 31 for right
	.byt	0, 32, 64, 96, 128, 160, 192, 224

end_tables:

#ifndef	MULTIBOOT
	.dsb	$FFFA-*, $FF	; ROM padding
	.word	start
	.word	start
	.word	start
#endif
