; FULL test of Durango-X (downloadable version)
; (c) 2021 Carlos J. Santisteban
; last modified 20210902-2144

; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202
	test	= 0
	himem	= $FF

* = $4000					; downloadable start address

	JMP reset				; this goes to actual code, ROMtest must skip this!

; *** binary data from file ($4004-$5BFF, LHHL format) ***
	.bin	$4004, $1BFC, "../../other/data/lhhl.bin"

; *** banner data ($5C00...5DFF) *** TBD 512-byte raw file!
banner:
	.bin	0, 512, "../../other/data/durango-x.sv"

; *** panic routines ***
* = $5E00					; *** zero page fail ***
zp_bad:
; high pitched beep (158t ~4.86 kHz)
	LDY #29
zb_1:
		DEY
		BNE zb_1			; inner loop is 5Y-1
	NOP						; perfect timing!
	INX
	STX $B000				; toggle buzzer output
	JMP zp_bad				; outer loop is 11t 

	.ds		addr_bad-*, $FF	; padding from $5E0D

* = $5E10					; *** bad address bus ***
addr_bad:
; flashing screen and intermittent beep ~0.21s
; note that inverse video runs on $5E1x while true video on $5E2x
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

* = $5E30					; *** bad RAM ***
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

* = $5E40					; *** bad ROM ***
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
; already at $5E50, no padding

* = $5E50					; *** slow or missing IRQ ***
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

* = $5E60					; *** fast or spurious IRQ ***
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


; $5ED0 = interrupt routine (for both IRQ and NMI test) *** could be elsewhere
isr:
	INC test				; increment standard zeropage address (no longer DEC)
	RTI

	.ds		all_ok-*, $FF	; padding

; $5EFx = ERROR FREE final lock
all_ok:
	STA $A000				; keep LED on
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

; ******************
; *** test suite ***
; ******************
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
		TXA
		STA 0, X			; try storing address itself (2+4)
		CMP 0, X			; properly stored? (4+2)
			BNE zp_3
		LDA #0				; A=0 during whole ZP test (2)
		STA 0, X			; clear byte (4)
		CMP 0, X			; must be clear right now! sets carry too (4+2)
			BNE zp_3
;		SEC					; prepare for shifting bit (2)
		LDY #10				; number of shifts +1 (2, 26t up here)
zp_2:
			DEY				; avoid infinite loop (2+2)
				BEQ zp_3
			ROL 0, X		; rotate (6)
			BNE zp_2		; only zero at the end (3...)
			BCC zp_3		; C must be set at the end (...or 5 last time) (total inner loop = 119t)
		CPY #1				; expected value after 9 shifts (2+2)
			BNE zp_3
		INX					; next address (2+4)
		STX $B000			; make beep at 158t ~4.86 kHz
		BNE zp_1			; complete page (3, post 13t)
	BEQ zp_ok
zp_3:
		JMP zp_bad			; panic if failed
zp_ok:

; * simple mirroring test *
; probe responding size first
	LDY #63					; max 16 KB, also a fairly good offset
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
		BNE rt_2
rt_1s:
		LDX #$60			; skip to begin of screen
rt_2:
			STX test+1		; update pointer
			STA (test), Y	; store...
			CMP (test), Y	; ...and check
				BNE rt_3	; mismatch!
			INY
			BNE rt_2
				INX			; next page
				STX test+1
				CPX himem	; should check against actual RAMtop
			BCC rt_2		; ends at whatever detected RAMtop...
			BEQ rt_2
				CPX #$60	; already at screen
				BCC rt_1s	; ...or continue with screen
			CPX #$80		; end of screen?
			BNE rt_2
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
	LDX #$40				; ROM start
	STX test+1				; set pointer
	LDY #4					; must skip initial JMP!
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
			CPX #$5C		; end of data
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
; print minibanner
	LDX #6					; number of horizontal bytes
nt_b:
		LDA nmi_b, X		; copy banner data into screen, note offsets
		STA $67FF, X
		LDA nmi_b+6, X
		STA $683F, X
		DEX
		BNE nt_b
; proceed with timeout
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
; prepare screen with minibanner
	LDX #5					; number of horizontal bytes
it_b:
		LDA irq_b, X		; copy banner data into screen, note offsets
		STA $6F3F, X
		LDA irq_b+5, X
		STA $6F7F, X
		LDA irq_b+10, X
		STA $6FBF, X
		DEX
		BNE it_b
; interrupt setup
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
	LDY #0					; initial value and inner counter reset
	STY test
; must enable interrupts!
	STY $A001				; hardware interrupt enable
	LDX #154				; about 129 ms, time for 32 interrupts
	CLI						; start counting!
; this provides timeout
it_1:
			INY
			BNE it_1
		DEX
		BNE it_1
; check timeout results for slow or fast
	SEI						; no more interrupts
; display dots indicating how many times IRQ happened
	LDX test				; using amount as index
		BNE it_slow			; did not respond at all!
	LDA #$0F				; nice clear value in all modes
	STA $6FD9				; place index dot @ 32
it_2:
		STA $7040, X		; place 'dot', note vertical offset
		DEX
		BNE it_2
; compare results
	LDA test
	CMP #31					; one less is aceptable
	BCS it_3				; <31 is slow 
it_slow:
		JMP slow_irq
it_3:
	CMP #34					; up to 33 is fine
	BCC it_ok				; 31-33 accepted
		JMP fast_irq		; >33 is fast

it_ok:
; *** all OK, end of test ***
	JMP all_ok

; *** interrupt handlers *** could be elsewhere
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)

; *** mini banners *** could be elsewhere
nmi_b:
	.byt	$FF, $0F, $0F, $F0, $FF, $0F
	.byt	$F0, $FF, $0F, $0F, $0F, $0F
irq_b:
	.byt	$F0, $FF, $F0, $FF, $F0
	.byt	$F0, $FF, $00, $F0, $F0
	.byt	$F0, $F0, $F0, $FF, $0F

suite_end:

