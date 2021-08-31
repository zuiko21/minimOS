; FULL test of Durango-X
; (c) 2021 Carlos J. Santisteban
; began 20210831-0212
; last modified 20210831-0340

* = $C000					; standard ROM start

; *** binary data from file ($8000-$FDFF) ***
	.bin	0, $3E00, "../../other/data/romtest.bin"

; *** panic routines ***
; $FE0x = zero page fail
zp_bad:
; high pitched beep

	.ds		ram_bad-*, $FF	; padding

; $FE1x = bad RAM
ram_bad:
; inverse bars and low pitched beep
	LDA #64
rb_1:
		STA $8000			; set flags
rb_2:
			INX
			BNE rb_2		; delay 1.28 kt (~830 µs, 600 Hz)
		EOR #64				; toggle inverse mode
		JMP rb_1

	.ds		rom_bad-*, $FF	; padding

; $FE2x = bad ROM
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
; already at $FE30, no padding

; $FE3x = slow IRQ
slow_irq:

	.ds		fast_irq-*, $FF	; padding

; $FE4x = fast IRQ
fast_irq:

	.ds		banner-*, $FF	; padding

; *** some more data and code ***
; banner data ($FE50...FECF) *** TBD raw file!
banner:
	.bin	0, $80, "../../other/data/durango-x.sv"

; $FED0 = interrupt routine (for both IRQ and NMI test)
isr:
	DEC test				; decrement standard zeropage address
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
	STX $A000				; disable hardware interrupt

; zeropage test
; make high pitched beep during test ()
	LDX #<test				; 6510-savvy...
zp_1:
		LDA #0				; initial value (2+4?)
		STA 0, X
		LDA 0, X			; must be clear right now! (4+2)
			BNE zp_3
		SEC					; prepare for shifting bit
		LDY #10				; number of shifts +1
zp_2:
			DEY				; avoid infinite loop (2+2)
				BEQ zp_3
			ROL 0, X		; rotate (6)
			BNE zp_2		; only zero at the end (3...)
			BCC zp_3		; C must be set at the end (...or 5 last time) (total inner loop = 119t)
		INX					; next address (2+4)
		STX $B000			; make beep at 141t ~5.45 kHz
		BNE zp_1			; complete page (3)
	BEQ zp_ok
zp_3:
		JMP zp_bad			; panic if failed
zp_ok:

; RAM test
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
;				CPX #$80
			BPL rt_2		; ends at $8000, alternatively use BNE if CPX above
		LSR					; create new value, either $0F or 0
		LSR
		LSR
		LSR
		BNE rt_1			; test with new value
	BCC ram_ok				; if arrived here first time, C is set and A=0
rt_3:
		JMP ram_bad			; panic if failed
ram_ok:

; ROM test
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
ro_2:
		LDA banner, X		; put data...
		STA $6000, X		; ...on screen
		INX
		BPL ro_2			; 128-byte banner! (may use BNE if a highres 256 banner is used)

; NMI test
; wait a few seconds for NMI
	STY test				; Y known to be zero
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_nmi				; standard-ish NMI vector
	STX fw_nmi+1
	LDY #0
	LDX #0					; reset timeout counters
; print minibanner *** TBD
nt_1:
		JSR delay			; (48)
		INY					; (2)
		BNE nt_2			; (usually 3)
			INX
			BNE nt_3		; this is timeout
nt_2:
		LDA test			; otherwise wait for non-zero, up to 2.5s (3+3)
		BEQ nt_1
nt_3:
; optionally display dots indicating how many times was called (button bounce) *** TBD

; IRQ test
	LDA #2					; initial value, will time IRQ during 1...0
	STA test
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
it_1:
; MUST provide some timeout *** TBD
		LDA test
		BNE it_1
; check timeout results for slow or fast *** TBD

; *** all OK, end of test ***
	JMP all_ok

; *** interrupt handlers ***
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)

	.ds		$FFFA-*, $FF	; padding

; *** 6502 hard vectors ***
	.word	nmi
	.word	reset
	.word	irq
