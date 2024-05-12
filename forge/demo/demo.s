; Twist-and-Scroll demo for Durango-X
; (c) 2024 Carlos J. Santisteban
; Last modified 20240512-1122

; ****************************
; *** standard definitions ***
	fw_irq	= $0200
	fw_nmi	= $0202

	IO8mode	= $DF80
	IO8lf	= $DF88			; EEEEEEEK
	IOAen	= $DFA0
	IOBeep	= $DFB0
	screen1	= $2000
	scr_shf	= $2400			; shifted logo address
	screen2	= $4000
	screen3	= $6000
	scrl	= $7800			; top position of scrolled text
; *** memory usage ***
	test	= 0
	himem	= test+2
	src		= himem+1
	ptr		= src+2
	posi	= ptr+2
	swp_ct	= posi+1
	temp	= swp_ct+1
	count	= temp+1
	sh_pt	= count+1
	s_old	= sh_pt+2
	s_new	= s_old+1
	colidx	= s_new+1
	text	= colidx+1
	sh_ix	= text+2
	sqk_par	= sh_ix+1
	glyph	= sqk_par+3
	colour	= glyph+8
	base	= colour+1		; temporary pointer
	irq_cnt	= base+2
	sh_of	= irq_cnt+1
	tasks	= sh_of+1
	tw_ix	= tasks+1
	END	= tw_ix+1
; ****************************

* = $8000					; this is gonna be big...

; ***********************
; *** standard header ***
; ***********************
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Twist'n'Scroll 1.0a11b"		; C-string with filename @ [8], max 220 chars
#ifdef	CPUMETER
#echo	CPU meter
	.asc	" (with CPU meter)"			; optional C-string with comment after filename, filename+comment up to 220 chars
#endif
#ifdef	VERSION2
#echo	v2
	.asc	" for Durango v2"
#endif
#ifdef	TURBO
#echo	"TURBO"
	.asc	" TURBO"
#endif
	.byt	0, 0			; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$100B			; 1.0a11		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
#echo $100b-twist-b
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5800			; time, 11.00		0101 1-000 000-0 0000
	.word	$58AC			; date, 2024/5/12	0101 100-0 101-0 1100
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; ******************
; *** test suite *** FAKE
; ******************
reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X specific stuff
	LDA #$38				; flag init and interrupt disable
	STA IO8mode				; set colour mode
	STA IOAen				; disable hardware interrupt (LED turns on)
; disable NMI for safety
	LDY #<exit
	LDA #>exit
	STY fw_nmi
	STA fw_nmi+1
; ** zeropage test **
; make high pitched chirp during test (not actually done, just run for timing reasons)
	LDX #<test				; 6510-savvy...
zp_1:
		TXA
		STA 0, X			; try storing address itself (2+4)
		CMP 0, X			; properly stored? (4+2)
		NOP					;	BNE zp_bad
		LDA #0				; A=0 during whole ZP test (2)
		STA 0, X			; clear byte (4)
		CMP 0, X			; must be clear right now! sets carry too (4+2)
		NOP					;	BNE zp_bad
		LDY #10				; number of shifts +1 (2, 26t up here)
zp_2:
			DEY				; avoid infinite loop (2+2)
			NOP				;	BEQ zp_bad
			ROL 0, X		; rotate (6)
			BNE zp_2		; only zero at the end (3...)
			NOP				;BCC zp_bad		; C must be set at the end (...or 5 last time) (total inner loop = 119t)
		CPY #1				; expected value after 9 shifts (2+2)
		NOP					;	BNE zp_bad
		INX					; next address (2+4)
		STX IOBeep			; make beep at 158t ~4.86 kHz, over 11 kHz in TURBO!
		BNE zp_1			; complete page (3, post 13t)
;	BEQ zp_ok
; don't care about errors

; * no mirroring/address lines test, as it's quite fast and barely noticeable *
	LDA #$7F				; last RAM page
	STA himem

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
			NOP				;BNE ram_bad	; don't care
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
;	BCC ram_ok				; if arrived here SECOND time, C is CLEAR and A=0

; ** ROM test ** NOPE

