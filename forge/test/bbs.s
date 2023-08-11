; 128K ROM bankswitching test
; (c) 2023 Carlos J. Santisteban

; *** common declarations ***
ptr		= 0

; *** bank 0 ***
	* = $8000

	.dsb	$FF00-*, $FF	; padding

; first init
rst0:
	SEI
	CLD
	LDX #$FF
	TXS
; Durango stuff
	STX $DFA0				; turn LED off
	LDA #$38
	STA $DF80				; colour mode
; standard code
	LDX #$60
	LDY #0
	LDA #$22				; RED
	STY ptr
page0:
		STX ptr+1
loop0:
			STA (ptr), Y
			INY
			BNE loop0
		INX
		BPL page0
; delay loop as usual
	LDA #10
delay0:
				INX
				BNE delay0
			INY
			BNE delay0
		DEC
		BNE delay0
	JMP switch0				; next bank

; dummy interrupt code
dummy0:
	RTI						; do nothing, just in case

; bankswitching code
	.dsb	$FFDC-*, $FF	; padding

switch0:
	LDA #2					; bank 0 -> 2 @FFDC
	STA $DFFC				; bankswitching port @FFDE
	JMP ($FFFC)				; soft reset @FFE1

; ROM bank end
	.dsb	$FFFA-*, $FF	; padding

	.word	dummy0
	.word	rst0
	.word	dummy0
; ***********************************

; *** bank 1 ***
	* = $8000

	.dsb	$FF00-*, $FF	; padding

rst1:
; standard code
	LDX #$60
	LDY #0
	LDA #$55				; GREEN
	STY ptr
page1:
		STX ptr+1
loop1:
			STA (ptr), Y
			INY
			BNE loop1
		INX
		BPL page1
; delay loop as usual
	LDA #10
delay1:
				INX
				BNE delay1
			INY
			BNE delay1
		DEC
		BNE delay1
	JMP switch1				; next bank

; dummy interrupt code
dummy1:
	RTI						; do nothing, just in case

; bankswitching code
	.dsb	$FFDC-*, $FF	; padding

switch1:
	LDA #4					; bank 2 -> 4 @FFDC
	STA $DFFC				; bankswitching port @FFDE
	JMP ($FFFC)				; soft reset @FFE1

; ROM bank end
	.dsb	$FFFA-*, $FF	; padding

	.word	dummy1
	.word	rst1
	.word	dummy1
; ***********************************

; *** bank 2 ***
	* = $8000

	.dsb	$FF00-*, $FF	; padding

rst2:
; standard code
	LDX #$60
	LDY #0
	LDA #$88				; BLUE
	STY ptr
page2:
		STX ptr+1
loop2:
			STA (ptr), Y
			INY
			BNE loop2
		INX
		BPL page2
; delay loop as usual
	LDA #10
delay2:
				INX
				BNE delay2
			INY
			BNE delay2
		DEC
		BNE delay2
	JMP switch2				; next bank

; dummy interrupt code
dummy2:
	RTI						; do nothing, just in case

; bankswitching code
	.dsb	$FFDC-*, $FF	; padding

switch2:
	LDA #6					; bank 4 -> 6 @FFDC
	STA $DFFC				; bankswitching port @FFDE
	JMP ($FFFC)				; soft reset @FFE1

; ROM bank end
	.dsb	$FFFA-*, $FF	; padding

	.word	dummy2
	.word	rst2
	.word	dummy2
; ***********************************

; *** bank 3 ***
	* = $8000

	.dsb	$FF00-*, $FF	; padding

rst3:
; standard code
	LDX #$60
	LDY #0
	LDA #$77				; YELLOW
	STY ptr
page3:
		STX ptr+1
loop3:
			STA (ptr), Y
			INY
			BNE loop3
		INX
		BPL page3
; delay loop as usual
	LDA #10
delay3:
				INX
				BNE delay3
			INY
			BNE delay3
		DEC
		BNE delay3
	JMP switch3				; next bank

; dummy interrupt code
dummy3:
	RTI						; do nothing, just in case

; bankswitching code
	.dsb	$FFDC-*, $FF	; padding

switch3:
	LDA #0					; bank 6 -> 0 @FFDC
	STA $DFFC				; bankswitching port @FFDE
	JMP ($FFFC)				; soft reset @FFE1

; ROM bank end
	.dsb	$FFFA-*, $FF	; padding

	.word	dummy3
	.word	rst3
	.word	dummy3
; ***********************************




