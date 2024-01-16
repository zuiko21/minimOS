; FULL test of Durango-X/S/R (ROMmable version, NMOS-savvy)
; now with v2 & TURBO support!
; (c) 2021-2024 Carlos J. Santisteban
; last modified 20230323-1820

; ****************************
; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202
	test	= 0
	posi	= $FB			; %11111011
	systmp	= $FC			; %11111100
	sysptr	= $FD			; %11111101
	himem	= $FF			; %11111111
	IO8mode	= $DF80
	IO8lf	= $DF88			; EEEEEEEK
	IOAen	= $DFA0
	IOBeep	= $DFB0
; ****************************

#ifndef	MULTIBOOT
* = $F400					; 3 KiB start address
; *** standard header ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Hardware test v2", 0	; C-string with filename @ [8], max 220 chars
;	.asc	"(comment)"		; optional C-string with comment after filename, filename+comment up to 220 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$2081			; 2.0b1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$9060			; time, 18.03
	.word	$5830			; date, 2024/1/16
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *** standard hardware test ***
#endif

; ******************
; *** test suite ***
; ******************
reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X specific stuff
#ifdef	HIRES
	LDA #$B0				; for testing
#else
	LDA #$38				; flag init and interrupt disable
#endif
	STA IO8mode				; set colour mode
	STA IOAen				; disable hardware interrupt (LED turns on)

; ** zeropage test **
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
		STX IOBeep			; make beep at 158t ~4.86 kHz
		BNE zp_1			; complete page (3, post 13t)
	BEQ zp_ok
zp_bad:
		LDA #$FF			; *** bad ZP, LED code = %1 00000000 ***
		JMP panic			; panic if failed
zp_ok:

; * simple mirroring test *
; probe responding size first
	LDY #127				; max 32 KB, also a fairly good offset EEEEK
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
;	INC						; CMOS only, instead of addition below
	CLC
	ADC #1
#endif
mt_6:
		INY					; one more bit...
		LSR					; ...and half the memory
		BCC mt_6
	STY posi				; X & Y cannot reach this in address lines test

; ** address lines test **
; X=bubble bit, Y=base bit (An+1)
; written value =$XY
; first write all values
;	STZ 0					; zero is a special case, as no bits are used
	LDA #0
	STA 0

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
;			STA (sysptr)	; CMOS only instead of 3 lines below
			LDY #0
			STA (sysptr), Y
			LDY systmp		; easily recovered writing $XY instead of $YX

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
;			CMP (sysptr)	; CMOS only
;				BNE at_bad
			LDY #0
			CMP (sysptr), Y
				BNE at_bad
			LDY systmp		; easily recovered writing $XY instead of $YX

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
		LDA #%10111111		; *** bad address lines, LED code = %1 01000000 ***
		JMP panic
addr_ok:

; ** RAM test **
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

; ** ROM test **
; unlike previous version, should apply Fletcher-16 algorithm as usual
; based on CHK_SUM, verify Fletcher-16 sum v0.9.6a4

; usually expects signature value at $FFDE(sum)-$FFDF(chk) for a final checksum of 0 (assuming ends at $FFFF)
; just reserve a couple of bytes for checksum matching

; * declare some temporary vars *
sum		= systmp			; included as output parameters
chk		= posi				; sum of sums

; *** compute checksum *** initial setup is 12b, 16t
	LDX #>reset				; start page as per interface (MUST be page-aligned!)
	STX sysptr+1			; temporary ZP pointer
	LDY #0					; this will reset index too
	STY sysptr
	STY sum					; reset values too
	STY chk
; *** main loop *** original version takes 20b, 426kt for 16KB ~0.28s on Durango-X
cs_loop:
			LDA (sysptr), Y	; get ROM byte (5+2)
			CLC
			ADC sum			; add to previous (3+3+2)
			STA sum
			CLC
			ADC chk			; compute sum of sums too (3+3+2)
			STA chk
			INY
			BNE cs_loop		; complete one page (3..., 6655t per page)
; *** MUST skip IO page (usually $DF), very little penalty though ***
		CPX #$DE			; just before I/O space?
		BNE f16_noio
			INX				; next INX will skip it!
