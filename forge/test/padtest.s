; Durango-X gamepad test
; (c) 2022 Carlos J. Santisteban, based on work from Emilio López Berenguer
; last modified 20221127-2147

#ifndef	MULTIBOOT
	*	= $F000
#endif

; *** zeropage definitions ***
	ptr		= $80			; indirect pointer
	gm1		= $82			; pad masks
	gm2		= $83
	tmp		= $84			; temporary pad value
	n_pad	= $85			; selected pad (0=pad 2, 8=pad 1) 
	src		= tmp			; temporary source pointer

; *** test code ***
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
; before anything else, get proper controller mask
	JSR readpad
	LDA $DF9C				; pad 1 value
	STA gm1					; is mask
	LDA $DF9D				; ditto for pad 2
	STA gm2
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
; load pad images
	LDX #>image_p			; pink controller goes top
	LDY #<image_p
	STY src
	STX src+1
	LDX #$62				; top pad position
	LDY #$20
	STY ptr
	STX ptr+1				; update pointer
	JSR drawpad
	LDX #>image_b			; blue controller goes bottom
	LDY #<image_b
	STY src
	STX src+1
	LDX #$6A				; bottom pad position
	LDY #$20
	STY ptr
	STX ptr+1				; update pointer
	JSR drawpad

; scan buttons and fill with appropriate colour
main:
		JSR readpad			; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK!
		LDA $DF9C			; pad 1
		EOR gm1				; adapt it!
		STA tmp
		LDA #8				; pad 1 select
		STA n_pad
		JSR update_pad
		LDA $DF9D			; pad 2
		EOR gm2				; adapt it!
		STA tmp
		LDA #0				; pad 2 select, NMOS savvy
		STA n_pad
		JSR update_pad
		JMP main

; *** ************* routines ************* ***
; *** take read value and draw it in place ***
update_pad:
	LDX #7					; highest offset
p_loop:
; compute address here
		LDY butl, X			; get button address
		LDA buth, X
		STY ptr
		CLC
		ADC n_pad			; switch pad position (0 is for pad2)
		STA ptr+1
; check for button
		ASL tmp				; shift leftmost bit
		BCC free			; not pressed
			LDA #$22		; red if pressed
			BNE pressed
free:
		LDA #0				; black if released
pressed:
; fill button space with selected colour
		LDY #0
		STA (ptr), Y		; top byte
		LDY #$40			; one raster below
		STA (ptr), Y		; bottom byte
		DEX
		BPL p_loop			; go for next button
	RTS

; *** read pad values into interface (without mask) ***
readpad:
	STA $DF9C				; send LATCH signal
	LDX #8					; NES pads have 8 bits to be shifted
pad_l:
		STA $DF9D			; send clock pulse
		DEX
		BNE pad_l
	RTS						; $DF9C and $DF9D hold the raw pad values

; *** copy 42x17 image ***
drawpad:
	LDX #17					; actually number of rasters
dr_p:
		LDY #20				; last byte offset (for 42 pixel)
dr_b:
			LDA (src), Y
			STA (ptr), Y
			DEY
			BPL dr_b
		LDA src
		CLC
		ADC #21				; add byte count to source pointer
		STA src
		BCC dr_now
			INC src+1
dr_now:
		LDA ptr
		CLC
		ADC #$40			; next raster
		STA ptr
		BCC dr_rst
			INC ptr+1		; next page
dr_rst:
		DEX
		BNE dr_p
	RTS

; ******************************
; *** button addresses table *** based on pad 2 (upper)
; ---- keys ----
; A      -> #$80 (X=7)
; START  -> #$40
; B      -> #$20
; SELECT -> #$10
; UP     -> #$08
; LEFT   -> #$04
; DOWN   -> #$02
; RIGHT  -> #$01 (X=0)
; --------------
butl:
	.byt	$24, $A3, $22, $A3, $A7, $AD, $A9, $B1
buth:
	.byt	$64, $64, $64, $63, $64, $64, $64, $64

image_b:
	.bin	0, 0, "../../other/data/nesblue.42x17"
image_p:
	.bin	0, 0, "../../other/data/nespink.42x17"
end:

; *********************************
; *** stuff for standalone test ***
#ifndef	MULTIBOOT
nmi:
irq:
	RTI						; standalone ROM disables all interrupts

	.dsb	$FFFA - *, $FF	; ROM padding

	.word	nmi
	.word	reset
	.word	irq
#endif