; show banner if ROM checked OK (now using RLE)
	LDY #<banner
	LDX #>banner
	STY src
	STX src+1				; set origin pointer
	LDY #<screen3			; actually 0
	LDX #>screen3			; $60
	STY ptr
	STX ptr+1				; set destination pointer
	JSR rle_loop			; display picture

; ** why not add a video mode flags tester? **
	LDX #0
	STX posi				; will store unresponding bits
mt_loop:
		STX IO8mode			; try setting this mode...
		TXA
		EOR IO8mode			; ...and compare to what is read...
		ORA posi
		STA posi			; ...storing differences
		INX
		BNE mt_loop
	LDY #$38				; * restore usual video mode, extra LED off *
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
		BIT #2				; recheck non-responding... CMOS!!!
		BEQ mt_bitok
			STA $6768, X	; mark them down again for clarity
mt_bitok:
		DEX
		BPL mt_disp

; ** next is testing for HSYNC and VSYNC ** nope, just display OK result 
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

; * NMI test * just for the sake of it, as it's the only responsive thing
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
; disable NMI again for safer IRQ test (prepare task switcher)
	LDY #<tswitch
	LDX #>tswitch			; eeek
	STY fw_nmi				; standard-ish NMI vector
	STX fw_nmi+1
; display dots indicating how many times was called (button bounce)
nt_3:
	LDX test				; using amount as index
	BEQ irq_test			; did not respond, don't bother printing dots EEEEEEEK
		LDA #$0F			; nice white value in all modes
nt_4:
			STA $6B45, X	; place 'dot', note offset as zero does not count
			DEX
			BNE nt_4

; ** IRQ test ** fake
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
	LDA #$78				; colour, inverse, RGB
	STA IO8mode				; eeeeek
; interrupt setup * nope
; assume HW interrupt is on
	LDX #154				; about 129 ms, time for 32 interrupts v1
; this provides timeout
it_1:
			INY
			BNE it_1
		DEX
		BNE it_1
; back to true video
	LDX #$38
	STX IO8mode
; display dots indicating how many times IRQ happened
	LDX #32					; expected value eeeek
	LDA #$01				; nice mid green value in all modes
	STA $6FDF				; place index dot @32 eeeeeek
	LDA #$0F				; nice white value in all modes
it_2:
		STA $703F, X		; place 'dot', note offsets
		DEX
		BNE it_2
; compare results * nope

; ***************************
; *** all OK, end of test ***
; ***************************

; sweep sound, print OK banner and lock
	STX swp_ct				; sweep counter
	TXA						; X known to be zero, again
sweep:
		LDX #8				; sound length in half-cycles
beep_l:
			TAY				; determines frequency (2)
			STX IOBeep		; send X's LSB to beeper (4)
rb_zi:
#ifdef	TURBO
				STY temp
				STY temp
				NOP			; double loop delay
#endif
				STY temp	; small delay for 1.536 MHz! (y*3)
				DEY			; count pulse length (y*2)
				BNE rb_zi	; stay this way for a while (y*3-1)
			DEX				; toggles even/odd number (2)
			BNE beep_l		; new half cycle (3)
		STX IOBeep			; turn off the beeper!
		LDA swp_ct			; period goes down, freq. goes up
		SEC
		SBC #4				; frequency change rate
		STA swp_ct
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
	STA temp
	ASL
	ASL			; times 32
	ADC temp	; plus 8x (C was clear), it's times 40
	ADC #7		; base offset (C should be clear too)
	TAY			; reading index
cpu_loop:
		LDA cpu_n, Y
		STA $7300, X
		LDA cpu_n+8, Y
		STA $7340, X
		LDA cpu_n+16, Y
		STA $7380, X
		LDA cpu_n+24, Y
		STA $73C0, X
		LDA cpu_n+32, Y
		STA $7400, X
		DEY
		DEX
		BPL cpu_loop

; all ended, print GREEN banner
	LDX #3					; max. offset
ok_l:
		LDA ok_b, X			; put banner data...
		STA $76DC, X		; ...in appropriate screen place
		LDA ok_b+4, X
		STA $771C, X
		LDA ok_b+8, X
		STA $775C, X
		DEX
		BPL ok_l			; note offset-avoiding BPL
	LDA #$3C				; turn on extra LED
	STA IO8mode