f16_noio:
		INX					; next page (2)
		STX sysptr+1		; update pointer (3)
;		CPX af_pg			; VRAM is the limit for downloaded modules, otherwise 0
		BNE cs_loop			; will end at last address! (3...)
; *** now compare computed checksum with ZERO *** 4b
;	LDA chk					; this is the stored value in A, saves two bytes
	ORA sum					; any non-zero bit will show up
	BEQ rom_ok				; otherwise, all OK!
; show minibanner to tell this from RAM error (no display)
rom_bad:
		LDX #6				; max. horizontal offset
ck_b:
			LDA rom_b, X	; copy banner data into screen
			STA $6F19, X
			LDA rom_b+7, X
			STA $6F59, X
			LDA rom_b+14, X
			STA $6F99, X
			DEX
			BPL ck_b		; no offset!
		LDA #%10100000		; *** bad ROM, LED code = %1 01011111 ***
;		JMP panic

rom_ok:
; show banner if ROM checked OK (worth using RLE?)
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

; ** why not add a video mode flags tester? **
	LDX #0
	STX posi				; will store unresponding bits
;	LDY IO8mode				; save previous mode
mt_loop:
		STX IO8mode			; try setting this mode...
		TXA
		EOR IO8mode			; ...and compare to what is read...
		ORA posi
		STA posi			; ...storing differences
		INX
		BNE mt_loop
#ifdef	HIRES
	LDY #$B0				; for testing
#else
	LDY #$38				; * restore usual video mode, extra LED off *
#endif
	STY IO8mode				; back to original mode
	LDX #7					; maximum bit offset
mt_disp:
		LSR posi			; extract rightmost bit into C
		LDA #1				; green for responding bits...
		ADC #0				; ...or red for non-responding
		CPX #4				; rightmost 4 are not essential
		BCC mt_ess
			ORA #8			; add blue to non-essential
mt_ess:
		STA $66E8, X		; display dots to the right
;		BIT #2				; recheck non-responding... CMOS!!!
		TAY					; need to save A
		AND #2

		BEQ mt_bitok
			TYA				; retrieve A, NMOS only
			STA $6768, X	; mark them down again for clarity
mt_bitok:
		DEX
		BPL mt_disp

; ** next is testing for HSYNC and VSYNC ** must adapt to v1, v2, TURBO and EIA!
; print initial GREEN banner
	LDX #2					; max. offset
lf_l:
		LDA sync_b, X		; put banner data...
		STA $6680, X		; ...in appropriate screen place
		LDA sync_b+3, X
		STA $66C0, X
		LDA sync_b+6, X
		STA $6700, X
		LDA sync_b+9, X
		STA $6740, X
		DEX
		BPL lf_l			; note offset-avoiding BPL
; is there any detected VSYNC?
	LDX #25					; each iteration is 12t, X cycles every 3075t ~2 ms
	LDY #2					; VBLANK takes ~3.6 ms, so one iteration is ~10% shorter for ~3.8 ms
vsync:
		INX					; (2)
		BNE vcont			; count cycles... (3...)
			DEY
			BEQ vtime		; up to ~3.8 ms
vcont:
		BIT IO8lf			; check VBLANK (4)
		BVS vsync			; wait until sync ends (3)
	LDY #9					; vertical display is ~16.3 ms, X cycles every ~2 ms...
	LDX #192				; ...so make first iteration shorter (by ~1.5 ms)
vden:
		INX					; (2)
		BNE vdisp			; count cycles... (3...)
			DEY
			BEQ vtime2		; up to ~16.5 ms
vdisp:
		BIT IO8lf			; check VBLANK (4)
		BVC vden			; wait until vertical display ends
; if arrived here, VSYNC is at least not exceedingly slow
; let's check at least the presence of HSYNC
	LDY #3					; loop takes 11t, HBLANK is 34, thus limit at ~33t (overhead allows it)
hsync:
		DEY					; (2)
			BEQ htime		; timeout at ~44t (2)
		BIT IO8lf			; check HBLANK (4)
		BMI hsync			; until sync ends (3)
	LDY #6					; loop takes 11t, display is 64, thus limit at ~66t
