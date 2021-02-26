; music player for breadboard!
; (c) 2021 Carlos J. Santisteban
; last modified 20210226-1833

; *** required variables (not necessarily in ZP) ***

	.zero

	* = 3					; minimOS-savvy ZP address

cur		.byt	0			; current score position

	.text

; *** player code ***

	* = $400				; downloadable version

	SEI						; standard init
	CLD
	LDX #$FF
	TXS

	INX						; now it's zero
	STX cur					; reset cursor (or use STZ)
loop:
		LDY cur				; get index
		LDA len, Y			; get length from duration array
		TAX
			BEQ end			; length=0 means END of score
		LDA note, Y			; get note period (10A+20 t) from its array
		BEQ rest			; no sound!

; *****************************
; *** ** beeping routine ** *** inlined
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
; *****************************
mt_beep:
			TAY				; determines frequency (2)
			STX $BFF0		; send X's LSB to beeper (4)
rb_zi:
				DEY			; count pulse length (y*2)
				BNE rb_zi	; stay this way for a while (y*3-1)
			DEX				; toggles even/odd number (2)
			BNE mt_beep		; new half cycle (3)
		STX $BFF0			; turn off the beeper!
; *****************************

		BEQ next			; go for next note

; **************************
; *** ** rest routine ** *** inlined
; ***     X = length     ***
; ***    t = X 1.28 ms   ***
; **************************
rest:
	TAY						; if period is zero for rests, this resets the counter
r_loop:
			INY
			BNE r_loop		; this will take ~ 1.28 ms
		DEX					; continue
		BNE rest
; **************************

next:
		INC cur				; advance cursor to next note
		BNE loop
end:
	BEQ end					; *** locks at the end ***

; *******************
; *** music score ***
; *******************
; PacMan theme for testing

; array of lengths (rests are computed like G5)
len:
	.byt	35, 52, 70, 52, 52, 52, 44, 52, 70, 52, 104, 88, 104
	.byt	35, 52, 70, 52, 52, 52, 44, 52, 70, 52, 104, 88, 104
	.byt	35, 52, 70, 52, 52, 52, 44, 52, 70, 52, 104, 88, 104
	.byt	41, 44, 46, 52, 46, 49, 52, 52, 52, 55, 58, 52, 140, 104, 0	; *** end of score ***

; array of notes (rests are 0)
note:
	.byt	190, 0, 94, 0, 126, 0, 150, 0, 94, 126, 0, 150, 0
	.byt	179, 0, 88, 0, 118, 0, 141, 0, 179, 118, 0, 141, 0
	.byt	190, 0, 94, 0, 126, 0, 150, 0, 94, 126, 0, 150, 0
	.byt	159, 150, 141, 0, 141, 133, 126, 0, 126, 112, 94, 0			; no need for extra byte as will be discarded
