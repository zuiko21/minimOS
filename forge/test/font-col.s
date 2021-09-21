; test of hires Durango-X font
; (c) 2021 Carlos J. Santisteban 

	* =	$400

ptr = 0
org = 2
io8flags = $8000			; later $DF80

	LDY #0
	STY io8flags			; set colour mode 
	STY ptr
	STY org
	LDX #$60				; screen start
	STX ptr+1
	LDX #$5					; font start
	STX org+1
	LDX #0					; ascii counter
loop:
			LDA (org), Y
; convert read pattern into several screen bytes
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

	LDA #0					; keep colour mode...
lock:
; inverse bars 
	STA io8flags			; set flags
	LDX #4
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	CLC
	ADC #64					; toggle inverse mode... and 
	JMP lock

	.dsb	$500-*, $FF
* = $500

#include "../../OS/drivers/fonts/8x8.s"