hden:
		DEY					; (2)
			BEQ htime2		; timeout at ~44t (2)
		BIT IO8lf			; check HBLANK (4)
		BMI hden			; until sync ends (3)
	LDY #3					; loop takes 11t, HBLANK is 34, thus limit at ~33t (overhead allows it)
; and measure hsync again, just for the sake of it
hmeas:
		DEY					; (2)
			BEQ htime3		; timeout at ~44t (2)
		BIT IO8lf			; check HBLANK (4)
		BMI hmeas			; until sync ends (3)
; there's HSYNC at reasonable speed
; now wait for VSYNC to end and count visible lines
	LDX #0					; line counter
vwait:
		BIT IO8lf
		BVS vwait
lcount:
			BIT IO8lf
			BPL lcount		; still within visible part of the line
		INX					; one more line
lend:
			BIT IO8lf
			BMI lend		; wait until the end of the H-blanking...
		BVC lcount			; ...while not at V-blank
; all visible lines are done, should be 256!
	TXA						; quickly check
	BEQ sync_ok				; 0 = 256, hopefully!
; otherwise we have a wrong number of lines!
bad_count:
	LDY #3					; max offset
bc_l:
		LDX lof, Y			; get line offset
		LDA $6682, X		; position of 'F'
		STA posi
		ASL
		ORA posi
		STA $6682, X		; will turn green into orange
		DEY
		BPL bc_l
	LDA #$BB
	STA $67C2				; fuchsia underline
	BMI sync_ok				; probably NTSC, just a warning, or...
;	LDA #%11000000			; *** bad VSYNC, LED code = %1 00111111 ***
;	JMP panic
; or VSYNC is way off (or not reported)
vtime:
vtime2:
	LDY #3					; max offset
vs_l:
		LDX lof, Y			; get line offset
		ASL $6682, X		; position of 'F', will turn into red
		DEY
		BPL vs_l
	LDA #$FF
	STA $67C2				; white underline
; this is serious, thus panic
	LDA #%11000000			; *** bad VSYNC, LED code = %1 00111111 ***
	JMP panic

; or HSYNC is way off (or not reported, no big deal, though)
htime:
htime2:
htime3:
	LDY #3					; max offset
hs_l:
		LDX lof, Y			; get line offset
		LDA $6680, X		; position of 'L'
		STA posi
		ASL
		ORA posi
		STA $6680, X		; will turn green into orange (warning)
		DEY
		BPL hs_l
	LDA #$FF
	STA $67C0				; white underline
;	LDA #%10010010			; *** bad HSYNC, LED code = %1 01101101 ***
;	JMP panic
sync_ok:

; * NMI test *
; wait a few seconds for NMI
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_nmi				; standard-ish NMI vector
	STX fw_nmi+1
; print minibanner
	LDX #5					; max. horizontal offset
	STX IOAen				; hardware interrupt enable (LED goes off), will be needed for IRQ test
nt_b:
		LDA nmi_b, X		; copy banner data into screen
		STA $6B00, X
		LDA nmi_b+6, X
		STA $6B40, X
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
			STA $6B45, X	; place 'dot', note offset as zero does not count
			DEX
			BNE nt_4

; ** IRQ test **
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
#ifdef	HIRES
	LDA #$F0				; HIRES inverse, for testing
#else
	LDA #$78				; colour, inverse, RGB
#endif
	STA IO8mode				; eeeeek
; interrupt setup
	LDY #<isr				; ISR address
	LDX #>isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
	LDY #0					; initial value and inner counter reset
	STY test
; assume HW interrupt is on
	LDX #154				; about 129 ms, time for 32 interrupts v1 (28 for v2, 14 for TURBO)
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
#ifdef	HIRES
	LDX #$B0				; for testing
#else
	LDX #$38				; can no longer be zero
#endif
	STX IO8mode
