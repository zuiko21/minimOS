; zero-page wrap test
; (c) 2022 Carlos J. Santisteban

* = $FF80

reset:
	SEI
	CLD
	LDX #$FF
	TXS

; Durango init
	STX $DFA0		; ERROR off
	LDA #$38		; colour mode
	STA $DF80

; clear screen
	LDX #$60		; screen 3 pointer
	LDY #0
	STY $80
	TYA				; black
p_loop:
		STX $81
b_loop:
			STA ($80), Y
			INY
			BNE b_loop
		INX
		BPL p_loop

; test code
	LDX #2			; test values
	LDY #3
	LDA #4
	
	STA $FF			; vector LSB
	STX 0			; vector MSB location if wraps
	STY $101		; vector MSB location if no wrap

	STX $204		; destination if wraps
	STY $304		; destination if no wrap

; ZP-indexed test
	LDX #1			; make sure it crosses page
	LDA $FF, X		; should be from $0 (2) if wraps

	TAX
	LDA #$08		; blue
zx_l:
		STA $6100, X
		DEX
		BNE zx_l	; display dot bar (2 or 3 pixels)

; pre-indexed indirect test
	LDA ($FF, X)	; X known zero, will work the same as (zp), Y=0

	TAX
	LDA #$02		; red
izx_l:
		STA $6200, X
		DEX
		BNE izx_l	; display dot bar (2 or 3 pixels)

; indirect post-indexed test
	LDY #0			; same as before
	LDA ($FF), Y

	TAX
	LDA #$05		; green
izy_l:
		STA $6300, X
		DEX
		BNE izy_l	; display dot bar (2 or 3 pixels)

end:
	JMP end

; padding and hard vectors

	.dsb	$FFFA-*, $FF

	.word	reset	; NMI
	.word	reset
	.word	reset	; IRQ/BRK
