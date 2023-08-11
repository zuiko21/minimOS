; testing 65C816 board for Durango-X
; (c) 2023 Carlos J. Santisteban

; *** common ***
ptr		= 0
src		= ptr+3				; note extra padding
dest	= src+3

; *** *** ROM contents *** ***
	* = $8000

picture:
	.bin	0, 0, "../../other/data/elvira.sv"
b6502:
b65816:

	.dsb	$FE00-*, $FF	; padding

; *** *** ROM code *** ***

; usual init
reset:
	SEI
	CLD
	LDX #$FF
	TXS
; Durango stuff
	STX $DFA0				; turn LED off
	LDA #$38
	STA $DF80				; colour mode

; *** main loop ***
; 6502 code
t6502:
	SEC
;	XCE						; make sure it's in emulation mode!
	NOP
	NOP						; extra safety
	LDX #$60				; screen address
	LDY #$0
	TYA						; will clear screen
	STY ptr
clr_p:
		STX ptr+1			; select page
clr_l:
			STA (ptr), Y	; clear byte
			INY
			BNE clr_l
		INX
		BPL clr_p
; draw 6502 banner (TBD)

	JSR delay
; scroll up picture
	LDX #$7F				; last page on screen
	STX dest				; temporary use
up02:
		LDA #>picture		; set origin pointer
		LDY #<picture		; MUST be zero!
		STA src+1
		STY src
		STY ptr
page02:
			STX ptr+1		; current destination pointer
loop02:
				LDA (src), Y
				STA (ptr), Y			; copy byte into selected location
				INY
				BNE loop02
			INC src+1		; next page
			INX
			BPL page02		; ouside screen?
		DEC dest			; will start one page upwards
		LDX dest
		CPX #$60			; already over screen top?
		BCS up02			; if not, redraw
; side scroll
	LDA #64					; set counter
	STA dest
sh02:
	LDX #$60
	LDY #1
	STY src					; source is one byte ahead
	DEY
	STY ptr
sp02:
		STX src+1
		STX ptr+1
sr02:
		LDY #0				; eeek
sl02:
			LDA (src), Y
			STA (ptr), Y
			INY				; fill raster
			CPY #63
			BNE sl02
		LDA src
		CLC
		ADC #64				; next raster
		STA src
		DEC					; destination is one byte before
		STA ptr
		BNE sr02			; still within same page?
			INX
		BPL sp02			; otherwise advance until end of screen
	DEC dest				; next iteration
	BNE sh02

; 65816 code
t65816:
	CLC
;	XCE						; make sure it's in NATIVE mode!
	.al						; 16-bit memory
;	REP #$20;*********CHECK
	LDX #$60				; screen address
	LDY #$0
	TYA						; will clear screen
	STY ptr
cw_p:
		STX ptr+1			; select page
cw_l:
			STA (ptr), Y	; clear word
			INY
			INY				; 16-bit mode!
			BNE cw_l
		INX
		BPL cw_p
; draw 65816 banner (TBD)

	JSR delay
; scroll up picture
	LDX #$7F				; last page on screen
	STX dest				; temporary use
up816:
		LDA #picture		; set origin pointer
		STA src
		LDY #0
		STY ptr
page816:
			STX ptr+1		; current destination pointer
loop816:
				LDA (src), Y
				STA (ptr), Y			; copy byte into selected location
				INY
				INY
				BNE loop816
			INC src+1		; next page
			INX
			BPL page816		; ouside screen?
		DEC dest			; will start one page upwards
		LDX dest
		CPX #$60			; already over screen top?
		BCS up816			; if not, redraw
; side scroll
	LDA #64					; set counter (16-bit to avoid mode change)
	STA dest
sh816:
	LDX #$60
	LDY #1
	STY src					; source is one byte ahead
	DEY
	STY ptr
sp816:
		STX src+1
		STX ptr+1
sr816:
		LDY #0				; eeek
sl816:
			LDA (src), Y
			STA (ptr), Y
			INY				; fill raster
			INY
			CPY #62
			BNE sl816
		LDA src				; not worth switching modes...
		CLC
		ADC #64				; next raster
		STA src
		DEC					; destination is one byte before
		STA ptr
		AND #$0F
		BNE sr816
			INX
		BPL sp816			; otherwise advance until end of screen
	DEC dest				; next iteration
	BNE sh816
	.as
;	SEP #$20;********CHECK

	JMP t6502

; *** delay routine ***
delay:
	LDA #10
d_loop:
				INX
				BNE d_loop
			INY
			BNE d_loop
		DEC
		BNE d_loop
	RTS

; *** void interrupt handler ***
dummy:
	RTI

; ***************
; *** ROM end ***
	.dsb	$FFE1-*, $FF	; usual padding
	
	JMP ($FFFC)				; devCart support
; 65816 vectors

; 6502 vectors
	.dsb	$FFFA-*, $FF

	.word	dummy
	.word	reset
	.word	dummy