; display dots indicating how many times IRQ happened
	LDX test				; using amount as index
		BEQ it_slow			; did not respond at all! eeeeeek
	LDA #$01				; nice mid green value in all modes
	STA $6FDF				; place index dot @32 eeeeeek
	STA $6FDD				; ** v2 ** @28 too
	ASL						; ** v2 ** turn into red
	STA $6FD6				; ** v2 ** mark for TURBO
	LDA #$0F				; nice white value in all modes
it_2:
		STA $703F, X		; place 'dot', note offsets
		DEX
		BNE it_2
; compare results
	LDA test
	CMP #13					; one less (for TURBO) is acceptable ** v2
	BCS it_3				; <13 is slow ** v2
it_slow:
		LDA #%00011111		; *** slow IRQ, LED code = %1 11100000 ***
		JMP panic
it_3:
	CMP #34					; up to 33 is fine (for v1)
	BCC it_wt				; 13-33 accepted, >33 is fast
it_fast:
		LDA #%10101011		; *** fast IRQ, LED code = %1 01010100 ***
		JMP panic
it_wt:
	CMP #16					; 15 is max count for TURBO ** v2
	BCC it_ok				; TURBO is OK ** v2
		CMP #27				; 27 is min count ** for v2
		BCS it_ok			; OK ** for v2
			LDA #%00110011	; *** between ** TURBO and standard values, LED code = %1 11001100 ***
it_ok:

; ***************************
; *** all OK, end of test ***
; ***************************

; sweep sound, print OK banner and lock
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
; sound done, may check CPU type too (from David Empson work)
	LDY #$00				; by default, NMOS 6502 (0)
	SED						; decimal mode
	LDA #$99				; load highest BCD number
	CLC						; prepare to add
	ADC #$01				; will wrap around in Decimal mode
	CLD						; back to binary
		BMI cck_set			; NMOS, N flag not affected by decimal add
	LDY #$03				; assume now '816 (3)
	LDX #$00				; sets Z temporarily
	.byt	$BB				; TYX, 65816 instruction will clear Z, NOP on all 65C02s will not
		BNE cck_set			; branch only on 65802/816
	DEY						; try now with Rockwell (2)
	STY $EA					; store '2' there, irrelevant contents
	.byt	$17, $EA		; RMB1 $EA, Rockwell R65C02 instruction will reset stored value, otherwise NOPs
	CPY $EA					; location $EA unaffected on other 65C02s
		BNE cck_set			; branch only on Rockwell R65C02 (test CPY)
	DEY						; revert to generic 65C02 (1)
		BNE cck_set			; cannot be zero, thus no need for BRA
cck_set:
	TYA						; A = 0...3 (NMOS/CMOS/Rockwell/816)
; display minibanner with CPU type, 5x16 pixels each
	LDX #7					; max. offset
	ASL
	ASL
	ASL			; times 8
	STA test
	ASL
	ASL			; times 32
	ADC test	; plus 8x (C was clear), it's times 40
	ADC #7		; base offset (C should be clear too)
	TAY			; reading index
cpu_loop:
		LDA cpu_n, Y
		STA $7400, X
		LDA cpu_n+8, Y
		STA $7440, X
		LDA cpu_n+16, Y
		STA $7480, X
		LDA cpu_n+24, Y
		STA $74C0, X
		LDA cpu_n+32, Y
		STA $7500, X
		DEY
		DEX
		BPL cpu_loop

; all ended, print GREEN banner
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
#ifdef	HIRES
	LDA #$B4				; extre LED on HIRES, for testing
#else
	LDA #$3C				; turn on extra LED
#endif
	STA IO8mode

; *** all checked OK, wait for NMI press to show delay adjust screen ***
#ifndef	MULTIBOOT
	LDX #>testcard
	LDY #<testcard
#else
	LDX #>switcher			; full-suite task switcher!
	LDY #<switcher
#endif
	STX fw_nmi+1			; set NMI vector to test card
	STY fw_nmi

all_ok:
	JMP all_ok				; final lock (X=$FF)

; *********************
; *** panic routine ***
; *********************
panic:
; *** display 9 bit pattern on ERROR LED *** and FLASH screen
	CLC						; at least one bit will flash
