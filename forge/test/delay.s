; Delay test for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220518-1311

;#include "../../macros.h"
;#include "../../zeropage.h"

; *** some global definitions ***
IO8flags	= $DF80

; *** zeropage variables ***
.zero
*	= $80					; was uz

pt			.word	0		; screen pointer
colour		.byt	0		; ink colour

; *** test code ***
.text
*	= $400					; safe download address

; minimal hardware init
	LDA #$38				; colour mode, true video, screen 3, RGB enabled
	STA IO8flags			; set hardware mode register
; init variables
	LDX #$60				; screen 3 address
	LDY #0
	STY pt					; set pointer
	STX pt+1
	TYA						; initial value is 0
; clear screen, just in case
clear:
		STA (pt), Y
		INY
		BNE clear
			INC pt+1
		BPL clear
	LDX #$60				; restore pointer
	STX pt+1
; finish init
	LDA #%11110000			; white at MSB
	STA colour				; preset first ink colour
; pattern loop
loop:
		LDA colour			; left pixel colour
		LDX #6				; six wide patterns... (2+4)
lwide:
			STA (pt), Y		; set this pattern
			INY				; leave one or three blank bytes
			INY
			CPX #5			; within first half?
			BCC lskip
				INY			; skip three then
				INY
lskip:
			DEX
			BNE lwide
tight:
			STA (pt), Y		; set all bytes this way
			INY
			INX				; this counter was reset, now goes up
			CPX #16			; middle of the pattern?
			BNE top_t
				LSR			; if so, shift to right pixel
				LSR
				LSR
				LSR
top_t:
			CPX #32			; end of tight pattern?
			BNE tight
		LDX #6				; six wide patterns again
rwide:
			STA (pt), Y		; set this pattern
			INY				; leave one or three blank bytes
			INY
			CPX #3			; within last half?
			BCS lskip
				INY			; skip three then
				INY
lskip:
			DEX
			BNE lwide
		TYA					; check offset
		BNE loop
		INC pt+1			; next page is big chunks
; enable delay test
		LDA colour			; get MSN
		LSR					; turn into LSN
		LSR
		LSR
		LSR
		ORA colour			; both pixels
		LDY #31				; half line
lhalf:
			STA (pt), Y
			DEY
			BPL lhalf
		LDY #64				; next raster to the left
		STA (pt), Y
		LDY #160			; right half, third raster
rhalf:
			STA (pt), Y
			INY
			CPY #192		; until end of raster
			BNE rhalf
		LDY #224			; middle of last raster
		STA (pt), Y
		INY
		STA (pt), Y			; two bytes
; change colour and advance page
		INC pt+1
		LDA colour
		SEC
		SBC #$10			; eeeeeeek, it's MSN
		STA colour
		BNE loop			; continue (black is not used)
lock:
	BEQ lock