; ***************************
; *** now the fun begins! ***
; ***************************

; decompress the standby picture on screen2
	LDY #<standby
	LDX #>standby
	STY src
	STX src+1				; set origin pointer
	LDY #<screen2			; actually 0
	LDX #>screen2			; $40
	STY ptr
	STX ptr+1				; set destination pointer
	JSR rle_loop			; decompress picture off-screen
; decompress the SMPTE bars on screen1
	LDY #<smpte
	LDX #>smpte
	STY src
	STX src+1				; set origin pointer
	LDY #<screen1			; actually 0
	LDX #>screen1			; $20
	STY ptr
	STX ptr+1				; set destination pointer
	JSR rle_loop			; decompress picture off-screen

; do some glitching effects *** TBD

	LDA #%00011000			; screen 1
	STA IO8mode				; SMPTE is visible
; * play 1 kHz for a couple of seconds (adjusted for 1.536 MHz) *
; toggle every 500µs means 768 cycles (875 for v2)
	LDY #0					; reset timer
	LDA #32
	STA count				; will do 32x ~ 4 s
bp_rpt:
		NOP					; (2) for timing accuracy
#ifdef	VERSION2
		NOP					; (2) v2 only
		LDX #172			; (2) v2 needs 172, as 172x5+15 = 875
#else
		LDX #151			; (2) 151x5+13 = 768!
#endif
bp_loop:
#ifdef	TURBO
			STX temp
			NOP				; double loop delay
#endif
			DEX
			BNE bp_loop		; 5t per iteration (needs ~153 of them)
		INY					; (2)
		STY IOBeep			; (4)
		BNE bp_rpt			; (mostly 3)
	DEC count
		BNE bp_rpt
; decompress 'just kidding' screen over current one
	LDY #<kidding
	LDX #>kidding
	STY src
	STX src+1				; set origin pointer
	LDY #<screen1			; actually 0
	LDX #>screen1			; $20
	STY ptr
	STX ptr+1				; set destination pointer
	JSR rle_loop			; decompress picture off-screen
; wait some time, maybe with pacman death sound
; first sqweak
	LDA #99					; initial freq
	LDY #88					; top freq
	LDX #36					; length
	JSR squeak				; actual routine
; second sqweak
	LDA #118
	LDY #105
	LDX #30
	JSR squeak
; third sqweak
	LDA #132
	LDY #117
	LDX #27
	JSR squeak
; fourth sqweak
	LDA #148
	LDY #132
	LDX #24
	JSR squeak
; fifth sqweak
	LDA #176
	LDY #157
	LDX #20
	JSR squeak
; last two sweeps
	LDA #2
d_rpt:
	PHA						; iteration
	LDA #255
	STA count
dth_sw:
		LDX #10
		JSR m_beep
		LDA count
		SEC
		SBC #24
		STA count
		CMP #15
		BCS dth_sw
	LDA #4
	JSR ms20				; ~80 ms delay, no longer 75
; next iteration
	PLA
	DEC						; *** CMOS ***
	BNE d_rpt

; make copies of Durango·X logo into SMPTE screen, both normal and shifted by one pixel
; both copies integrated!
	LDY #<screen1			; actually 0
	LDA #>screen1			; $20
	STY ptr
	STA ptr+1				; set destination pointer
;	LDY #<scr_shf			; actually 0 as well
	LDA #>scr_shf			; four pages below (1 KB, $24)
	STY sh_pt
	STA sh_pt+1				; pointer to shifted copy
;	LDY #<screen3
	LDX #>screen3
	STY src					; origin LSB
	STZ s_old
cp_pg:
;		LDY #0
		STX src+1			; set origin pointer in full
cp_loop:
			LDA (src), Y
			STA (ptr), Y	; raw copy
			STZ s_new
			LSR				; extract rightmost bit...
			ROR s_new		; ...and insert here
			LSR
			ROR s_new
			LSR
			ROR s_new
			LSR
			ROR s_new
			ORA s_old
			STA (sh_pt), Y	; MSB plus previous LSB
			LDA s_new
			STA s_old		; cycle extracted nybble
			INY
			BNE cp_loop
		INC ptr+1			; next page
		INC sh_pt+1			; eeeeek
		INX
		CPX #$64			; logo size is four pages (assume screen3 = $6000)
		BNE cp_pg