ploop:
			NOP
			INY
			BNE ploop
		INX
		BNE ploop			; total cycle is ~300 ms
	ROL						; keep rotating pattern (cycle ~2.7 s)
	STA IOAen				; LED is on only when D0=0
	TAY
	AND #%00000001			; keep LED bit...
	BNE fl_off				; ...which works the opposite...
		LDA IO8mode			; ...and set that video flag
		ORA #64
		BNE fl_set
fl_off:
	LDA IO8mode				; otherwise clear inverse mode
	AND #%10111111
fl_set:
	ORA #%00001000			; enable RGB, just in case
	STA IO8mode				; set inverse flag according to bit
	TYA
	BNE ploop				; A is NEVER zero

#ifndef	MULTIBOOT
testcard:
; *** display test pattern for video delay adjustment ***
; minimal hardware init
	LDA #$38				; systmp mode, true video, screen 3, RGB enabled, extra LED off!
	STA IO8mode				; set hardware mode register
; init variables
	LDX #$60				; screen 3 address
	LDY #0
	STY sysptr				; set pointer
	STX sysptr+1
	TYA						; initial value is 0
; clear screen, just in case
clear:
		STA (sysptr), Y
		INY
		BNE clear
			INC sysptr+1
		BPL clear
	LDX #$60				; restore pointer
	STX sysptr+1
; finish init
	LDA #%11110000			; white at MSB
	STA systmp				; preset first ink systmp
; pattern loop
loop:
		LDA systmp			; left pixel systmp
		LDX #6				; six wide patterns... (2+4)
lwide:
			STA (sysptr), Y	; set this pattern
			INY				; leave one or three blank bytes
			INY
			CPX #5			; within first half?
			BCC lskip
				INY			; skip three then
				INY
lskip:
			DEX
			BNE lwide
tight:
			STA (sysptr), Y	; set all bytes this way
			INY
			INX				; this counter was reset, now goes up
			CPX #16			; middle of the pattern?
			BNE top_t
				LSR			; if so, shift to right pixel
				LSR
				LSR
				LSR
top_t:
			CPX #32			; end of tight pattern?
			BNE tight
		LDX #6				; six wide patterns again
rwide:
			STA (sysptr), Y	; set this pattern
			INY				; leave one or three blank bytes
			INY
			CPX #3			; within last half?
			BCS rskip
				INY			; skip three then
				INY
rskip:
			DEX
			BNE rwide
		TYA					; check offset
		BNE loop
		INC sysptr+1		; next page is big chunks
; enable delay test
		LDA systmp			; get MSN
		LSR					; turn into LSN
		LSR
		LSR
		LSR
		ORA systmp			; both pixels
		LDY #31				; half line
lhalf:
			STA (sysptr), Y
			DEY
			BPL lhalf
		LDY #64				; next raster to the left
		STA (sysptr), Y
		LDY #160			; right half, third raster
rhalf:
			STA (sysptr), Y
			INY
			CPY #192		; until end of raster
			BNE rhalf
		LDY #224			; middle of last raster
		STA (sysptr), Y
		INY
		STA (sysptr), Y		; two bytes
; change systmp and advance page
		INC sysptr+1
		LDY #0				; eeeeek
		LDA systmp
		SEC
		SBC #$10			; eeeeeeek, it's MSN
		STA systmp
		BNE loop			; continue (black is not used)
	JMP all_ok 
#endif

test_end: 

; ********************************************
; *** miscelaneous stuff, may be elsewhere ***
; ********************************************

; *** interrupt handlers *** could be elsewhere, ROM only
#ifndef	MULTIBOOT
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)
#endif

; *** interrupt routine (for both IRQ and NMI test) *** could be elsewhere
isr:
	NOP						; make sure it takes over 13-15 µsec
	INC test				; increment standard zeropage address (no longer DEC)
	NOP
	NOP
exit:
	RTI

; *** delay routine *** (may be elsewhere)
delay:
	JSR dl_1				; (12)
	JSR dl_1				; (12)
	JSR dl_1				; (12... +12 total overhead =48)
dl_1:
	RTS						; for timeout counters

; *** *** data *** ***

