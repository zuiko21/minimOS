; firmware module for minimOS·65
; extensive RAM test (like test suite) for Durango-X
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20210915-2259

.(
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
		STX $B000			; make beep at 158t ~4.86 kHz
		BNE zp_1			; complete page (3, post 13t)
	BEQ zp_ok
zp_bad:
; panic if failed
; high pitched beep (158t ~4.86 kHz)
	LDY #29
zb_1:
		DEY
		BNE zb_1			; inner loop is 5Y-1
	NOP						; perfect timing!
	INX
	STX $B000				; toggle buzzer output
	JMP zp_bad				; outer loop is 11t 
zp_ok:

; * simple mirroring test *
; probe responding size first
#ifdef	DOWNLOAD
	LDY #63					; max 16 KB, also a fairly good offset
#else
	LDY #127				; standard 32 KB, will affect screen anyway
#endif
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
	BEQ at_bad

addr_ok:
; * RAM test *
; silent but will show up on screen
	LDA #$F0				; initial value
	LDY #0
	STY test				; standard pointer address
rt_1:
		LDX #1				; skip zeropage
#ifdef	DOWNLOAD
		BNE rt_2
rt_1s:
		LDX #$60			; skip to begin of screen
#endif
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
#ifdef	DOWNLOAD
				CPX #$60	; already at screen
				BCC rt_1s	; ...or continue with screen
			CPX #$80		; end of screen?
			BNE rt_2
#endif
		LSR					; create new value, either $0F or 0
		LSR
		LSR
		LSR
		BNE rt_1			; test with new value
		BCS rt_1			; EEEEEEEEEEEEK
	BCC ram_ok				; if arrived here SECOND time, C is CLEAR and A=0
ram_bad:
; panic if failed
; inverse bars and continuous beep
	STA $8000				; set flags (hopefully A<128)
	STA $B000				; set buzzer output
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	EOR #65					; toggle inverse mode... and buzzer output
	JMP ram_bad

ram_ok:
.)
