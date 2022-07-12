; pixel routine demo for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220713-0029

; *** zeropage definitions ***
	fw_ccol	= 3				; PAPERs setting
	fw_ink	= 6				; thus, INKs are here (+3)
	cio_pt	= 4				; screen pointer between PAPER and INK (.w)
	fw_mask = 7				; PLOT/UNPLOT mode
	fw_cbyt = 8				; temporary
	ptr		= 9
	posx	= 10			; extras
	posy	= 11

	* = $400				; usual download address

; *** test code ***
	LDA #$38				; standard colour mode
	STA IO8attr
	LDX #$77				; yellow ink
	STX fw_ink
	LDA #$88				; blue paper 
	STA fw_ccol
	LDY #0					; plot mode, and reset pointer
	STY fw_mask
	STY ptr
	STY posx
	STY posy
; clear screen
	LDX #$60
	STX cio_pt+1
	STY cio_pt				; already 0 for pointer
loop:
		STA (cio_pt), Y		; A already is paper code
		INY
		BNE loop
	INX
	STX cio_pt+1
	BPL loop
; fill the screen with pixels
do:
	LDX posx
	LDA $400,X
	STA fw_mask
	LDY posy
	JSR dxplot
	INC posx
	BPL do
		STZ posx
		INC posy
		BPL do
lock:
	BRA lock

#include "../../OS/firmware/modules/durango-plot.s"
