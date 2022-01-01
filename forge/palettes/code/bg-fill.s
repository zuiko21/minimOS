; SIXtation FW background fill
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20200410-2227

; *** hardware definitions ***

	mp_sel =	$DFC2		; multiplane select write
	mp_lngl =	$B00000		; multiplane access base
	mp_lngh =	$B10000		; multiplane access second half

	* = $FBF0				; experimental background fill routine, note BF mnemonic

bg_fill:
; enter routine, Y = background colour (AND 254)
; in case full 8-bit entry is not guaranteed...
	SEP #$30				; all 8-bit (3)
	.xs:.as
; will exit on 16-bit both M & X
	TYA						; base colour on A.MSB... (2)
	XBA						; switch accs (3)
	TYA						; ...and on A.LSB (2)
	LDX #0						; reset index (2)

	REP #$30				; all 16-bit (3)
	.xl:.al

	AND #$FEFE				; mask bit 0 (and 8) out (3)
	TAY						; save for later (2)
	EOR #$FEFE				; select zeroed bits (3)
	STA mp_sel				; enable these banks, LSB ignored (5)
	TXA						; clear value for these banks (2)
bf_loop:	; 19x32768+13-1 twice -1, 30+6 overhead
		STA @mp_lngl, X				; clear that word... (6)
		STA @mp_lngh, X				; ...on both halves (6)
		INX							; next word (2+2)
		INX
		BNE bf_loop				; repeat until X wraps (3)
	STY mp_sel				; select planes to be set, LSB ignored (5)
	DEC						; now A will be all ones (2)
	CMP #$FFFE				; went twice? (3)
		BNE bf_loop				; if not, go for a second time (3)
	RTS						; *** ends in all 16-bit ***
; takes about 0.138s @ 9 MHz, or 92ms @ 13.5 MHz, 41 bytes ($FBF0-$FC18)
; is this timing right? seems so!

/*
; alternative way is 51 bytes, actually SLOWER 189ms @ 9 MHz
	SEP #$30
	.as:.xs

	TYA
	AND #$FE
	TAY
	EOR #$FE
	STA mp_sel
	LDX #0

	REP #$30
	.xl:.al

	TXA				; common part 22t
bf_cyc:
		PEA #$B1B0		; 5t twice
		PLB			; 1st loop is 4t plus 32k x 13 -1, 425987t
bf_loop:
			STA 0, X	; zeropage or absolute for 16-bit index?
			INX
			INX
			BNE bf_loop
		PLB			; 2nd loop is 425987t
bf_loop2:
			STA 0, X	; zeropage or absolute for 16-bit index?
			INX
			INX
			BNE bf_loop2
		DEC			; 1+ twice 7
		CMP #$FFFE
	BEQ bf_exit

		SEP #$10		; once done 13
		.xs

		STY mp_sel

		REP #$10
		.xl

		BRA bf_cyc
bf_exit:
	RTS				; last 6t, TOTAL 
*/
