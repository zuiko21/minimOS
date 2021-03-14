; Pi-day demo
; for DURANGO 65c02 computer
; (c) 2021 Carlos J. Santisteban
; last modified 20210314-1504

; ZP use
	.zero

	* =	3					; minimOS savvy

org		.word	0

; some constants

	io8lh = $8000
	io8ll = $8001
	io8wr = $8003
	iob_d = $BFFF
	ltc_o = $FFF0

; actual code
	.text

	* =	$400

	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS

; transfer image data to IO-screen
	LDY #<img				; set pointers for copy
	LDA #>img
	STY org
	STA org+1
	LDY #0					; IO-based screen origin, Y=LSB, X=MSB
	LDX #0
	STX io8lh				; set first page!
loop:
			LDA (org), Y	; get image data
			STY io8ll		; set pointer...
			STA io8wr		; ...and poke value
			INY
			BNE loop
		INC org+1			; page crossing
		INX
		STX io8lh			; eeeeeek
		CPX #8				; check screen end
		BNE loop

; beep for some time!
	LDX #0
rpt:
		STX iob_d
b_loop:
			INY
			BNE b_loop
		DEX
		BNE rpt
	STA iob_d

; display 'Pi' on LTC-4622
lock:
	LDA #%00110010
	STA ltc_o
	LDA #%10000001
	STA ltc_o
	LDA #%11111000
	STA ltc_o
	LDA #%10110100
	STA ltc_o
	BNE lock

; *** data section ***
img:
	.bin	56, 2048, "../../other/data/pi.pbm"
