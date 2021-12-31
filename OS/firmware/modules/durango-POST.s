; firmware module for minimOS
; system checker routine 0.9.6a6
; for Durango-X, both ROMmable and DOWNLOADable
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-0045

#ifdef	TESTING
#include "../../macros.h"
#include "../../abi.h"
#include "../../zeropage.h"
#include "../../options/durango.h"
	*=	$200
#include "../durango.h"
.text
	*=	$3FF6	; *** note special testing load address! ***
	SEI
	CLD
	LDX #$FF
	TXS
	LDA #$38	; colour mode
	STA $DF80
#endif

.(
; *** special zeropage definitions ***
	test	= 0				; temporary storage and pointer
	posi	= $FB			; safe locations during tests
	mxmem	= $FF

; ******************
; *** test suite ***
; ******************

; * zeropage test *
; make high pitched chirp during test
	LDX #0					; no 6510 allowed!
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
		LDA #$FE			; ZP bad, single flash
		JMP lock			; panic if failed
zp_ok:

; * simple mirroring test *
; probe responding size first
	LDY #>ROM_BASE-1		; DOWNLOAD-savvy, also a fairly good offset
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
		LDA #%11111			; long blink (33%, C is set?) 
		JMP lock			; if arrived here, there is no more than 256 bytes of RAM, which is a BAD thing
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
	STA mxmem				; store in a safe place (needed afterwards)
; the address test needs mxmem in a bit-position format (An+1)
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
; should actually check whether actual size is enough (8 KiB) ***

; * address lines test *
; X=bubble bit, Y=base bit (An+1)
; written value =$XY
; first write all values
	_STZA test				; zero is a special case, as no bits are used
	LDY #1					; first base bit, representing A0
at_0:
		LDX #0				; init bubble bit as disabled, will jump to Y+1
at_1:
			LDA bit_l, Y
			ORA bit_l, X	; create pointer LSB
			STA sysptr		; savvy addresses for this test!
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
			STA (sysptr)	; CMOS only, no way to use macro (see below)
#else
			LDY #0			; but needs to be restored!
			STA (sysptr), Y
			LDY systmp		; easily recovered writing $XY instead of $YX
#endif
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
#ifndef	NMOS
			CMP (sysptr)	; CMOS only, see below
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
			CPX posi		; size-savvy!
			BNE at_4
		INY					; end of bubble, advance base bit
		CPY posi			; size-savvy!
		BNE at_3			; this will disable bubble, too
	BEQ addr_ok
at_bad:
		LDA #%101			; LED turns off twice, is C set?
		JMP lock
addr_ok:

; * RAM test *
; silent but will show up on screen
; 8 K systems cannot add the usual screen test, but cannot download either
	INC mxmem				; worth it, now is the first non-RAM page
#ifndef	DOWNLOAD
	LDA mxmem
	SEC
	SBC #$20				; subtract screen size
#else
	LDA #$60				; hopefully correct address!
#endif
	STA posi				; will indicate first page of screen (0 if 8K)
	LDA #$F0				; initial value
	LDY #0
	STY test				; standard pointer address
rt_1:
		LDX #1				; skip zeropage
		BNE rt_2
rt_1s:
		LDX posi			; skip to begin of screen (not used on 8K)
rt_2:
			STX test+1		; update pointer
			STA (test), Y	; store...
			CMP (test), Y	; ...and check
				BNE rt_3	; mismatch!
			INY
			BNE rt_2
				INX			; next page
				STX test+1
				CPX mxmem	; should check against actual RAMtop
			BCC rt_2		; ends at whatever detected RAMtop...
;			BEQ rt_2		; not needed as mxmem was incremented
				CPX posi	; already at screen...
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
		LDA #%11111010		; blinks twice (C is set here)
		JMP lock			; panic if failed
ram_ok:

	LDA mxmem				; we now for sure RAM size, let's store it definitely
	STA himem				; standard firmware variable

; * ROM test is already done *

; * show banner if ROM checked OK *** from RLE decoder!
	LDY #<banner			; get compressed banner address
	LDA #>banner
	STY rle_src				; store pointer
	STA rle_src+1
	LDY #0					; get screen address
	LDA posi				; computed screen address
#ifdef	SAFE
	BNE vr_ok				; posi was invalid on 8K
		LDA #$10			; 8K system has smaller screen
vr_ok:
#endif
	STY rle_ptr				; store pointer
	STA rle_ptr+1
#ifndef	TESTING
	JSR rle_dec				; direct firmware call, don't care about errors
#endif

; * NMI test in nonsense *

; * IRQ test *
irq_test:
; no minibanner here
; no inverse video during test (brief flash)
; interrupt setup
	LDY #<t_isr				; ISR address
	LDX #>t_isr
	STY fw_irq				; standard-ish IRQ vector
	STX fw_irq+1
	LDY #0					; initial value and inner counter reset
	STY test
; must enable interrupts!
	INY
	STY IOAie				; hardware interrupt enable (LED goes off) suitable for all
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
; do not display dots, just compare results
	LDA test
	CMP #31					; one less is aceptable
	BCS it_3				; <31 is slow 
it_slow:
		LDA #%11111			; long off (4/9 as C is clear)
		JMP lock
it_3:
	CMP #34					; up to 33 is fine
	BCC it_ok				; 31-33 accepted
		LDA #%10101010		; otherwise turn off LED four times
		JMP lock			; >33 is fast
it_ok:
	JMP test_end			; all OK, skip data
	
; *** next is testing for HSYNC and VSYNC... ***


; ********************************************
; *** miscelaneous stuff, may be elsewhere ***
; ********************************************

; *** interrupt routine (for both IRQ and NMI test) *** could be elsewhere
t_isr:
	INC test				; increment standard zeropage address (no longer DEC)
exit:
	RTI

; *** bit position table *** actually combining both tables
; H_INDEX =   0    1    2    3    4    5    6    7
bit_h:
	.byt    $00, $00, $00, $00, $00, $00, $00, $00

; L_INDEX =   0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
; H_INDEX =   8    9    A    B    C    D    E    F
bit_l:
	.byt	$00, $01, $02, $04, $08, $10, $20, $40, $80, $00, $00, $00, $00, $00, $00, $00
;            -    A0   A1   A2   A3   A4   A5   A6   A7   A8   A9   AA   AB   AC   AD   AE (A14)

; *** RLE-compressed banner ***
banner:
	.bin	0, 536, "../other/data/durango-x.rle"	; check path ***

; ***************************
; *** all OK, end of test ***
; ***************************
test_end:

#ifdef	TESTING
#include "streaks.s"
#endif
.)
