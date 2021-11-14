; FULL test of Durango-X (downloadable version)
; (c) 2021 Carlos J. Santisteban
; last modified 20211114-1332

; *** memory maps ***
;				ROMable		DOWNLOADable
;	test RAM	<$7FFF		<$3FFF, $6000-$7FFF
;	test ROM	$C000-$F7FF	$4004-$57FF
;	banner		$F800-$FBFF	$5800-$5BFF
;	test code	$FC00-$FEFF	$5C00-$5EFF
;	panics		$FFxx		$5Fxx

; prototype uses old I/O addresses and A0-driven interrupt control
;#define	PROTO	_PROTO

; ****************************
; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202
	test	= 0
	posi	= $FB			; %11111011
	systmp	= $FC			; %11111100
	sysptr	= $FD			; %11111101
	himem	= $FF			; %11111111
#ifndef	PROTO
	IO8lh	= $DF80
	IOAen	= $DFA0
	IOBeep	= $DFB0
#else
	IO8lh	= $8000
	IOAen	= $A000
	IOBeep	= $B000
#endif
; ****************************

* = $4000					; downloadable start address

	JMP reset				; this goes to actual code, ROMtest must skip this!
	NOP						; must take 4 bytes EEEEEEEK

; *** binary data from file ($4004-$57FF, LHHL format) ***
	.bin	$4004, $17FC, "../../other/data/lhhl.bin"

; *** banner data ($5800...5BFF) *** 1 Kbyte raw file!
banner:
	.bin	0, 1024, "../../other/data/durango-x.sv"

; ******************
; *** test suite ***
; ******************
reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X specific stuff
	LDA #$38				; flag init and interrupt disable, RGB
	STA IO8lh				; set colour mode
	STA IOAen				; disable hardware interrupt, also for PROTO

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
		STX IOBeep			; make beep at 158t ~4.86 kHz
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
; the address test needs himem in a bit-position format (An+1)
	LDY #8					; limit in case of a 256-byte RAM!
#ifdef	NMOS
	INC						; CMOS only
#else
	CLC
	ADC #1
#endif
mt_6:
		INY					; one more bit...
		LSR					; ...and half the memory
		BCC mt_6
	STY posi				; X & Y cannot reach this in address lines test

; * address lines test *
; X=bubble bit, Y=base bit (An+1)
; written value =$XY
; first write all values
#ifndef	NMOS
	STZ 0					; zero is a special case, as no bits are used
#else
	LDA #0
	STA 0
#endif
	LDY #1					; first base bit, representing A0
at_0:
		LDX #0				; init bubble bit as disabled, will jump to Y+1
at_1:
			LDA bit_l, Y
			ORA bit_l, X	; create pointer LSB
			STA sysptr
			LDA bit_h, Y
			ORA bit_h, X	; with MSB, pointer complete
			STA sysptr+1
			STY systmp		; lower nibble to write
			TXA				; this will be higher nibble...
			ASL
			ASL
			ASL
			ASL				; ...times 16
			ORA systmp		; byte complete in A
#ifndef	NMOS
			STA (sysptr)	; CMOS only
#else
			LDY #0
			STA (sysptr), Y
			LDY systmp		; easily recovered writing $XY instead of $YX
#endif
			TXA				; check if bubble bit is present
			BNE at_2		; it is, just advance it
				TYA			; if not, will be base+1
				TAX
at_2:
			INX				; advance bubble in any case
;			CPX #$F			; only 16K allowed! (ROM based use $10)
			CPX posi		; size-savvy!
			BNE at_1
		INY					; end of bubble, advance base bit
;		CPY #$F				; max. 16K (ROM use $10)
		CPY posi			; size-savvy
		BNE at_0			; this will disable bubble, too
; then compare computed and stored values
	LDA #0
	CMP 0					; zero is a special case, as no bits are used
		BNE at_bad
	LDY #1					; first base bit, representing A0
at_3:
		LDX #0				; init bubble bit as disabled, will jump to Y+1
at_4:
			LDA bit_l, Y
			ORA bit_l, X	; create pointer LSB
			STA sysptr
			LDA bit_h, Y
			ORA bit_h, X	; with MSB, pointer complete
			STA sysptr+1
			STY systmp		; lower nibble to write
			TXA				; this will be higher nibble...
			ASL
			ASL
			ASL
			ASL				; ...times 16
			ORA systmp		; byte complete in A
#ifndef	NMOS
			CMP (sysptr)	; CMOS only
				BNE at_bad
#else
			LDY #0
			CMP (sysptr), Y
				BNE at_bad
			LDY systmp		; easily recovered writing $XY instead of $YX
#endif
			TXA				; check if bubble bit is present
			BNE at_5		; it is, just advance it
				TYA			; if not, will be base+1
				TAX
at_5:
			INX				; advance bubble in any case
;			CPX #$F			; only 16K allowed! (ROM based use $10)
			CPX posi		; size-savvy!
			BNE at_4
		INY					; end of bubble, advance base bit