; *** get ready to launch concurrent tasks ***
	LDA #$38
	STA IO8mode				; standard screen for scroller
; prepare text scroller
	STZ colidx				; reset colour index
	STZ count				; will trigger character load
	LDY #<(msg-1)
	LDX #>(msg-1)			; back to text start, note points to byte before as always loads next char
	STY text
	STX text+1				; restore pointer
; prepare animation
	LDA #$FF				; don't loose first frame!
	STA sh_ix				; reset animation cursor
; prepare sound *** TBD

; set interrupt task!
	LDA #5					; next screen swap will be 5 IRQs away
	STA irq_cnt
	LDY #<player
	LDX #>player			; alternative task address
	STY fw_irq
	STX fw_irq+1
	CLI						; enable it!
	STZ tasks				; enable all tasks for scheduler

; **************************
; *** multithreaded loop ***
; **************************
wait:
			BIT IO8lf		; wait for vertical blanking
			BVC wait
#ifdef	CPUMETER
		LDA #$78			;inverse
		STA IO8mode
#endif
		BIT tasks			; controlled scheduler
		BVS no_scr
			JSR scroller	; execute this thread (if enabled)
no_scr:
		BIT tasks			; recheck
		BMI no_shf
			JSR shifter		; and animation as well (if enabled)
no_shf:
#ifdef	CPUMETER
		LDA #$38			; normal
		STA IO8mode
#endif
		BRA wait			; forever!

; ********************************************
; *** miscelaneous stuff, may be elsewhere ***
; ********************************************

; *** interrupt handlers *** could be elsewhere, ROM only
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)

; *** interrupt routine (for NMI test) *** could be elsewhere
isr:
	NOP						; make sure it takes over 13-15 µsec
	INC test				; increment standard zeropage address (no longer DEC)
	NOP
	NOP
exit:
	RTI

; *** final ISR ***
player:
	PHA
	DEC irq_cnt				; one less to go
	BNE do_isr				; if not each 5, do regular stuff
		LDA IO8mode
		AND #%11100000			; else will switch into screen2
		ORA #%00001000			; RGB mode
		STA IO8mode
		LDA #5				; next screen swap will be 5 IRQs away
		STA irq_cnt
do_isr:
; regular task *** before a sound player is made, take some delay
i_delay:
		INC
		BNE i_delay
; restore things
	LDA IO8mode
	AND #%11000000			; will switch back into screen3
	ORA #%00111000			; RGB mode
	STA IO8mode
	PLA
	RTI

; *** task switcher ***
tswitch:
.byt$cb
	PHA
	LDA tasks				; task disable register (1=OFF)
	CLC
	ADC #64					; will just use bits 6-7, as V & N flags for BIT opcode
sta$6d00
	STA tasks
	PLA
	RTI

; *** delay routine *** (may be elsewhere)
delay:
	JSR dl_1				; (12)
	JSR dl_1				; (12)
	JSR dl_1				; (12... +12 total overhead =48)
dl_1:
	RTS						; for timeout counters

; *** delay ~20A ms *** assuming 1.536 MHz clock! NEW
ms20:
	LDX #11					; computed iterations for a 20ms delay
	LDY #44					; first iteration takes ~0.17 the time, actually ~10.17 iterations
m20d:
#ifdef	TURBO
			STY temp
			NOP				; double loop delay
#endif
			DEY				; inner loop (2y)x
			BNE m20d		; (3y-1)x, total 1279t if in full, ~220 otherwise
		DEX					; outer loop (2x)
		BNE m20d			; (3x-1)
	DEC						; ** CMOS **
		BNE ms20
	RTS						; add 12t from call overhead

; *** RLE decompressor ***
; entry point, set src & ptr pointers
rle_loop:
		LDY #0				; always needed as part of the loop
		LDA (src), Y		; get command
		INC src				; advance read pointer
		BNE rle_0
			INC src+1