; *** mini banners *** could be elsewhere
sync_b:
	.byt	$10, $00, $11					; mid green 'LF'
	.byt	$10, $00, $10
	.byt	$10, $00, $11
	.byt	$11, $00, $10
nmi_b:
	.byt	$DD, $0D, $0D, $D0, $DD, $0D	; cyan 'NMI'
	.byt	$D0, $DD, $0D, $0D, $0D, $0D
irq_b:
	.byt	$60, $66, $60, $66, $60			; brick colour 'IRQ'
	.byt	$60, $66, $00, $60, $60
	.byt	$60, $60, $60, $66, $06
ok_b:
	.byt	$55, $50, $50, $50				; green 'OK'
	.byt	$50, $50, $55, $00
	.byt	$55, $50, $50, $50
rom_b:
	.byt	$DD, $D0, $DD, $D0, $DD, $0D, $D0	; red 'ROM' (actually cyan as most of the time will show in inverse)
	.byt	$DD, $00, $D0, $D0, $D0, $D0, $D0
	.byt	$D0, $D0, $DD, $D0, $D0, $00, $D0

cpu_n:
	.byt	$22, $20, $22, $20, $22, $20, $22, $20	; red (as in "not supported") 6502
	.byt	$20, $00, $20, $00, $20, $20, $00, $20
	.byt	$22, $20, $22, $20, $20, $20, $22, $20
	.byt	$20, $20, $00, $20, $20, $20, $20, $00
	.byt	$22, $20, $22, $20, $22, $20, $22, $20

cpu_c:
	.byt	$FF, $F0, $FF, $0F, $F0, $FF, $F0, $FF	; white 65C02 @ +40
	.byt	$F0, $00, $F0, $0F, $00, $F0, $F0, $0F
	.byt	$FF, $F0, $FF, $0F, $00, $F0, $F0, $FF
	.byt	$F0, $F0, $0F, $0F, $00, $F0, $F0, $F0
	.byt	$FF, $F0, $FF, $0F, $F0, $FF, $F0, $FF

cpu_r:
	.byt	$FF, $00, $F0, $FF, $0F, $FF, $0F, $F0	; white R'C02 @ +80
	.byt	$FF, $F0, $F0, $F0, $0F, $0F, $00, $F0
	.byt	$FF, $00, $00, $F0, $0F, $0F, $0F, $F0
	.byt	$F0, $F0, $00, $F0, $0F, $0F, $0F, $00
	.byt	$F0, $F0, $00, $FF, $0F, $FF, $0F, $F0

cpu_16:
	.byt	$AA, $A0, $AA, $0A, $AA, $0A, $0A, $AA	; pink 65816 @ +120
	.byt	$A0, $00, $A0, $0A, $0A, $0A, $0A, $00
	.byt	$AA, $A0, $AA, $0A, $AA, $0A, $0A, $AA
	.byt	$A0, $A0, $0A, $0A, $0A, $0A, $0A, $0A
	.byt	$AA, $A0, $AA, $0A, $AA, $0A, $0A, $AA

; *** bit position table ***
; INDEX =    0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
bit_l:
	.byt	$00, $01, $02, $04, $08, $10, $20, $40, $80, $00, $00, $00, $00, $00, $00, $00
;            -    A0   A1   A2   A3   A4   A5   A6   A7   A8   A9   AA   AB   AC   AD   AE (A14)
bit_h:
	.byt    $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $04, $08, $10, $20, $40

; *** line offset table ***
lof:
	.byt	$00, $40, $80, $C0

misc_end:

; *** banner data *** 1 Kbyte raw file!
banner:
	.bin	0, 1024, "../../other/data/durango-x.sv"
pic_end:

; ****************************************
; *** padding, ID and hardware vectors ***
; ****************************************

#ifndef	MULTIBOOT
	.dsb	$FFD6-*, $FF	; padding

	.asc	"DmOS"			; Durango-X cartridge signature
	.word	$FFFF			; extra padding
	.word	$FFFF
	.word	0				; this will hold checksum at $FFDE-$FFDF

	.byt	$FF
	JMP ($FFFC)				; devCart support!

	.dsb $FFFA-*, $FF

	.word	nmi
	.word	reset
	.word	irq
#endif