;		CPY #$F				; max. 16K (ROM use $10)
		CPY posi			; size-savvy!
		BNE at_3			; this will disable bubble, too
	BEQ addr_ok
at_bad:
		JMP addr_bad
addr_ok:

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
		BCS rt_1			; EEEEEEEEEEEEK
	BCC ram_ok				; if arrived here SECOND time, C is CLEAR and A=0
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
			CPX #$58		; end of data EEEEEEK
		BNE ro_1
	BEQ rom_ok
ro_3:
		JMP rom_bad			; jump as easily as possible (Z is clear)

rom_ok:
; show banner if ROM checked OK
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

; * NMI test *
; wait a few seconds for NMI
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_nmi				; standard-ish NMI vector
	STX fw_nmi+1
; print minibanner
	LDX #5					; max. horizontal offset
nt_b:
		LDA nmi_b, X		; copy banner data into screen
		STA $6800, X
		LDA nmi_b+6, X
		STA $6840, X
		DEX
		BPL nt_b			; no offset!
; proceed with timeout
	LDX #0					; reset timeout counters (might use INX as well)
;	LDY #0					; makes little effect up to 0.4%
	STX test				; reset interrupt counter
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
			STY IOBeep		; buzzer = 1
			JSR delay		; 50 µs pulse
			INY
			STY IOBeep		; turn off buzzer
			LDA test		; get new target
		BNE nt_1			; no need for BRA
; disable NMI again for safer IRQ test
	LDY #<exit
;	LDA #>exit				; maybe the same
	STY fw_nmi
;	STA fw_nmi+1
; display dots indicating how many times was called (button bounce)
nt_3:
	LDX test				; using amount as index
	BEQ irq_test			; did not respond, don't bother printing dots EEEEEEEK
		LDA #$0F			; nice white value in all modes
nt_4:
			STA $6845, X	; place 'dot', note offset as zero does not count
			DEX
			BNE nt_4

; * IRQ test *
irq_test:
; prepare screen with minibanner
	LDX #4					; max. horizontal offset
it_b:
		LDA irq_b, X		; copy banner data into screen
		STA $6F40, X
		LDA irq_b+5, X
		STA $6F80, X
		LDA irq_b+10, X
		STA $6FC0, X
		DEX
		BPL it_b			; no offset!
; inverse video during test (brief flash)
	LDA #$79				; colour, inverse and interrupt enable (valid for PROTO)
	STA IO8lh
; interrupt setup
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
	LDY #0					; initial value and inner counter reset
	STY test
; must enable interrupts!
	STA IOAen+1				; hardware interrupt enable (LED goes off) suitable for all
	LDX #154				; about 129 ms, time for 32 interrupts
	CLI						; start counting!
; this provides timeout
it_1:
			INY
			BNE it_1
		DEX
		BNE it_1
; check timeout results for slow or fast
	SEI						; no more interrupts, but hardware still generates them (LED off)
; back to true video
	LDX #$38				; can no longer be zero
	STX IO8lh
; display dots indicating how many times IRQ happened
	LDX test				; using amount as index
		BEQ it_slow			; did not respond at all! eeeeeek
	LDA #$01				; nice mid green value in all modes
	STA $6FDF				; place index dot @32 eeeeeek
	LDA #$0F				; nice white value in all modes
it_2:
		STA $703F, X		; place 'dot', note offsets
		DEX
		BNE it_2
; compare results
	LDA test
	CMP #31					; one less is aceptable
	BCS it_3				; <31 is slow 
it_slow:
#ifndef	PROTO
		LDA #1				; ready for LED off
#endif
		JMP slow_irq
it_3:
	CMP #34					; up to 33 is fine
	BCC it_ok				; 31-33 accepted
		JMP fast_irq		; >33 is fast

it_ok:

; *** next is testing for HSYNC and VSYNC... ***
; make sure X ends at 0, or load after!

; *** all OK, end of test ***
; sweep sound, print OK banner and lock
	STX IOAen				; interrupts are masked, let's turn the LED on anyway, suitable for all
	STX test				; sweep counter
	TXA						; X known to be zero, again
sweep:
		LDX #8				; sound length in half-cycles
beep_l:
			TAY				; determines frequency (2)
			STX IOBeep		; send X's LSB to beeper (4)
rb_zi:
				STY test+1	; small delay for 1.536 MHz! (3)
				DEY			; count pulse length (y*2)
				BNE rb_zi	; stay this way for a while (y*3-1)
			DEX				; toggles even/odd number (2)
			BNE beep_l		; new half cycle (3)
		STX IOBeep			; turn off the beeper!
		LDA test			; period goes down, freq. goes up
		SEC
		SBC #4				; frequency change rate
		STA test
		CMP #16				; upper limit
		BCS sweep
; sound done, print GREEN banner
	LDX #3					; max. offset
ok_l:
		LDA ok_b, X			; put banner data...
		STA $77DC, X		; ...in appropriate screen place
		LDA ok_b+4, X
		STA $781C, X
		LDA ok_b+8, X
		STA $785C, X
		DEX
		BPL ok_l			; note offset-avoiding BPL

