; test code for picoVDU in Tommy2 computer
; IO-channel 8 connection
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20210427-1722

	* = $400				; standard download address

; constants
	io_lh =	$8000
	io_ll =	$8001
	io_wr =	$8002			; ***
	ltc_o =	$FFF0
; first block %11110000
	LDX #0
	STX ltc_o				; turn LED off
	STX io_lh
	LDY #0
top:
		STY io_ll
		TYA
		AND #24
		CMP #24
		BEQ skip
		LDA #0
skip:	STA io_wr
		INY
		BNE top
	INX
	STX io_lh
	CPX #8	;4
	BNE top
	JMP end
; ***
; bottom half is %00001111
	LDA #%00001111
bot:
		STY io_ll
		STX io_wr;
		INY
		BNE bot
	INX
	STX io_lh
	CPX #8
	BNE bot
; all done, show some feedback on LED
end:
	LDA #%11101001			; dot & slash (or the opposite)
	STA ltc_o
	JMP *					; lock here