rle_0:
		TAX					; command is just a counter
			BMI rle_u		; negative count means uncompressed string
; * compressed string decoding ahead *
		BEQ rle_exit		; 0 repetitions means end of 'file'
; multiply next byte according to count
		LDA (src), Y		; read immediate value to be repeated
rc_loop:
			STA (ptr), Y	; store one copy
			INY				; next copy, will never wrap as <= 127
			DEX				; one less to go
			BNE rc_loop
; burst generated, must advance to next command!
		LDA #1
		BNE rle_adv			; just advance source by 1 byte
; * uncompressed string decoding ahead *
rle_u:
			LDA (src), Y	; read immediate value to be sent, just once
			STA (ptr), Y	; store it just once
			INY				; next byte in chunk, will never wrap as <= 127
			INX				; one less to go
			BNE rle_u
		TYA					; how many were read?
rle_adv:
		CLC
		ADC src				; advance source pointer accordingly (will do the same with destination)
		STA src
		BCC rle_next		; check possible carry
			INC src+1
; * common code for destination advance, either from compressed or uncompressed
rle_next:
		TYA					; once again, these were the transferred/repeated bytes
		CLC
		ADC ptr				; advance desetination pointer accordingly
		STA ptr
		BCC rle_loop		; check possible carry
			INC ptr+1
		BNE rle_loop		; no need for BRA
rle_exit:
	RTS

; *************************************
; *** *** main graphic routines *** ***
; *************************************

; *** text scroller *** multithreaded
scroller:
	LDA count				; check shiftings counter
	BPL sc_column			; if still shifting one char, continue with it
		INC text			; otherwise, next char in message
			BNE sc_char
		INC text+1
sc_char:
; get char from text
		LDA (text)				; get character to be displayed (CMOS only)
		BNE do_text				; restart text if NUL
			LDY #<msg
			LDX #>msg			; back to text start
			STY text
			STX text+1			; restore pointer
			LDA (text)			; and get first char, no big deal
do_text:
; compute glyph address
		STZ src+1				; will be shifted before adding font base address
		ASL
		ROL src+1
		ASL
		ROL src+1
		ASL
		ROL src+1				; times 8 rows per glyph
		CLC
		ADC #<font				; font base LSB
		STA src					; LSB pointer is ready
		LDA src+1
		ADC #>font				; font base MSB
		STA src+1				; glyph pointer is ready!
; copy glyph into buffer
		LDY #7					; max offset
		STY count				; will count 7...0
sb_loop:
			LDA (src), Y		; get glyph data
			STA glyph, Y		; store into buffer
			DEY
			BPL sb_loop
; maybe change colour here (per char)
		INC colidx				; advance colour
getcol:
		LDX colidx				; current colour index
		LDA coltab, X			; sorted colours
		BNE not_black
			STZ colidx			; black restarts list
			BRA getcol
not_black:
		STA colour
; * base update *
; displace 4 pixels (2 bytes) to the left on selected lines (every page start)
sc_column:
; if colour should change every column, do it here
	LDY #<scrl
	LDX #>scrl
	STY ptr					; destination LSB is set
	INY
	INY						; source is 4 pixels (2 bytes) to the right
	STY src					; LSBs are set
sc_pg:
		STX ptr+1
		STX src+1			; MSBs are set and updated
		LDY #0
sc_loop:
			LDA (src), Y
			STA (ptr), Y	; copy active byte
			INY
			INY				; every two pixels
			CPY #62			; no more to be scrolled?
			BNE sc_loop
		INX
		BPL sc_pg
; now print next column of pixels from glyph at the rightmost useable column
	LDX #0					; reset glyph buffer index
	LDY #>scrl				; back to top row
	LDA #62					; this is rightmost column
	STA ptr					; offset is ready
sg_pg:
		STY ptr+1			; update row page EEEEK
		ASL glyph, X		; shift current glyph raster
		LDA #0				; black background...
		BCC sg_cset			; ...will stay if no pixel there
			LDA colour		; otherwise get current colour
sg_cset:
		STA (ptr)			; set big pixel (CMOS only)
		INY					; next page on screen
		INX					; next raster on glyph
		CPX #8				; until the end
		BNE sg_pg
