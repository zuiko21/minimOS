; FULL test of Durango-X
; (c) 2021 Carlos J. Santisteban
; began 20210831-0212
; last modified 20210901-0002

* = $C000					; standard ROM start

; *** binary data from file ($C000-$FBFF, LHHL format) ***
	.bin	0, $3C00, "../../other/data/romtest.bin"

; *** banner data ($FC00...FDFF) *** TBD 512-byte raw file!
banner:
	.bin	0, 512, "../../other/data/durango-x.sv"

; *** panic routines ***
* = $FE00					; *** zero page fail ***
zp_bad:
; high pitched beep (146t ~5.26 kHz, actually 145t or ~5.3 kHz)
	LDY #27
zb_1:
		DEY
		BNE zb_1			; inner loop is 5Y-1
	INX
	STX $B000				; toggle buzzer output
	JMP zp_bad				; outer loop is 11t 

	.ds		addr_bad-*, $FF	; padding from $FE0C

* = $FE10					; *** bad address bus *** may begin a bit earlier ($FE0C) so most of the code runs in $FE1x
addr_bad:
; flashing screen and intermittent beep ~0.21s
	LDA #64					; initial inverse video
	STA $8000				; set flags
ab_1:
			INY
			BNE ab_1		; delay 1.28 kt (~830 µs, 600 Hz)
		INX
		STX $B000			; toggle buzzer output
		BNE ab_1
	STX $8000				; this returns to true video, buzzer was off
ab_2:
			INY
			BNE ab_2		; delay 1.28 kt (~830 µs)
		INX
		BNE ab_2
	BEQ addr_bad

	.ds		ram_bad-*, $FF	; padding

* = $FE30					; *** bad RAM ***
ram_bad:
; inverse bars and low pitched beep
rb_1:
		STA $8000			; set flags (hopefully A<128)
		STA $B000			; set buzzer output
rb_2:
			INX
			BNE rb_2		; delay 1.28 kt (~830 µs, 600 Hz)
		EOR #65				; toggle inverse mode... and buzzer output
		JMP rb_1

	.ds		rom_bad-*, $FF	; padding

* = $FE40					; *** bad ROM ***
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
; already at $FE50, no padding

* = $FE50					; *** slow or missing IRQ ***
slow_irq:
; keep IRQ LED off, low pitch buzz (~119 Hz)
	LDX #10					; 10x123t ~4 ms (125 Hz)
si_1:
		LDY #123			; 10x123t ~4 ms (125 Hz)
si_2:
			DEY
			BPL si_3
		DEX
		STX $B000			; toggle buzzer output
		BNE si_1
	BEQ slow_irq

	.ds		fast_irq-*, $FF	; padding

* = $FE60					; *** fast or spurious IRQ ***
fast_irq:
; 600 Hz beep while IRQ LED blinks *** TBD TBD TBD
			INY
			BNE fast_irq	; delay 1.28 kt (~830 µs, 600 Hz)
		EOR #1				; toggle buzzer and interrupt control pointer
		STX $B000			; set buzzer output
	INX
	
		TAX					; use as index
		STA $A000, X		; enable/disable LED
		JMP fast_irq

	.ds		isr-*, $FF	; padding


; $FED0 = interrupt routine (for both IRQ and NMI test) *** could be elsewhere
isr:
	INC test				; increment standard zeropage address (no longer DEC)
	RTI

	.ds		all_ok-*, $FF	; padding

; $FEFx = ERROR FREE final lock
all_ok:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLC
	BCC all_ok

; *** test suite ***
reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X specific stuff
	STX $A000				; disable hardware interrupt
	LDA #0					; flag init and zp test initial value
	STA $8000				; set colour mode

; * zeropage test *
; make high pitched chirp during test
	LDX #<test				; 6510-savvy...
zp_1:
		STA 0, X			; A=0 during whole ZP test (4)
		LDA 0, X			; must be clear right now! (4+2)
			BNE zp_3
		SEC					; prepare for shifting bit (2)
		LDY #10				; number of shifts +1 (2)
zp_2:
			DEY				; avoid infinite loop (2+2)
				BEQ zp_3
			ROL 0, X		; rotate (6)
			BNE zp_2		; only zero at the end (3...)
			BCC zp_3		; C must be set at the end (...or 5 last time) (total inner loop = 119t)
		CPY #1				; expected value after 9 shifts (2+2)
			BNE zp_3
		INX					; next address (2+4)
		STX $B000			; make beep at 146t ~5.26 kHz
		BNE zp_1			; complete page (3)
	BEQ zp_ok
zp_3:
		JMP zp_bad			; panic if failed
zp_ok:

; * simple mirroring test *
; probe responding size first
	LDY #127				; max 32 KB, also a fairly good offset
	STY test+1				; pointer set (test.LSB known to be zero)
