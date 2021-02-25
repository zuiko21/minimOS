; firmware module for minimOS
; RAMtest 0.6a2
; modified for integrated IOB beep
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20210225-1345

; *** RAMtest, 6510-savvy ***
; check zeropage first (except bytes 0-1)

.(
; *** exhaustive ZP check ***
	LDX #$FE				; addresses to be checked (2)
z_test:
		LDA #$AA			; test pattern (2)
p_test:
			STA 1, X		; 6510-savvy, X>0 (4)
			CMP 1, X		; check (4+2)
				BNE lock
			EOR #$FF		; also with inverse pattern (2+3)
			BPL p_test		; THIS LOOP: 29+5t
		TXA					; try with index as well (2+4+4+2)
		STA 1, X
		CMP 1, X
			BNE lock
		DEX					; go for next ZP address (2+3)
		BNE z_test			; THIS LOOP: 2+34+12+5-1=52t per byte
		
; buzzer bit toggles every 267t => 1873 Hz @ 1 MHz, VERY close to Bb6

; another note should be musically related to 1873 Hz
ram_ok:
; *** SRAM already measured and tested ***
.)
