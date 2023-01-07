; dithered picture test for Durango-X
; (c) 2023 Carlos J. Santisteban


; *** definitions ***
IO8attr	= $DF80
IO8blnk	= $DF88
IO9kbd	= $DF9B
IOAie	= $DFA0

; *** RAM usage ***
ptr		= $C0
src		= ptr+2


; *** code ***
	*	= $8000				; needs whole 32K because of 24K worth of pictures!

reset:
	SEI
	CLD
	LDX #$FF
	TXS						; usual 6502 stuff
	STX IOAie				; enable Durango-X interrupts; not used but turns LED off
	LDA #$08				; RGB mode, note screen 0!
	STA IO8attr				; set video mode
; clear available screen for intro
	LDX #$02				; safe page
	LDY #0
	LDA #$22				; red screen!
	STY ptr
pg_clear:
		STX ptr+1
loop_clear:
			STA (ptr), Y
			INY
			BNE loop_clear
		INX
		CPX #$20			; first page of screen 1
		BNE pg_clear
; in the meanwhile, copy ROM pictures into RAM
	LDA #<rom_pics
	STA src
	LDA #>rom_pics
	STA src+1				; pointers are set
pg_copy:
		STX ptr+1
loop_copy:
			LDA (src), Y
			STA (ptr), Y
			INY
			BNE loop_copy
		INC src+1
		INX
		BPL pg_copy			; negative is the end of screen 3
; display dots waiting for a key press...
	LDA #$82				; left pixel will become blue
	STA $101F
	STA $1020
	STA $1021
; wait for any keypress
wait_key:
		LDA #16				; fifth column
sel_col:
			STA IO9kbd		; select column
			LDX IO9kbd		; and get any rows pressed
		BNE cycle			; start animation!
			LSR				; previous column
		BCC sel_col
	BCS wait_key			; check forever
; go for it!
cycle:
	LDA #$18				; screen 1, RGB mode
frame:
		STA IO8attr
exit_blank:
			BIT IO8blnk
			BVS exit_blank
wait_blank:
			BIT IO8blnk
			BVC wait_blank
; advance to next screen
		CLC
		ADC #$10
		CMP #$40
		BCC frame
	BCS cycle				; start again, forever
_end_code:

; *** images ***
rom_pics:
	.bin	0, 0, "../../other/data/dl1.sv"
	.bin	0, 0, "../../other/data/dl2.sv"
	.bin	0, 0, "../../other/data/dl3.sv"

; *** end of ROM stuff ***
	.dsb	$FFD6-*, $FF	; filler

	.asc	"DmOS"			; standard sigature
	.dsb	$FFF9-*, $FF	; one byte before vectors
null:
	RTI						; null interrupt handler, just in case

	.word	reset			; NMI like reset
	.word	reset
	.word	null			; IRQ/BRK do nothing