; * end of base update *
; column is done, count until 8 are done, then reload next character and store glyph into buffer
; maybe changing colour somehow
	DEC count				; one less column (7...0)
	RTS

; *** whole logo shifter ***
shifter:
	LDA #>screen3
	STA ptr+1				; set destination MSB
	STA base+1
	INC sh_ix				; for next EEEEEEK
sh_again:
	LDX sh_ix				; get shift index
	LDA shift, X			; positive means shift to the right (expected -32...+32)
	CMP #128				; special case, end of list
	BNE do_shift
		STZ sh_ix
		BRA sh_again		; roll back, PLACEHOLDER
do_shift:
; emulate ASR for sign extention!
	ASL						; keep sign into carry
	LDA shift, X			; restore value (faster this way)
	ROR						; check even/odd... with sign extention
	
	BCC not_half			; if even, whole byte shifting EEEEK
		LDY #>scr_shf		; otherwise take half-byte shifted origin
		BNE org_ok
not_half:
	LDY #>screen1			; original position of non-shifted copy
org_ok:
	STY src+1				; set origin pointer accordingly
	TAX						; recheck byte-offset (worth it)
	BMI s_left				; negative means shift to the left
; shift right
		STZ src				; assume always zero!
		STA ptr				; set destination offset LSB
		EOR #$FF			; 1's complement
		SEC					; looking for 2's complement
		ADC #63				; bytes per raster-offset EEEK
		STA sh_of			; last index
sr_ras:
		JSR shr_ras			; common raster code
		CMP #$64			; end of logo?
		BNE sr_ras
	RTS
s_left:
; shift left
		STZ ptr				; assume always zero!
		EOR #$FF			; 1's complement
		INC					; 2's complement
		STA src				; set ORIGIN offset LSB
		EOR #$FF			; 1's complement of offset
		SEC					; looking for 2's complement
		ADC #63				; bytes per raster-offset EEEK
		STA sh_of			; last index
sl_ras:
		JSR shl_ras			; common raster code
		CMP #$64			; end of logo?
		BNE sl_ras
	RTS

; *** logo wave twister *** TBD
twister:
	LDA #>screen3
	STA ptr+1				; set destination MSB
	STA base+1
	INC sh_ix				; for next EEEEEEK
tw_again:
	LDX tw_ix				; get shift index
	LDA wave, X			; positive means shift to the right (expected -32...+32)
	CMP #128				; special case, end of list
	BNE do_twist
		STZ tw_ix
		BRA tw_again		; roll back, PLACEHOLDER
do_twist:
; emulate ASR for sign extention!
	ASL						; keep sign into carry
	LDA wave, X				; restore value (faster this way)
	ROR						; check even/odd... with sign extention
	BCC not_htw				; if even, whole byte shifting EEEEK
		LDY #>scr_shf		; otherwise take half-byte shifted origin
		BNE tw_ok
not_htw:
	LDY #>screen1			; original position of non-shifted copy
tw_ok:
	STY src+1				; set origin pointer accordingly
	TAX						; recheck byte-offset (worth it)
	BMI t_left				; negative means shift to the left
; twist right
		STZ src				; assume always zero!
		STA ptr				; set destination offset LSB
		EOR #$FF			; 1's complement
		SEC					; looking for 2's complement
		ADC #63				; bytes per raster-offset EEEK
		STA sh_of			; last index
tr_ras:
		JSR shr_ras			; common raster code
		CMP #$64			; end of logo?
		BNE tr_ras
	RTS
t_left:
; twist left
		STZ ptr				; assume always zero!
		EOR #$FF			; 1's complement
		INC					; 2's complement
		STA src				; set ORIGIN offset LSB
		EOR #$FF			; 1's complement of offset
		SEC					; looking for 2's complement
		ADC #63				; bytes per raster-offset EEEK
		STA sh_of			; last index
tl_ras:
		JSR shl_ras			; common raster code
		CMP #$64			; end of logo?
		BNE tl_ras
	RTS

; *** *** auxiliary graphic routines *** ***
shr_ras:
; shift right one raster, returns destination page in A (autoincremented)
	LDY sh_of			; will be retrieved once and again
