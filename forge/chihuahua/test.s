; Chihuahua PLUS hardware test
; (c) 2024 Carlos J. Santisteban
; last modified 20240523-1307

; *** VIA constants ***
#define	IORB	0
#define	IORA	1
#define	DDRB	2
#define	DDRA	3
#define	T1CL	4
#define	T1CH	5
#define	T1LL	6
#define	T1LH	7
#define	T2CL	8
#define	T2CH	9
#define	VSR		10
#define	ACR		11
#define	PCR		12
#define	IFR		13
#define	IER		14
#define	NHRA	15

; ****************************
; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202
	VIAptr	= 0				; Chihuahua specific
	test	= VIAptr+2
	posi	= $FB			; %11111011
	systmp	= $FC			; %11111100
	sysptr	= $FD			; %11111101
	himem	= $FF			; %11111111

; ****************************
	t1ct	= (1000000/250)-2			; 250 Hz interrupt at 1 MHz clock rate

* = $F400					; 3 KiB start address
; *** standard header ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Hardware test for Chihuahua v1.0", 0	; C-string with filename @ [8], max 220 chars
;	.asc	"(comment)"		; optional C-string with comment after filename, filename+comment up to 220 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1001			; 1.0a1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$6000			; time, 12.00		0110 0-000 000-0 0000
	.word	$58B7			; date, 2024/5/23	0101 100-0 101-1 0111
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *******************
; *** actual code ***
; *******************
reset:
	SEI
	CLD
	LDX #$FF
	TSX						; usual 6502 stuff
; first of all, check whether C or D configuration
	STZ VIAptr
	LDA #$80				; first page of I/O for D map
	STA VIAptr+1
	LDY #IER
via_chk:
		LDA #$7F			; writing $7F to IER will read as $80!
		STA (VIAptr), Y
		LDA (VIAptr), Y		; check response
		CMP #$80			; all interrupts disabled
	BEQ via_ok				; VIA is responding properly (if 32K ROM, make sure $800E does *not* contain $80, which is reasonable)
		LSR VIAptr+1		; or try C map instead
		BIT VIAptr+1		; just once
		BVS via_chk			; %01000000 is C map
; *** no VIA detected is horribly wrong ***
panic_loop:
				STA (VIAptr), Y			; fill memory with current A value
				INY
				BNE panic_loop
			INC VIAptr+1	; next page
			BNE panic_loop
		INC					; change fill pattern
		INC VIAptr+1		; ...and skip zeropage
		BNE panic_loop		; no need for BRA
; *** end of panic routine ***

; basic VIA init
via_ok:
	LDA #%11101110			; CA2, CB2 high, CA1, CB1 trailing
	LDY #PCR
	STA (VIAptr), Y
	LDA #%01000000			; T1 free run (PB7 off), no SR, no latch
	LDY #ACR
	STA (VIAptr), Y
	LDA #<t1ct
	LDY #T1CL				; will load T1CL
	STA (VIAptr), Y
	INY						; now for T1CH, that will start count
	LDA #>t1ct
	STA (VIAptr), Y
	LDA #%11000000			; enable T1 interrupt
	LDY #IER
	STA (VIAptr), Y

; ** zeropage test **
; set CB2 high in order to activate sound (PB7) during test
	LDA #%10000000			; PB7 will be output
	LDY #DDRB
	STA (VIAptr), Y			; universal form (STA VIA+DDRB)
	LDY #PCR				; * not really needed...
	LDA (VIAptr), Y			; *
	ORA #%11100000			; * make sure CB2 hi (could use LDA# instead of LDA/ORA#)
	STA (VIAptr), Y			; *
; make high pitched chirp during test
	LDX #<test				; 6510-savvy...
zp_1:
		TXA
		STA 0, X			; try storing address itself (2+4)
		CMP 0, X			; properly stored? (4+2)
			BNE zp_bad
		LDA #0				; A=0 during whole ZP test (2)
		STA 0, X			; clear byte (4)
		CMP 0, X			; must be clear right now! sets carry too (4+2)
			BNE zp_bad
;		SEC					; prepare for shifting bit (2)
		LDY #10				; number of shifts +1 (2, 26t up here)
zp_2:
			DEY				; avoid infinite loop (2+2)
				BEQ zp_bad
			ROL 0, X		; rotate (6)
			BNE zp_2		; only zero at the end (3...)
			BCC zp_bad		; C must be set at the end (...or 5 last time) (total inner loop = 119t)
		CPY #1				; expected value after 9 shifts (2+2)
			BNE zp_bad
		INX					; next address (2+4)
		TXA					; *** Chihuahua specific ***
		ROR: ROR			; * D0 is now at D7
		LDY #IORB
		STA (VIAptr), Y		; *** end of Chihuahua sound ***
		TXA					; * ...but check X again
		BNE zp_1			; complete page (3, post 13t)
	BEQ zp_ok
