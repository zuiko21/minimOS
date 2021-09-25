; panics from test of Durango-X (downloadable version)
; (c) 2021 Carlos J. Santisteban
; last modified 20210925-2227

; ****************************
; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202
	test	= 0
	posi	= $FB			; %11111011
	systmp	= $FC			; %11111100
	sysptr	= $FD			; %11111101
	himem	= $FF			; %11111111
	IO8lh	= $8000			; will become $DF80
	IOAen	= $A000			; will become $DFA0
	IOBeep	= $B000			; will become $DFB0
; ****************************

* = $4000					; downloadable start address

reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X specific stuff
	STX IOAen				; disable hardware interrupt
	LDA #$30				; flag init
	STA IO8lh				; set colour mode
; put banner on screen
	LDX #0					; reset index
ro_4:
		LDA banner, X		; put data...
		STA $6000, X		; ...on screen
		LDA banner+256, X
		STA $6100, X
		LDA banner+512, X	; it's 1K EEEEEEEK
		STA $6200, X
		LDA banner+768, X
		STA $6300, X
		INX
		BNE ro_4			; 1K-byte banner as 4x256!
; clear the rest of the screen, just for aesthetics
	LDX #$64
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
; set NMI for panic switching
	LDX #>panics			; panic address start
	LDY #<panics
	STY posi				; set indirect jump
	STX posi+1

	STZ test				; bounce control

	LDX #>isr				; set interrupt vector
	LDY #<isr
	STY fw_nmi
	STX fw_nmi+1

; set BRK for catastrophic errors
	LDY #<break
	LDX #>break
	STY fw_irq
	STX fw_irq+1
lock:
	BNE lock				; locked... but wait for NMI!

; *** print routine (A= 0, $20...)
prn:
	LDX #$30
	STX IO8lh				; disable inverse
	LSR
	LSR
	STA himem				; temporary add
	LSR
;	CLC
	ADC himem				; n*12
	TAX						; index of minibanner
	LDY #0					; reset offset, worth it
pl:
		LDA texts, X		; first scan
		STA $681C, Y
		LDA texts+3, X		; second
		STA $685C, Y
		LDA texts+6, X		; third
		STA $689C, Y
		LDA texts+9, X		; and fourth
		STA $68DC, Y
		INX					; advance in banner offset
		INY
		CPY #3				; number of bytes?
		BNE pl
	RTS

	.dsb	$4100-*, $FF	; padding

; *** banner data ($5800...5BFF) *** 1 Kbyte raw file!
banner:
	.bin	0, 1024, "../../other/data/durango-x.sv"

; ********************************************
; *** miscelaneous stuff, may be elsewhere ***
; ********************************************

; interrupt routine (for NMI as a routine switching button) *** currently $4500
isr:
	PHA
	LDA test
	BNE exit				; avoid bouncing
		PHX:PHY
		INC test
loop:
			INC himem
			BNE loop
		LDA posi
		CLC
		ADC #$20
		CMP #$C0			; first non-existent routine
		BNE do
			LDA #0
do:
		STA posi
		JSR prn				; display little text (A=0, $20, $40...)
		STZ test			; allow future interrupts after delay
		PLY:PLX:PLA
		JMP (posi)
exit:
	PLA
	RTI

; *** delay routine (may be elsewhere)
delay:
	JSR dl_1				; (12)
	JSR dl_1				; (12)
	JSR dl_1				; (12... +12 total overhead =48)
dl_1:
	RTS						; for timeout counters

; *** small texts (3x3)
texts:
	.byt	$FF, $BF, $FB, $BF, $BF, $FB, $FB, $BF, $BB, $FF, $BF, $BB	; ZP
	.byt	$FF, $FB, $FB, $FB, $FB, $FB, $FF, $FB, $FB, $FB, $FB, $FF	; AL
	.byt	$FF, $FB, $FB, $FB, $FB, $FB, $FF, $BB, $FF, $FB, $FB, $FF	; RB
	.byt	$FF, $BF, $FF, $FB, $BF, $BF, $FB, $BF, $FB, $FF, $BF, $BF	; CR
	.byt	$FF, $BF, $BB, $FB, $BF, $BB, $BF, $BF, $BB, $FF, $BF, $BB	; SI
	.byt	$FF, $BF, $BB, $FB, $BF, $BB, $FF, $BF, $BB, $FB, $BF, $BB	; FI
misc_end:

	.dsb	$4700-*, $FF	; padding

; **********************
; *** panic routines ***
; **********************
* = $4700					; *** zero page fail ***
panics:
zp_bad:
; high pitched beep (158t ~4.86 kHz)
	LDY #29
zb_1:
		DEY
		BNE zb_1			; inner loop is 5Y-1
	NOP						; perfect timing!
	INX
	STX IOBeep				; toggle buzzer output
	JMP zp_bad				; outer loop is 11t 

	.dsb	$4720-*, $FF	; padding from $5F0D

* = $4720					; *** bad address bus ***
addr_bad:
; flashing screen and intermittent beep ~0.21s
; note that inverse video runs on $5F1x while true video on $5F2x
	LDA #$70				; initial inverse video
	STA IO8lh				; set flags
ab_1:
			INY
			BNE ab_1		; delay 1.28 kt (~830 µs, 600 Hz)
		INX
		STX IOBeep			; toggle buzzer output
		BNE ab_1
	EOR #$40
	STA IO8lh				; this returns to true video, buzzer was off
ab_2:
			INY
			BNE ab_2		; delay 1.28 kt (~830 µs)
		INX
		BNE ab_2
	BEQ addr_bad

	.dsb	$4740-*, $FF	; padding

* = $4740					; *** bad RAM ***
ram_bad:
; inverse bars and continuous beep
	LDA #$71
rb_0:
	STA IO8lh				; set flags
	STA IOBeep				; set buzzer output
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	EOR #65					; toggle inverse mode... and buzzer output
	JMP rb_0

	.dsb	$4760-*, $FF	; padding

* = $4760					; *** bad ROM ***
rom_bad:
; silent, will not show banner, try to use as few ROM addresses as possible, arrive with Z clear
	BNE rom_bad
	BNE rom_bad+2
	BNE rom_bad+4
	BNE rom_bad+6
	BNE rom_bad+8
	BNE rom_bad+10
	BNE rom_bad+12
	BNE rom_bad+14

	.dsb	$4780-*, $FF	; padding

* = $4780					; *** slow or missing IRQ ***
slow_irq:
; keep IRQ LED off, low pitch buzz (~125 Hz)
	STA IOAen+1				; LED off
si_0:
	LDY #116				; 116x53t ~4 ms
si_1:
		JSR delay
		DEY
		BPL si_1
	INX
	STX IOBeep				; toggle buzzer output
	JMP slow_irq

	.dsb	$47A0-*, $FF	; padding

* = $47A0					; *** fast or spurious IRQ ***
fast_irq:
; 1.7 kHz beep while IRQ LED blinks
	SEC
	LDA #%01011111			; couple of blinks per cycle (note C is set in test!)
fi_1:
		LDY #91
fi_2:
			DEY
			BNE fi_2		; delay 455t (~296 µs, 1688 Hz)
		INX
		STX IOBeep			; set buzzer output
		BNE fi_1			; 256 times is ~76 ms
	ROL						; keep rotating pattern (cycle ~0.68 s)
	TAY						; use as index
	STA IOAen, Y			; LED is on only when A0=0, ~44% the time
	BNE fi_1				; A/X are NEVER zero

; *** internal error handler ***
break:
	STZ $681A
	LDA #$B0				; hires mode
	STA IO8lh
	BNE break

suite_end:

