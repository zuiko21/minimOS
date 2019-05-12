; RickRolling for Acapulco!
; (c) 2019 Carlos J. Santisteban
; last modified 20190512-1331

.(
; *** minimOS header to be done ***

; *** zeropage declarations ***
	vptr	= local1	; 16-bit indirect pointer
	frames	= local1+2	; 8-bit frame counter, enough for ~8s

; *** initial code ***
#ifdef	SAFE
	_STZA ex_pt			; get standard ISR
	_STZA ex_pt+1
	_ADMIN(SET_ISR)
	LDA ex_pt+1			; and save it for later
	PHA
	LDA ex_pt			; LSB too
	PHA
#endif
	SEI					; audio disabled by default
	LDY #<au_isr			; ISR address
	LDA #>au_isr
	STY ex_pt			; set new ISR
	STA ex_pt+1
	_ADMIN(SET_ISR)
	LDA #$5C			; start page of attribute area
	STA vptr+1
	LDY #0				; reset counter...
	STY vptr			; ...and indirect pointer
	LDA #240			; 8 seconds at 30fps
	STA frames			; prepare counter, zero may be acceptable
	CLI					; enable audio and start playing!
; *** main loop *** usually 34t per byte, nearly 21 ms per frame :-(
vi_loop:
		LDA VIA_U+IORA			; get video data... (4)
		STA (vptr), Y			; ...into attribute area (5)
		INY					; next byte (2)
		BNE nx_vi			; check wrap or continue (3/15...)
			INC vptr+1			; next page (5)
			LDA vptr+1			; check attribute end (3+2)
			CMP #$60
			BNE nx_vi			; check end of frame (3...)
				LDA #$5C			; (2+3) reset pointer
				STA vptr+1
; should ask 6445 for next frame!
				DEC frames			; (5) fastest way up to 8s ~240 frames)
				BEQ ra_end			; (2) until video is finished
vi_nx:
		LDA VIA_U+IORB			; get port status (4)
#ifdef	LSB6
; 6 bits from PB1-6, rest on inboard counter pulsed by PB6 (total 7/8t)
		CLC
		ADC #2					; increase count on PB1-6 (2+2)
		BPL vi_plus			; PB7 did not change (3/4)
			AND #$7F			; clear it otherwise
vi_plus:
#else
; full 18-bit counter on board, just pulse PB1, does not seem worth it (total 8t)
		ORA #&00000010			; set PB1 (2)
		STA VIA_U+IORB			; port bit goes high... (4)
		AND #%11111101			; clear PB1 (2)
#endif
		STA VIA_U+IORB			; set updated value (4)
		JMP vi_loop			; continue until aborted (3)
; *** clean up and finish ***
ra_end:
#ifdef	SAFE
; restore previous ISR!
	PLA
	STA ex_pt
	PLA
	STA ex_pt+1
	_ADMIN(SET_ISR)
#endif

; *****************
; *** audio ISR *** max. overhead is 39t+cur. opcode (not 33t because of vectored IRQ)
; *****************
au_isr:
	PHA					; only affected register (3)
	INC VIA_U+IORB			; put PB0 high (selects audio ROM) (6)
	LDA VIA_U+IORA			; get audio PWM pattern... (4)
	STA VIA_U+VSR			; ...into shift register (4)
	DEC VIA_U+IORB			; put back PB0 low (advances audio counter and selects video ROM)
	PLA					; restore register and finish (4+6)
	RTI
.)
