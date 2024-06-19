; Chihuahua PLUS hardware test
; (c) 2024 Carlos J. Santisteban
; last modified 20240619-0855
; use -DPOCKET for nanoBoot version (@ $800)
; *** speed in Hz (use -DSPEED=x, default 1 MHz) ***
#ifndef	SPEED
#define		SPEED	1000000
#endif

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
	Dmap	= $8000			; original VIA location
	Cmap	= $4000
	VIAptr	= 0				; Chihuahua specific
	test	= VIAptr+2		; 6510-savvy
	posi	= $FB			; %11111011
	systmp	= $FC			; %11111100
	sysptr	= $FD			; %11111101
	himem	= $FF			; %11111111
; ****************************

	t1ct	= (SPEED/250)-2	; 250 Hz interrupt at 1 MHz (or whatever) clock rate

#ifndef	POCKET
* = $F800					; 2 KiB start address
#else
#echo Pocket version!
* = $800
#endif
; *** standard header ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
#ifndef	POCKET
	.asc	"dX"			; bootable ROM
	.asc	"****"			; reserved
#else
	.asc	"pX"			; downloadable Pocket format
	.word	rom_start		; load address
	.word	reset			; execution address
#endif
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Hardware test for Chihuahua v1.1", 0	; C-string with filename @ [8], max 220 chars
;	.asc	"(comment)"		; optional C-string with comment after filename, filename+comment up to 220 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1141		; 1.1b1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$4700			; time, 8.56		0100 0-111 000-0 0000
	.word	$58D3			; date, 2024/6/19	0101 100-0 110-1 0011
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
	TXS						; usual 6502 stuff EEEEK
	STX Dmap+IORB
	STX Cmap+IORB			; all PB LEDs will flash for a moment
	STX Dmap+DDRB
	STX Cmap+DDRB			; set all PB bits to output, wherever the VIA is

; basic VIA init
; try disabling any interrupts, just in case
	LDA #%01111111			; all off
	STA Dmap+IER
	STA Cmap+IER
; set CB2 high in order to activate sound (PB7) during test
	LDA #%11101110
	STA Dmap+PCR
	STA Cmap+PCR
; start T1 counter!
	LDA #%01000000			; T1 free run (PB7 off), no SR, no latch
	STA Dmap+ACR
	STA Cmap+ACR
	LDA #<t1ct
	STA Dmap+T1CL
	STA Cmap+T1CL			; will load T1CL
	LDA #>t1ct				; now for T1CH, that will start count
	STA Dmap+T1CH
	STA Cmap+T1CH
#ifdef	DEBUG
	LDA #%10000000			; all LEDs off, except PB7 to disable sound (VIA OK)
	STA Dmap+IORB
	STA Cmap+IORB			; clear all LEDs, safest way
#endif

; ** zeropage test **
; make high pitched chirp during test
	LDX #<test				; Chihuahua and 6510-savvy...
zp_1:
		TXA
		STA 0, X			; try storing address itself (2+4)
		CMP 0, X			; properly stored? (4+2)
			BNE zp_bad
		LDA #0				; A=0 during whole ZP test (2)
		STA 0, X			; clear byte (4)
		CMP 0, X			; must be clear right now! sets carry too (4+2)
			BNE zp_bad
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
		STA Dmap+IORB
		STA Cmap+IORB		; *** end of Chihuahua sound ***
		TXA					; * ...but check X again
		BNE zp_1			; complete page (3, post 13t)
	BEQ zp_ok
zp_bad:
		LDA #$FF			; *** bad ZP, LED code = %1 00000000 ***
		JMP panic			; panic if failed
zp_ok:
	LDA #%11000001			; turn on PB0 (zeropage OK) & PB7 (sound off), PB6 means 'do not use NMI'
	STA Dmap+IORB
	STA Cmap+IORB
; * simple mirroring test *
; first of all, check whether C or D configuration
	LDA #>Dmap				; first page of I/O for D map
	STA VIAptr+1
	LDA #$7F				; writing $7F to IER will read as $80!
	STA Dmap+IER
	LDX Dmap+IER			; check response
	CPX #$80				; are all interrupts disabled?
	BEQ via_ok				; VIA is responding properly (if 32K ROM, make sure $800E does *not* contain $80, which is reasonable)
		LSR VIAptr+1		; or try C map instead
		STA Cmap+IER
		LDX Cmap+IER		; check response EEEEK
		CPX #$80			; are all interrupts disabled?
	BEQ via_ok
