; firmware module for minimOS
; RAMtest 0.6a1
; modified for integrated IOB beep
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20210218-1433

; *** RAMtest, 6510-savvy ***
; check zeropage first (except bytes 0-1)

.(
; *** exhaustive ZP check ***
	LDX #$FE				; addresses to be checked (2)
;	LDY #5					; odd-divisor for toggling speaker output
z_test:
;		DEY					; advance divisor
;		BNE zb_tog			; do nothing until expired
;			TXA				; if so, take current index
;			STA $BFF0		; D0 will change every time
;			LDY #5			; preset divisor
;zb_tog:
		LDA #$AA			; test pattern (2)
p_test:
			STA 1, X		; 6510-savvy, X>0 (4)
			CMP 1, X		; check (4+2)
				BNE lock
			EOR #$FF		; also with inverse pattern (2+3)
			BPL p_test		; THIS LOOP: 29t
		TXA					; try with index as well (2+4+4+2)
		STA 1, X
		CMP 1, X
			BNE lock
		DEX					; go for next ZP address (2+3)
		BNE z_test			; THIS LOOP: 2+29+12+5-1=47t per byte
ram_ok:
; *** SRAM already measured and tested ***
.)