sr_l:
		LDA (src), Y	; get original
		STA (ptr), Y	; store with offset
		DEY
		BPL sr_l		; down to index 0
	LDA ptr
	AND #%11000000		; reset offset within raster
	STA base			; but on a different pointer!
	LDA ptr				; reload
	AND #%00111111		; but keep offset this time
	TAY					; retrieve byte-offset EEEK
	LDA #0				; will clear leftmost pixels
	DEY					; at least one before offset
	BMI no_rc			; if anything to be cleared
sr_c:
		STA (base), Y
		DEY
		BPL sr_c		; complete clear
no_rc:
	LDA src
	CLC
	ADC #64				; next raster in origin
	STA src
	BCC rr_nw
		INC src+1
		INC base+1		; may work here, too
rr_nw:
	LDA ptr
	CLC
	ADC #64				; next raster in destination
	STA ptr
	LDA ptr+1
	ADC #0				; propagate carry (and already in A)
	STA ptr+1			; will return page number
	RTS

shl_ras:
; shift left one raster, returns destination page in A (autoincremented)
	LDY sh_of			; will be retrieved once and again
sl_l:
		LDA (src), Y	; get original with offset
		STA (ptr), Y	; store it
		DEY
		BPL sl_l		; down to index 0
	LDY sh_of			; and again
	INY					; at least one AFTER last index
	CPY #64				; anything to clear?
	BEQ no_lc
		LDA #0			; will clear rightmost pixels
sl_c:
			STA (ptr), Y
			INY
			CPY #64
			BNE sl_c	; complete clear
no_lc:
	LDA src
	CLC
	ADC #64				; next raster in origin
	STA src
	BCC rl_nw
		INC src+1
		INC base+1		; may work here, too
rl_nw:
	LDA ptr
	CLC
	ADC #64				; next raster in destination
	STA ptr
	LDA ptr+1
	ADC #0				; propagate carry (and already in A)
	STA ptr+1
	RTS

; *** *** sound routines *** ***

; *** beeping routine ***
; *** X = length, A = freq. ***
; *** X = 2*cycles          ***
; *** tcyc = 16 A + 20      ***
; ***     @1.536 MHz        ***
m_beep:
mb_l:
		TAY					; determines frequency (2)
		STX IOBeep			; send X's LSB to beeper (4)
mb_zi:
#ifdef	TURBO
			STY temp
			STY temp
			NOP				; double loop delay
#endif
			STY temp		; small delay for 1.536 MHz! (3)
			DEY				; count pulse length (y*2)
			BNE mb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE mb_l			; new half cycle (3)
	STX IOBeep				; turn off the beeper!
	RTS

; *** squeak sound ***
; A=initial period, Y=final period, X=length
; uses m_beep
squeak:
	STA sqk_par+1
	STA sqk_par				; and current
	STY sqk_par+2
	STX count
sw_up:
		LDX count
		JSR m_beep
		LDA sqk_par
		SEC
		SBC #3
		STA sqk_par
		CMP sqk_par+2
		BCS sw_up
sw_down:
		LDX count
		JSR m_beep
		LDA sqk_par
		CLC
		ADC #3
		STA sqk_par
		CMP sqk_par+1
		BCC sw_down
	RTS


; ********************
; *** *** data *** ***
; ********************

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

; *** sorted colour table ***
coltab:
	.byt	$FF, $77, $33, $66, $CC, $99, $DD
	.byt	$55, $11, $CC, $99, $DD, $77, $33, $66
	.byt	$AA, $EE, $BB, 0