; *** no VIA detected is horribly wrong ***
		STZ VIAptr			; may serve as pointer (MSB somewhat set)
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
via_ok:
; probe responding size then
	LDA #127				; max 32 KB, but not a good offset EEEEK
	LDX VIAptr+1			; * check whether C (+) or D (-) config *
	BMI ok32				; * D is up to 32K (pages 0...127)
		LSR					; * otherwise C is up to 16K (pages 0...63)
ok32:
	STA test+1				; pointer set (test.LSB known to be zero)
	LDY #IER				; now this is a good offset as won't return the written value
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
#ifdef	POCKET
		LDA test+1
		CMP #$C				; keep above loaded code!
		BCS mt_1
#else
		BNE mt_1
#endif
	JMP ram_bad				; if arrived here, there is no more than 256 bytes of RAM, which is a BAD thing
mt_4:
; size is probed, let's check for mirroring
	LDX test+1				; keep highest responding page number
mt_5:
		LDA test+1			; get page number under test
		STA (test), Y		; mark page number
		LSR test+1			; try half the amount
#ifdef	POCKET
		LDA test+1
		CMP #$C				; keep above loaded code!
		BCS mt_5
#else
		BNE mt_5
#endif
	STX test+1				; recompute highest address tested
	LDA (test), Y			; this is highest non-mirrored page
	STA himem				; store in a safe place (needed afterwards)
; the address test needs himem in a bit-position format (An+1)
#ifdef	POCKET
	LDY #12					; * * * is this OK? * * *
#else
	LDY #8					; limit in case of a 256-byte RAM!
#endif
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
#ifdef	POCKET
			CMP #$8			; below code memory...
			BCC at_1ok
				CMP #$C		; ...or above it? continue as normal
				BCC at_2	; otherwise skip this combo
at_1ok:
#endif
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
	LDA 0					; zero is a special case, as no bits are used
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
#ifdef	POCKET
			CMP #$8			; below code memory...
			BCC at_4ok
				CMP #$C		; ...or above it? continue as normal
				BCC at_5	; otherwise skip this combo
at_4ok:
#endif
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
#ifdef	DEBUG
	LDA #%11000010			; PB1 means address test OK
	STA Dmap+IORB
	STA Cmap+IORB
#endif

; ** RAM test **
	LDA #$F0				; initial value
	LDY #0
	STY test				; standard pointer address
rt_1:
		LDX #1				; skip zeropage
rt_2:
			STX test+1		; update pointer
			STA (test), Y	; store...
			CMP (test), Y	; ...and check
				BNE ram_bad	; mismatch!
			INY
			BNE rt_2
				INX			; next page
#ifdef	POCKET
				CPX #$8		; are we entering code memory?
				BNE rt_2ok
					LDX #$C	; if so, skip it!
rt_2ok:
#endif
				CPX himem	; should check against actual RAMtop
			BCC rt_2		; ends at whatever detected RAMtop...
			BEQ rt_2
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
#ifdef	DEBUG
	LDA #%10000100			; PB2 means RAM OK
	STA Dmap+IORB
	STA Cmap+IORB
#endif

; ** ROM test is no longer done **

; * NMI test * HOW? maybe later

; ** IRQ test ** REVISE
irq_test:
; interrupt setup
	LDY #<exit
	LDX #>exit
	STY fw_nmi
	STX fw_nmi+1			; disable NMI for a while EEEEK
; make sure HW interrupt is on
	LDA #%11000000			; enable T1 interrupt
	STA Dmap+IER
	STA Cmap+IER
	BIT Dmap+T1CL
	BIT Cmap+T1CL			; just clear previous interrupts
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
	LDX #(50*SPEED/1000000)	; 50@1 MHz is about 128 ms, time for 32 interrupts
	LDY #0					; initial value and inner counter reset
	STY test
	CLI						; start counting!
; this provides timeout
it_1:
			NOP
			STY systmp		; add some delay
			INY
			BNE it_1
		DEX
		BNE it_1
; check timeout results for slow or fast
	SEI						; no more interrupts, but hardware still generates them (LED off)
	LDA #%01000000			; disable T1 interrupt for good measure
	STA Dmap+IER
	STA Cmap+IER
	BIT Dmap+T1CL
	BIT Cmap+T1CL			; just clear previous interrupts, why?
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
#ifdef	DEBUG
	LDA #%10001000			; PB3 means IRQ OK
	STA Dmap+IORB
	STA Cmap+IORB
#endif

; ***************************
; *** all OK, end of test ***
; ***************************

; bong sound, tell C from D thru beep codes and lock (just waiting for NMIs)
	SEI
	LDA #%11101110			; * CB2 back to hi, just in case
	STA Dmap+PCR
	STA Cmap+PCR
