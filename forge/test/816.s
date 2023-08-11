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

	.dsb	$FF00-*, $FF	; padding

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

lock:jmp lock

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