mt_1:
		LDA #$AA			; first test value
mt_2:
			STA (test), Y	; probe address
			CMP (test), Y
				BNE mt_3	; failed
			LSR				; try $55 as well
			BCC mt_2
mt_3:
			BCS mt_4		; failed (¬C) or passed (C)?
		LSR test+1			; if failed, try half the amount
		BNE mt_1
	JMP ram_bad				; if arrived here, there is no more than 256 bytes of RAM, which is a BAD thing
mt_4:
; size is probed, let's check for mirroring
	LDX test+1				; keep highest responding page number
mt_5:
		LDA test+1			; get page number under test
		STA (test), Y		; mark page number
		LSR test+1			; try half the amount
		BNE mt_5
	STX test+1				; recompute highest address tested
	LDA (test), Y			; this is highest non-mirrored page
	STA himem				; store in a safe place (needed afterwards)

; * address lines test *


; * RAM test *
; silent but will show up on screen
	LDA #$F0				; initial value
	LDY #0
	STY test				; standard pointer address
rt_1:
		LDX #1				; skip zeropage
		STX test+1
rt_2:
			STA (test), Y	; store...
			CMP (test), Y	; ...and check
				BNE rt_3	; mismatch!
			INY
			BNE rt_2
				INX			; next page
				STX test+1
				CPX himem	; should check against actual RAMtop
			BNE rt_2		; ends at $8000 or whatever detected RAMtop
		LSR					; create new value, either $0F or 0
		LSR
		LSR
		LSR
		BNE rt_1			; test with new value
	BCC ram_ok				; if arrived here first time, C is set and A=0
rt_3:
		JMP ram_bad			; panic if failed
ram_ok:

; * ROM test *
; must check sequence LHHLLHHL...
	LDX #$C0				; ROM start
	STX test+1				; set pointer (LSB and Y already at zero)
ro_1:
		TYA					; get LSB for first
		CMP (test), Y		; check 1
			BNE ro_3
		INY
		TXA					; second and third must be MSB
		CMP (test), Y		; check 2
			BNE ro_3
		INY
		CMP (test), Y		; check 3
			BNE ro_3
		INY
		TYA					; get LSB for last one
		CMP (test), Y		; check 4
			BNE ro_3
		INY
		BNE ro_1
			INX				; next page
			STX test+1
			CPX #$FE		; end of data
		BNE ro_1
	BEQ rom_ok
ro_3:
		JMP rom_bad			; jump as easily as possible (Z is clear)

; *** delay routine (may be elsewhere)
delay:
	JSR dl_1				; (12)
	JSR dl_1				; (12)
	JSR dl_1				; (12... +12 total overhead =48)
dl_1:
	RTS						; for timeout counters

rom_ok:
; show banner if ROM checked OK
	LDX #0					; reset index
ro_1:
		LDA banner, X		; put data...
		LDA banner+256, X
		STA $6000, X		; ...on screen
		STA $6100, X
		INX
		BNE ro_1			; 512-byte banner as 2x256!

; * NMI test *
; wait a few seconds for NMI
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_nmi				; standard-ish NMI vector
	STX fw_nmi+1
	LDX #0					; reset timeout counters
;	LDY #0					; makes little effect up to 0.4%
	STX test				; reset interrupt counter
; print minibanner *** TBD
	TXA						; or whatever is zero
nt_1:
		JSR delay			; (48)
		INY					; (2)
		BNE nt_2			; (usually 3)
			INX
			BEQ nt_3		; this does timeout after ~2.5s
nt_2:
		CMP test			; NMI happened?
		BEQ nt_1			; nope
			LDY #0			; otherwise do some click
			STY $B000		; buzzer = 1
			JSR delay		; 50 µs pulse
			INY
			STY $B000		; turn off buzzer
			LDA test		; get new target
		BNE nt_1			; no need for BRA
; display dots indicating how many times was called (button bounce)
nt_3:
	LDX test				; using amount as index
	BNE irq_test			; did not respond, don't bother printing dots
		LDA #$0F			; nice clear value in all modes
nt_4:
			STA $6845, X	; place 'dot', note offset
			DEX
			BNE nt_4

; * IRQ test *
irq_test:
	LDA #2					; initial value $FF, will time IRQ from 0
	STA test
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
; must enable interrupts!
it_1:
; MUST provide some timeout *** TBD
		LDA test
		BNE it_1
; check timeout results for slow or fast *** TBD

; *** all OK, end of test ***
	JMP all_ok

; *** interrupt handlers *** could be elsewhere
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)

	.ds		$FFFA-*, $FF	; padding

; *** 6502 hard vectors ***
	.word	nmi
	.word	reset
	.word	irq
