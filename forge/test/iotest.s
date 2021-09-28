; I/O test of Durango-X (downloadable version)
; (c) 2021 Carlos J. Santisteban
; last modified 20210928-1231

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
	STX IOAen				; disable hardware interrupt
	LDA #$30				; flag init
	STA IO8lh				; set colour mode
; clear the rest of the screen, just for aesthetics
	LDX #$60
	LDY #0
	STY sysptr
	STX sysptr+1
	LDA #$BB				; pink!
clear:
			STA (sysptr), Y
			INY
			BNE clear
		INC sysptr+1
		BPL clear

	LDA #%00111111
	SEC
recrap:
INY:bne recrap:inx:bne recrap
ldx#7
crap:
;		STA IOAen+6, X
		DEX
		BNE crap
sta IO8lh+22
	stA IOBeep+8
	ROL
	BRA recrap

; **********************
; *** test  routines ***
; **********************
; 5 kHz beep while IRQ LED blinks
khz:
	SEC
	LDA #%01111111			; single blink per cycle (note C is set in test!)
fi_1:
		LDY #29
fi_2:
			DEY
			BNE fi_2		; delay 155t (~101 µs, ~5 kHz)
		INX
		PHA
		AND #$0F
		TAY
		PLA
		STA IOAen, Y		; update pattern, more than needed
		STX IOBeep			; set buzzer output
		BNE fi_1			; 256 times is ~26 ms
	ROL						; keep rotating pattern (cycle ~0.23 s)
	BNE fi_1				; A is NEVER zero
suite_end:

