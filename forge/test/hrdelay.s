; Delay test for Durango-X (HIRES mode)
; (c) 2022 Carlos J. Santisteban
; last modified 20221126-1444

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
*	= $400					; safe download address
#endif

; standard 6502 stuff
	SEI
	CLD
	LDX #$FF
	TXS
; minimal hardware init
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
hloop:
		STA $6000, X		; top raster
		STA $7FE0, X		; bottom raster
		DEX
		BPL hloop
; add serrations in between
; left side
	LDX #7					; 7 bytes per corner
ls_loop:
		ASL					; remove rightmost bit
		LDY tl_off, X		; get offset to top left
		STA $6000, Y		; all within a page
		LDY bl_off, X		; bottom left offset
		STA $7F00, Y
		DEX
		BPL ls_loop
; right side
	LDX #7					; 7 bytes per corner
rs_loop:
		LSR					; remove leftmost bit
		LDY tl_off, X		; get offset to top left
		STA $601F, Y		; all within a page, note offset
		LDY bl_off, X		; bottom left offset
		STA $7F1F, Y
		DEX
		BPL rs_loop
/*
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
			BCS rskip
				INY			; skip three then
				INY
rskip:
			DEX
			BNE rwide
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
		LDY #0				; eeeeek
		LDA colour
		SEC
		SBC #$10			; eeeeeeek, it's MSN
		STA colour
		BNE loop			; continue (black is not used)
*/

lock:
	BEQ lock

; *** tables ***
tl_off:						; offset to top left, add 31 for right
	.byt	224, 192, 160, 128, 96, 64, 32

bl_off:						; bottom left offset, add 31 for right
	.byt	0, 32, 64, 96, 128, 160, 192
