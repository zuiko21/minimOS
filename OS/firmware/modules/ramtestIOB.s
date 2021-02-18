; firmware module for minimOS
; RAMtest 0.6a1
; modified for integrated IOB beep
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20210218-1438

; *** RAMtest, 6510-savvy ***
; check zeropage first (except bytes 0-1)

.(
; *** exhaustive ZP check ***
	LDX #$FE				; addresses to be checked (2)
;	LDY #5					; odd-divisor for toggling speaker output
z_test:
;		DEY					; advance divisor (2)
;		BNE zb_tog			; do nothing until expired (3/2)
;			TXA				; if so, take current index (0/2)
;			STA $BFF0		; D0 will change every time (0/4)
;			LDY #5			; preset divisor (0/2)
;zb_tog:
		LDA #$AA			; test pattern (2)
p_test:
			STA 1, X		; 6510-savvy, X>0 (4)
			CMP 1, X		; check (4+2)
				BNE lock
			EOR #$FF		; also with inverse pattern (2+3)
			BPL p_test		; THIS LOOP: 29+5t, 29+12t every 5
		TXA					; try with index as well (2+4+4+2)
		STA 1, X
		CMP 1, X
			BNE lock
		DEX					; go for next ZP address (2+3)
		BNE z_test			; THIS LOOP: 2+34+12+5-1=52t per byte, plus 7 every 5 bytes
; buzzer bit toggles every 267t => 1873 Hz @ 1 MHz
ram_ok:
; *** SRAM already measured and tested ***
.)
