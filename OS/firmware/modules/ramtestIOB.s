; firmware module for minimOS
; RAMtest 0.6a3
; modified for integrated IOB beep
; (c) 2015-2022 Carlos J. Santisteban
; last modified 20210226-1435

; *** RAMtest, 6510-savvy ***
; check zeropage first (except bytes 0-1)

#define	STKTEST	_STKTEST
.(
; *** exhaustive ZP (and stack) check ***
	LDX #$FE				; addresses to be checked (2)
z_test:
		LDA #$AA			; test pattern (2)
p_test:
			STA 1, X		; 6510-savvy, X>0 (4)
			CMP 1, X		; check (4+2)
				BNE m_err
#ifdef	STKTEST
; ditto for stack!
			STA $101, X		; won't test last two bytes though (5)
			CMP $101, X		; check (4+2)
				BNE m_err
#endif
			EOR #$FF		; also with inverse pattern (2+3)
			BPL p_test		; THIS LOOP: 29+5t +...
		TXA					; try with index as well (2)
		STA 1, X			; store and check (4+4+2)
		CMP 1, X
			BNE m_err
#ifdef	STKTEST
		STA $101, X			; stack too (5+4+2)
		CMP $101, X
			BNE m_err
#endif
		DEX					; go for next ZP address (2+3)
		BNE z_test			; THIS LOOP: 2+34+12+5-1=52t per byte +...
	BEQ rz_beep				; ZP was fine
m_err:
		JMP lock			; panic otherwise!

; *****************************
; *** ** beeping routine ** ***
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
; *****************************
mt_beep:
		TAY					; determines frequency (2)
		STX $BFF0			; send X's LSB to beeper (4)
rb_zi:
			DEY				; count pulse length (y*2)
			BNE rb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE mt_beep			; new half cycle (3)
	STX $BFF0				; turn off the beeper!
	RTS
; *****************************
mz_beep:
; ZP is OK, let's do a short G beep (~1568 Hz, or 638t)
	LDX #63					; determines length (~ 40 ms)
	LDA #62					; determines frequency (2) (actually 1562.5 Hz)
	JSR mt_beep

; check for mirroring? ZP is fine (stack too)

; now time to test rest of memory

; all OK, let's do a longer C beep (~1046.5 Hz or 956t)
; **********************************************
; *** might include a separate file for this ***
; 2(5y+10) = 10y+20 is a whole cycle, thus Y ~ 94
rm_beep:
	LDX #208				; determines length (~ 200 ms)
	LDA #94					; determines frequency (2) (actually 1041.7 Hz)
	JSR mt_beep

ram_ok:
; *** SRAM already measured and tested ***
.)
