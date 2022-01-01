; music player for breadboard!
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20210927-0004

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

	STX $FFF0				; turn off display, just in case
/*
; *** experimental code ***
	LDA #83
	LDX #0
	JSR mt_beep
	LDA #168
	LDX #128
	JSR mt_beep

; play one 2-note chord
	LDA #168				; note values
	LDY #83
	LDX #0
	JSR mt_double

; ...but it sounds like this
	LDA #253
	LDX #128
	JSR mt_beep

	JMP end
*/
; sweep for pacman eating ghost ** OK
	LDA #0
	STA cur
sweep:
		LDX #8
		JSR mt_beep
		DEC cur
		DEC cur
		DEC cur
		DEC cur
		LDA cur
		CMP #16
		BNE sweep

	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74

; pacman death
	LDA #99		; initial freq
	LDY #88		; top freq
	LDX #36		; length
	JSR squeak
	LDA #118
	LDY #105
	LDX #30
	JSR squeak
	LDA #132
	LDY #117
	LDX #27
	JSR squeak
	LDA #148
	LDY #132
	LDX #24
	JSR squeak
	LDA #176
	LDY #157
	LDX #20
	JSR squeak
; last two sweeps ** OK
	LDA #2
	STA cur+1	; iteration
d_rpt:
	LDA #255
	STA cur
send:
		LDX #10
		JSR mt_beep
		LDA cur
		SEC
		SBC #24
		STA cur
		CMP #15
		BCS send
	JSR ms74
; next iteration
	DEC cur+1
	BNE d_rpt

	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74

; munch dot
	LDA #179
	LDX #4
	JSR mt_beep
	JSR ms74
	JSR ms74
	JSR ms74
	LDA #179
	LDX #4
	JSR mt_beep
	JSR ms74
	JSR ms74
	JSR ms74
	LDA #179
	LDX #4
	JSR mt_beep
	JSR ms74
	JSR ms74
	JSR ms74
	LDA #179
	LDX #4
	JSR mt_beep

	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74
	JSR ms74

; ************************

	LDX #0					; now it's zero
	STX cur					; reset cursor (or use STZ)
loop:
		LDY cur				; get index
		LDA len, Y			; get length from duration array
			BEQ end			; length=0 means END of score
		TAX
		LDA note, Y			; get note period (10A+20 t) from its array
		BEQ rest			; if zero, no sound!

		JSR mt_beep			; call beep! (no longer inlined)

		BEQ next			; go for next note

; **************************
; *** ** rest routine ** *** inlined
; ***     X = length     ***
; ***    t = X 1.28 ms   ***
; **************************
rest:
		TAY					; if period is zero for rests, this resets the counter
r_loop:
			STY 0		; 1.536 MHz delay
			INY
			BNE r_loop		; this will take ~ 1.28 ms
		DEX					; continue
		BNE rest
; **************************

next:
		INC cur				; advance cursor to next note
		BNE loop
end:
	LDA #%01100101			; put dashes on display
	STA $FFF0
	BNE end					; *** repeats at the end ***

; support routines
; *****************************
; *** ** beeping routine ** *** no longer inlined
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
; *****************************
mt_beep:
		TAY				; determines frequency (2)
		STX $DFB0		; send X's LSB to beeper (4)
rb_zi:
			STY 0		; 1.536 MHz delay
			DEY			; count pulse length (y*2)
			BNE rb_zi	; stay this way for a while (y*3-1)
		DEX				; toggles even/odd number (2)
		BNE mt_beep		; new half cycle (3)
	STX $DFB0			; turn off the beeper!
	RTS
; *****************************

; ~74 ms delay
ms74:
	LDY #198
delay:
		INX
		BNE delay
		INY
		BNE delay
	RTS

; squeak, get higher then lower
; cur=current, cur+1=initial, cur+2=final, cur+3=length
squeak:
	STA cur+1
	STA cur		; and current
	STY cur+2
	STX cur+3
peak1:
		LDX cur+3
		JSR mt_beep
		DEC cur
		DEC cur
		DEC cur
		LDA cur
		CMP cur+2
		BCS peak1
peak:
		LDX cur+3
		JSR mt_beep
		INC cur
		INC cur
		INC cur
		LDA cur
		CMP cur+1
		BCC peak
	RTS

; *****************************
; *** ** 2-chord routine ** ***
; *** X = length (4n!!!)    ***
; *** A = per.1, Y = per.2  ***
; *** tcyc = 10 n + 20      ***
; *****************************
mt_double:
	STA cur				; temporary storage
	STY cur+1
mt_beep2:
; first note, 10n + 20
		LDY cur			; determines frequency (3)
		STX $DFB0		; send X's LSB to beeper (4)
rb_d1:
			DEY			; count pulse length (y*2)
			BNE rb_d1	; stay this way for a while (y*3-1)
		DEX				; toggles even/odd number (2)
		LDA 0			; ***eq***
		LDY cur			; determines frequency (3)
		STX $DFB0		; send X's LSB to beeper (4)
rb_u1:
			DEY			; count pulse length (y*2)
			BNE rb_u1	; stay this way for a while (y*3-1)
		DEX				; eEEEEEEEK
		LDA 0			; ***eq***
; second note
		LDY cur+1		; determines frequency (3)
		STX $DFB0		; send X's LSB to beeper (4)
rb_d2:
			DEY			; count pulse length (y*2)
			BNE rb_d2	; stay this way for a while (y*3-1)
		DEX				; toggles even/odd number (2)
		LDA 0			; ***eq***
		LDY cur+1		; determines frequency (3)
		STX $DFB0		; send X's LSB to beeper (4)
rb_u2:
			DEY			; count pulse length (y*2)
			BNE rb_u2	; stay this way for a while (y*3-1)
; repeat cycle, note X *must* be a multiple of 4!
		DEX				; toggles even/odd number (2)
		BNE mt_beep2	; new half cycles (3)
	STX $DFB0			; turn off the beeper!
	RTS
; *****************************

; *******************
; *** music score ***
; *******************
; PacMan theme for testing

; array of lengths (rests are computed like G5)
len:
	.byt	 70,  52, 140,  52, 104,  52,  88,  52, 140, 104, 104, 176, 104
	.byt	 74,  52, 148,  52, 110,  52,  92,  52, 148, 110, 104, 184, 104
	.byt	 70,  52, 140,  52, 104,  52,  88,  52, 140, 104, 104, 176, 104
	.byt	 82,  88,  92,  52,  92,  98, 104,  52, 104, 110, 116,  52, 255, 130,   0	; *** end of score ***

; array of notes (rests are 0)
note:
	.byt	190,   0,  94,   0, 126,   0, 150,   0,  94, 126,   0, 150,   0
	.byt	179,   0,  88,   0, 118,   0, 141,   0,  88, 118,   0, 141,   0
	.byt	190,   0,  94,   0, 126,   0, 150,   0,  94, 126,   0, 150,   0
	.byt	159, 150, 141,   0, 141, 133, 126,   0, 126, 118, 112,   0,  94,   0		; no need for extra byte as will be discarded