zp_bad:
		LDA #$FF			; *** bad ZP, LED code = %1 00000000 ***
		JMP panic			; panic if failed
zp_ok:
	LDA #%10000000			; * PB7 high will shut down sound
	LDY #IORB
	STA (VIAptr), Y

; * simple mirroring test *
; probe responding size first
	LDA #127				; max 32 KB, also a fairly good offset EEEEK
	LDY VIAptr+1			; * check whether C (+) or D (-) config *
	BMI ok32				; * D is up to 32K (pages 0...127)
		LSR					; * otherwise C is up to 16K (pages 0...63)
ok32:
	STA test+1				; pointer set (test.LSB known to be zero)
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
	INC						; CMOS only
mt_6:
		INY					; one more bit...
		LSR					; ...and half the memory
		BCC mt_6
	STY posi				; X & Y cannot reach this in address lines test

; ** address lines test ** make sure it NEVER tries to write to VIA
; X=bubble bit, Y=base bit (An+1)
; written value =$XY
; first write all values
	STZ 0					; zero is a special case, as no bits are used
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
			STA (sysptr)	; CMOS only
			TXA				; check if bubble bit is present
			BNE at_2		; it is, just advance it
				TYA			; if not, will be base+1
				TAX
at_2:
			INX				; advance bubble in any case
			CPX posi		; size-savvy!
			BNE at_1
		INY					; end of bubble, advance base bit
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
			CMP (sysptr)	; CMOS only
				BNE at_bad
			TXA				; check if bubble bit is present
			BNE at_5		; it is, just advance it
				TYA			; if not, will be base+1
				TAX
at_5:
			INX				; advance bubble in any case
			CPX posi		; size-savvy!
			BNE at_4
		INY					; end of bubble, advance base bit
		CPY posi			; size-savvy!
		BNE at_3			; this will disable bubble, too
	BEQ addr_ok
at_bad:
		LDA #%10111111		; *** bad address lines, LED code = %1 01000000 ***
		JMP panic
addr_ok:

; ** RAM test **
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
				BNE ram_bad	; mismatch!
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
ram_bad:
		LDA #%10101111		; *** bad RAM, LED code = %1 01010000 ***
		JMP panic			; panic if failed
ram_ok:

; ** ROM test is no longer done **

; * NMI test * HOW? maybe later

; ** IRQ test ** REVISE
irq_test:
; interrupt setup
	LDY #T1CL
	LDA (VIAptr), Y			; just clear previous interrupts
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
	LDY #0					; initial value and inner counter reset
	STY test
; assume HW interrupt is on
	LDX #100				; about 129 ms, time for 32 interrupts
	CLI						; start counting!
; this provides timeout
it_1:
			INY
			BNE it_1
		DEX
		BNE it_1
; check timeout results for slow or fast
	SEI						; no more interrupts, but hardware still generates them (LED off)
; compare results
	LDA test
	CMP #31					; one less is acceptable
	BCS it_3				; <31 is slow
it_slow:
		LDA #%00011111		; *** slow IRQ, LED code = %1 11100000 ***
		JMP panic
it_3:
	CMP #34					; up to 33 is fine
	BCC it_wt				; 31-33 accepted, >33 is fast
it_fast:
		LDA #%10101011		; *** fast IRQ, LED code = %1 01010100 ***
		JMP panic
it_wt:

; ***************************
; *** all OK, end of test ***
; ***************************

; bong sound, tell C from D thru beep codes and lock (just waiting for NMIs)

; ********************************************
; *** interrupt service and other routines ***
; ********************************************
isr:
	BIT $8000+T1CL			; simpler way to acknowledge the T1 interrupt!
	BIT $4000+T1CL
	INC test				; increment standard zeropage address (no longer DEC)
exit:
	RTI

; *** standard panic, will make buzzing bursts instead of Durango's LED
panic:
	SEC						; at least one bit will flash
	EOR #$FF				; this is positive logic, BTW
	LDY #%11101110			; make sure CB2 is high
	STY $800C
	STY $400C				; update PCR (safer)
ploop:
			INY
			BNE ploop
		INX
		BNE ploop			; total cycle is ~326 ms
	ROL						; keep rotating pattern (cycle ~2.94 s)
	TAY						; must save pattern safely
	LDA #%01000000			; standard ACR config
	BCC no_buzz
		ORA #%10000000		; if C, then enable output
no_buzz:
	STA $800B
	STA $400B				; update ACR (safer)
	TYA
	BRA ploop				; not sure about A

; *********************
; *** base firmware ***
; *********************

; *** interrupt handlers ***
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)

; *** ROM footer ***
	.dsb	$FFD6-*, $FF	; filling

	.asc	"DmOS"			; usual ROM signature

	.dsb	$FFE1-*, $FF	; Durango devCart is *not* supported, but anyway
	JMP ($FFFC)

	.dsb	$FFFA-*, $FF	; fill until 6502 hard vectors
	.word	nmi
	.word	reset
	.word	irq