;	LDA #%00101110			; * desperately set CB2 as input?
;	STA Dmap+PCR
;	STA Cmap+PCR
	LDA #%11010000			; T1 free run (PB7 on), SR free, no latch
	STA Dmap+ACR
	STA Cmap+ACR			; shifting starts now (SR not yet loaded)
	LDA #<(t1ct/8)
	STA Dmap+T1CL
	STA Cmap+T1CL
	LDA #>(t1ct/8)			; *** placeholder 1 kHz
	STA Dmap+T1CH
	STA Cmap+T1CH
	LDA #0
	STA Dmap+T2CL
	STA Cmap+T2CL
	STA Dmap+T2CH
	STA Cmap+T2CH			; now pointing to T2CH, free run at max speed
	LDA #$FF				; max volume PWM
bvol:
#echo set aux cr needed?
; * needed here?
		LDY #%11010000		; T1 free run (PB7 on), SR free, no latch EEEEK
		STY Dmap+ACR
		STY Cmap+ACR		; * shifting starts now? (SR not yet loaded)
		LDX #$A0			; shorter envelope
		STA Dmap+VSR
		STA Cmap+VSR		; set PWM
#ifdef	DEBUG
		STA Dmap+IORB
		STA Cmap+IORB		; display current PWM pattern on LEDs
#endif
bloop:
				INY			; first iteration a bit shorter
				BNE bloop
			INX
			BNE bloop
		ASL					; one bit less
		BCS bvol
	LDA #%01000000			; T1 free run (but PB7 off EEEEK), no SR, no latch
	STA Dmap+ACR
	STA Cmap+ACR			; shifting starts now (SR not yet loaded)
	LDA #%10010000			; PB4 means all tests OK, also PB7 hi shuts speaker off
	STA Dmap+IORB
	STA Cmap+IORB			; this will shut speaker off
	LDA #%11101110			; * CB2 back to hi, just in case
	STA Dmap+PCR
	STA Cmap+PCR
	LDY #<nmi_test
	LDX #>nmi_test
	STY fw_nmi
	STX fw_nmi+1			; NMI will beep
lock:
	BRA lock				; stop here, this far

; ********************************************
; *** interrupt service and other routines ***
; ********************************************
isr:
	BIT Dmap+T1CL			; simpler way to acknowledge the T1 interrupt!
	BIT Cmap+T1CL
	INC test				; increment standard zeropage address (no longer DEC)
exit:
	RTI

nmi_test:
	PHA
	PHX
	PHY
	LDA #%11101110			; make sure CB2 is high
	STA Dmap+PCR
	STA Cmap+PCR			; update PCR (safer)
	LDA #$FF
	STA Dmap+DDRB
	STA Cmap+DDRB			; and PB is all output (safer)
	LDA #%01000000			; don't press NMI any more
	STA Dmap+IORB
	STA Cmap+IORB
	LDA #%11000000			; set PB7 square wave, no shift
	STA Dmap+ACR
	STA Cmap+ACR			; update ACR (safer)
	LDX #0					; eeeek
wait:
			INY
			BNE wait
		INX
		BNE wait
	LDA #%01000000			; back to continuous interrupts but no PB7 output
	STA Dmap+ACR
	STA Cmap+ACR			; update ACR (safer)
	LDA #%10111111			; make sure PB7 is hi, keep speaker off (PB0-5 green checked NMI)
	STA Dmap+IORB
	STA Cmap+IORB			; update PB7 (safer)
	PLY
	PLX
	PLA
	RTI

; *** standard panic, will make buzzing bursts instead of Durango's LED
panic:
	SEC						; at least one bit will flash
	EOR #$FF				; this is positive logic, BTW
	LDY #%11101110			; make sure CB2 is high
	STY Dmap+PCR
	STY Cmap+PCR			; update PCR (safer)
ploop:
			INY
			BNE ploop
		INX
		BNE ploop			; total cycle is ~326 ms @ 1 MHz
	ROL						; keep rotating pattern (cycle ~2.94 s)
	TAY						; must save pattern safely
	LDA #%01000000			; standard ACR config
	BCC no_buzz
		ORA #%10000000		; if C, then enable output
no_buzz:
	STA Dmap+ACR
	STA Cmap+ACR			; update ACR (safer)
	TYA
	BRA ploop				; not sure about A

; ************
; *** data ***
; ************

; *** bit position table ***
; INDEX =    0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
bit_l:
	.byt	$00, $01, $02, $04, $08, $10, $20, $40, $80, $00, $00, $00, $00, $00, $00, $00
;            -    A0   A1   A2   A3   A4   A5   A6   A7   A8   A9   AA   AB   AC   AD   AE (A14)
bit_h:
	.byt    $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $04, $08, $10, $20, $40

#ifndef	POCKET
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
#endif
