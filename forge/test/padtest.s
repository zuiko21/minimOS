; Durango-X gamepad test
; (c) 2022 Carlos J. Santisteban, based on work from Emilio López Berenguer
; last modified 20221127-1035

#ifndef	MULTIBOOT
	*	= $F000
#endif

; *** zeropage definitions ***
	ptr		= $80			; indirect pointer
	gm1		= $82			; pad masks
	gm2		= $83
	tmp		= $84			; temporary pad value
	n_pad	= $85			; selected pad (0=pad 2, 8=pad 1) 

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
; load pads image *** TBD

; scan buttons and fill with appropriate colour
main:
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
