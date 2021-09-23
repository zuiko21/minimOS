; test of hires Durango-X font
; (c) 2021 Carlos J. Santisteban 

	* =	$400

ptr = 0
org = 2

	LDA #$80
	STA $8000				; set hires (later $DF80) 
	STA $DF80				; new address 
	LDY #0
	STY ptr
	STY org
	LDX #$60				; screen start
	STX ptr+1
	LDX #$5					; font start
	STX org+1
	LDX #0					; ascii counter
loop:
			LDA (org), Y
			STA (ptr)
			LDA ptr
			CLC
			ADC #32			; should set NO carry
			STA ptr
			INY
			CPY #8
			BNE loop
		LDA org				; next char in font
		CLC
		ADC #8
		STA org
		LDY #0				; eeek
		INC ptr				; next char on screen (LSB was rest as 32x8)
		INX					; one more printed char
		TXA
		AND #31				; line feed?
		BNE loop
	STZ ptr
	INC org+1
	INC ptr+1
	BPL loop

	LDA #$80				; keep hires mode...
lock:
; inverse bars 
	STA $8000				; set flags
	STA $DF80				; set flags (new address)
	LDX #3					; originally 4, compensate if using both old and new addresses
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	EOR #64					; toggle inverse mode
	JMP lock

	.dsb	$500-*, $FF
* = $500

#include "../../OS/drivers/fonts/8x8.s"