; *** trigonometry tables ***
shift:
	.byt	  0,   0,   0,   0,   0,   0,   1,   1,   1,   2
	.byt	  2,   2,   3,   3,   3,   3,   3,   3,   3,   3
	.byt	  3,   2,   2,   1,   0,   0, 255, 254, 253, 252
	.byt	251, 250, 249, 248, 248, 247, 246, 246, 246, 246
	.byt	246, 246, 246, 247, 248, 249, 250, 251, 252, 254
	.byt	  0,   1,   3,   4,   6,   8,   9,  11,  12,  13
	.byt	 14,  15,  15,  16,  16,  15,  15,  14,  13,  12
	.byt	 10,   8,   6,   4,   2,   0, 253, 251, 248, 246
	.byt	243, 241, 239, 238, 236, 235, 234, 233, 233, 233
	.byt	234, 234, 236, 237, 239, 241, 244, 246, 249, 252
	.byt	  0,   3,   6,   9,  12,  15,  18,  21,  23,  25
	.byt	 26,  27,  28,  28,  28,  27,  26,  25,  23,  20
	.byt	 18,  14,  11,   7,   3,   0, 252, 248, 244, 241
	.byt	237, 235, 232, 230, 229, 228, 227, 227, 227, 228
	.byt	229, 230, 232, 234, 237, 240, 243, 246, 249, 252
	.byt	  0,   3,   6,   9,  11,  14,  16,  18,  19,  21
	.byt	 21,  22,  22,  22,  21,  20,  19,  17,  16,  14
	.byt	 12,   9,   7,   4,   2,   0, 253, 251, 249, 247
	.byt	245, 243, 242, 241, 240, 240, 239, 239, 240, 240
	.byt	241, 242, 243, 244, 246, 247, 249, 251, 252, 254
	.byt	  0,   1,   3,   4,   5,   6,   7,   8,   9,   9
	.byt	  9,   9,   9,   9,   9,   8,   7,   7,   6,   5
	.byt	  4,   3,   2,   1,   0,   0, 255, 254, 253, 253
	.byt	252, 252, 252, 252, 252, 252, 252, 252, 252, 253
	.byt	253, 253, 254, 254, 254, 255, 255, 255, 255, 255
	.byt	128				; *** end of list ***

wave:
	.byt	  0,   0					; padding
	.byt	  0,   0,   0,   0,   0,   0,   0,   0
	.byt	  0,   0,   0,   0,   0,   0,   0,   2
	.byt	  6,  10,  16,  22,  24,  22,  16,   9
	.byt	  0, 246, 239, 233, 232, 233, 239, 245
	.byt	249, 253, 255, 255,   0,   0,   0,   0
	.byt	  0,   0,   0,   0,   0,   0,   0,   0
	.byt	  0,   0,   0,   0				; padding
	.byt	128				; *** end of list ***

; *** displayed text ***
msg:
	.asc	"    ", 16, 32, 16, 32, 16, " Durango·X: the 8-bit computer for the 21st Century! ", 16, 32, 16, 32, 16
	.asc	"    65C02 @ 1.536-3.5 MHz... 32K RAM... 32K ROM in cartridge... "
	.asc	"128x128/16 colour, or 256x256 mono video... 1-bit audio! ", 19, 32, 7, 32, 19
	.asc	" Designed in Almería by @zuiko21 at LaJaquería.org ", 17, 32, 7, 32, 17
	.asc	" Big thanks to @emiliollbb and @zerasul, plus all the folks at 6502.org    "
	.asc	14, 32, 6, 32, 6, " P.S.: Learn to code in assembly! ", 2, 32, 2, 32, 15, "    ", 0
end:

; BIG DATA perhaps best if page-aligned?

; *** font data ***
	.dsb	$CC00-*, $FF
font:
	.bin	0, 0, "8x8.fnt"				; 2 KiB, not worth compressing (~1.8 K)

; *** picture data *** RLE compressed
;	.dsb	$D400-*, $FF				; already there!
banner:
	.bin	0, 0, "durango-x.rle"		; 534 bytes ($216, 3 pages)

	.dsb	$D700-*, $FF
standby:
	.bin	0, 0, "standby.rle"			; 2031 bytes ($7EF, 8 pages but must skip $DF)
stby_end:								; check whether before $DF80!

	.dsb	$E200-*, $FF
smpte:
	.bin	0, 0, "smpte.rle"			; 3344 bytes ($D10, 14 pages)

	.dsb	$F000-*, $FF
kidding:
	.bin	0, 0, "kidding.rle"			; 4052 bytes ($FD4, 16 pages including last!)
pic_end:

; ****************************************
; *** padding, ID and hardware vectors ***
; ****************************************

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
