; Greyscale test of Durango-X (downloadable version)
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211002-2234

; ****************************
; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202
	test	= 0
	posi	= $FB			; %11111011
	systmp	= $FC			; %11111100
	sysptr	= $FD			; %11111101
	himem	= $FF			; %11111111
	IO8lh	= $DF80			; will become $DF80
	IOAen	= $DFA0			; will become $DFA0
	IOBeep	= $DFB0			; will become $DFB0
; ****************************

* = $400					; downloadable start address

reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X specific stuff
	LDA #$30				; flag init
	STA IO8lh				; set colour mode
	STA IOAen				; disable hardware interrupt
; clear the rest of the screen, just for aesthetics
	LDX #$60
	LDY #0
	STY sysptr
	STX sysptr+1
	TYA						; black
clear:
			STA (sysptr), Y
			INY
			BNE clear
		INC sysptr+1
		BPL clear
; init stuff
	STZ posi				; index for colour

; *** draw a grayscale strip, 8*8 squares, near the centre ***
colour:
	LDX #0					; reset h-pos
	TXA						; first byte is 0
	TAY						; first colour
loop:
		STA $6E00, X
		STA $6E01, X
		STA $6E02, X
		STA $6E03, X
		STA $6F00, X
		STA $6F01, X
		STA $6F02, X
		STA $6F03, X
		INY
		CPY #16
		BNE set
			LDY #0
set:
		LDA scale, Y		; desired index for both pixels!
		INX
		INX
		INX
		INX
	BNE loop
	 
; *** greyscale data ***
scale:
	.byt	0,	$88,	$44,	$CC,	$22,	$AA,	$66,	$EE,	$11,	$99,	$55,	$DD,	$33,	$BB,	$77,	$FF
