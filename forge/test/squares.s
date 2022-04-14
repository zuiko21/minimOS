; Squares demo for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220413-1423

#include "../../macros.h"
#include "../../zeropage.h"

; *** some global definitions ***
fw_hires	= $DF80

; *** zeropage variables ***
.zero
*	= uz

cio_pt		.word	0		; (screen pointer), 3
min			.byt	0		; lower coordinate limit, 5
max			.byt	0		; first coordinate over limit, 6
colour		.byt	0		; value to be POKEd, 7
lmin		.word	0		; initial line address for convenience, 8
lines		.byt	0		; numer of lines for convenience, 10

; *** test code ***
.text
*	= $400					; safe download address

; minimal hardware init
	LDA #$38				; colour mode, true video, screen 3, RGB enabled
	STA fw_hires			; set hardware mode register
; variable setting
reset:
	LDY #0					; first colour is black
	STY colour
; main loop
cycle:
	LDA #31					; lowest byte on line
	STA min
	LDA #33					; will affect bytes 31 & 32
	STA max
	LDA #$6F				; screen 3 base address MSB *PLUS* 2 lines above centre
	STA lmin+1				; base MSB
	LDA #$80				; ditto for LSB, will be subtracting $80 each cycle (2 lines)
	STA lmin				; full pointer ready
	LDA #4					; initial number of lines
	STA lines
square:
		LDY lmin			; get current address
		LDA lmin+1
		STY cio_pt			; set pointer
		STA cio_pt+1
		LDX lines			; get desired number of lines
line:
			LDY min			; get base offset
			LDA colour
pokes:
				STA (cio_pt), Y
				INY
				CPY max
				BNE pokes	; until end of line
			LDA cio_pt
			CLC
			ADC #64			; bytes per line
			STA cio_pt
			BCC next
				INC cio_pt+1	; check MSB
next:
			DEX				; one line less to do
			BNE line
; the desired square is drawn, now restart with a bigger one
		DEC min
		BMI repeat			; if min<0, change colour
			INC max			; next square is wider
			INC lines
			INC lines		; two more lines
; initial address is previous minus $80 (two more lines), LSB is either 0 or $80
			LDA lmin
			EOR #$80
			STA lmin
			BEQ square		; went zero, MSB stays
				DEC lmin+1
			BNE square		; always
repeat:
		LDA colour
		CLC
		ADC #$11			; next colour on both pixels
		STA colour
		BCC cycle
	BCS reset				; or start again with black
