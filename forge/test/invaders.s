; Space Invaders sound test for Durango
; (c) 2021-2023 Carlos J. Santisteban

; must play 494, 440, 392 and 370 Hz brief notes
; that's semicycles of 1555t, 1745t, 1959t and 2076t
; for 9t loops is ~173, 194, 218 and 231
; like every 0.6 s?

.text
;*		= $FF80				; standard download
* = $c000
.dsb $ff80-*, $ff

reset:
	SEI						; just in case
play:
	LDA #173				; B (494 Hz)
	JSR note
	JSR delay
	LDA #194				; A (440 Hz)
	JSR note
	JSR delay
	LDA #218				; G (392 Hz)
	JSR note
	JSR delay
	LDA #231				; Gb (370 Hz)
	JSR note
	JSR delay
	JMP play

note:
	LDY #15					; number of semicycles
n_loop:
		TAX					; get loop value
hi_loop:
			STY $DFB0		; beeper output
			DEX
			BNE hi_loop
		DEY					; toggle output
		TAX					; get loop value again
lo_loop:
			STY $DFB0		; beeper output
			DEX
			BNE lo_loop
		DEY					; toggle output
		BPL n_loop			; good for a few cycles
	RTS

; 64K * 14t
delay:
	LDA #0					; useful to disable output
	TAX						; reset counters
	TAY
d_loop:
			STA $DFB0
			STA 0			; some extra delay
			NOP
			INX
			BNE d_loop
		INY
		BNE d_loop
	RTS
end:

	.dsb	$FFFA-*, $ff
	
vectors:
	.word	reset
	.word	reset
	.word	reset