;	JMP all_ok				; final lock at $5FFx
	JMP reset				; continuous test
test_end: 

; ********************************************
; *** miscelaneous stuff, may be elsewhere ***
; ********************************************

; *** interrupt handlers *** could be elsewhere, ROM only
irq:
;	JMP (fw_irq)
nmi:
;	JMP (fw_nmi)

; interrupt routine (for both IRQ and NMI test) *** could be elsewhere
isr:
	PHA						; universal comprehensive ISR
	TXA
	PHA						; X saved, NMOS savvy
	TSX
	LDA $101, X				; get saved PSR
	AND #$10				; B 'flag'
	BEQ do_isr				; not set, expected IRQ, all OK
		LDX test
		LDA #$02			; otherwise print a red dot below
		STA $7080, X
do_isr:
	INC test				; increment standard zeropage address (no longer DEC)
	PLA						; restore status
	TAX
	PLA
exit:
	RTI

; *** mini banners *** could be elsewhere
nmi_b:
	.byt	$DD, $0D, $0D, $D0, $DD, $0D	; cyan
	.byt	$D0, $DD, $0D, $0D, $0D, $0D
irq_b:
	.byt	$60, $66, $60, $66, $60			; 'brick' colour
	.byt	$60, $66, $00, $60, $60
	.byt	$60, $60, $60, $66, $06
ok_b:
	.byt	$55, $50, $50, $50				; green
	.byt	$50, $50, $55, $00
	.byt	$55, $50, $50, $50

; *** delay routine (may be elsewhere)
delay:
	JSR dl_1				; (12)
	JSR dl_1				; (12)
	JSR dl_1				; (12... +12 total overhead =48)
dl_1:
	RTS						; for timeout counters

; *** bit position table ***
; INDEX =    0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
bit_l:
	.byt	$00, $01, $02, $04, $08, $10, $20, $40, $80, $00, $00, $00, $00, $00, $00, $00
;            -    A0   A1   A2   A3   A4   A5   A6   A7   A8   A9   AA   AB   AC   AD   AE (A14)
bit_h:
	.byt    $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $04, $08, $10, $20, $40

misc_end:

	.dsb	$5F00-*, $FF	; padding

; **********************
; *** panic routines ***
; **********************
* = $5F00					; *** zero page fail ***
zp_bad:
; high pitched beep (158t ~4.86 kHz)
	LDY #29
zb_1:
		DEY
		BNE zb_1			; inner loop is 5Y-1
	NOP						; perfect timing!
	INX
	STX IOBeep				; toggle buzzer output
	BRA zp_bad				; outer loop is 11t 

	.dsb	$5F10-*, $FF	; padding from $5F0D

* = $5F10					; *** bad address bus ***
addr_bad:
; flashing screen and intermittent beep ~0.21s
; note that inverse video runs on $5F1x while true video on $5F2x
	LDA #$78				; initial inverse video
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

	.dsb	$5F30-*, $FF	; padding

* = $5F30					; *** bad RAM ***
ram_bad:
; inverse bars and continuous beep
	LDA #$79
rb_0:
	STA IO8lh				; set flags
	STA IOBeep				; set buzzer output
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	EOR #$41				; toggle inverse mode... and buzzer output
	BRA rb_0
ramend:
	.dsb	$5F40-*, $FF	; padding

* = $5F40					; *** bad ROM ***
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
; already at $5F50, no padding

* = $5F50					; *** slow or missing IRQ ***
slow_irq:
; keep IRQ LED off, low pitch buzz (~125 Hz)
	STA IOAen+1				; LED off, suitable for all (assume A=1)
	LDY #116				; 116x53t ~4 ms
si_1:
		JSR delay
		DEY
		BPL si_1
	INX
	STX IOBeep				; toggle buzzer output
	BRA slow_irq
si_end:
	.dsb	$5F60-*, $FF	; padding

* = $5F60					; *** fast or spurious IRQ ***
fast_irq:
; 1.7 kHz beep while IRQ LED blinks
	LDA #$0F				; %00001111·1, ~44% duty cycle for LED (note C is set in test!)
fi_1:
		LDY #91
fi_2:
			DEY
			BNE fi_2		; delay 455t (~296 µs, 1688 Hz)
		INX
		STX IOBeep			; set buzzer output
		BNE fi_1			; 256 times is ~76 ms
	ROL						; keep rotating pattern (cycle ~0.68 s)
#ifndef	PROTO
	STA IOAen				; LED is on only when A0=0, ~44% the time
#else
	TAY						; use as index
	STA IOAen, Y			; LED is on only when A0=0, ~44% the time
#endif
	BNE fi_1				; A/X are NEVER zero

	.dsb	$5FF0-*, $FF	; padding

; *** next is testing for HSYNC and VSYNC... ***

; $5FFx = ERROR FREE final lock
* = $5FF0
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
	CLC
	BCC all_ok
suite_end:
