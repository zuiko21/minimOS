; dithered picture test for Durango-X (RAMless)
; (c) 2023 Carlos J. Santisteban


; *** definitions ***
IO8attr	= $DF80
IO8blnk	= $DF88
IO9kbd	= $DF9B
IOAie	= $DFA0
scr		= $6000

; *** code ***
	*	= $C000

reset:
	SEI
	CLD
	LDX #$FF
	TXS						; usual 6502 stuff
	STX IOAie				; enable Durango-X interrupts; not used but turns LED off
	LDA #$38				; RGB mode
	STA IO8attr				; set video mode
; copy screen, RAMless
loop:
	LDA rom, X				; $c100
	STA scr, X
	LDA rom+$100, X
	STA scr+$100, X
	LDA rom+$200, X
	STA scr+$200, X
	LDA rom+$300, X
	STA scr+$300, X
	LDA rom+$400, X
	STA scr+$400, X
	LDA rom+$500, X
	STA scr+$500, X
	LDA rom+$600, X
	STA scr+$600, X
	LDA rom+$700, X
	STA scr+$700, X
	LDA rom+$800, X
	STA scr+$800, X
	LDA rom+$900, X
	STA scr+$900, X
	LDA rom+$a00, X
	STA scr+$a00, X
	LDA rom+$b00, X
	STA scr+$b00, X
	LDA rom+$c00, X
	STA scr+$c00, X
	LDA rom+$d00, X
	STA scr+$d00, X
	LDA rom+$e00, X
	STA scr+$e00, X
	LDA rom+$f00, X
	STA scr+$f00, X
	LDA rom+$1000, X
	STA scr+$1000, X
	LDA rom+$1100, X
	STA scr+$1100, X
	LDA rom+$1200, X
	STA scr+$1200, X
	LDA rom+$1300, X
	STA scr+$1300, X
	LDA rom+$1400, X
	STA scr+$1400, X
	LDA rom+$1500, X
	STA scr+$1500, X
	LDA rom+$1600, X
	STA scr+$1600, X
	LDA rom+$1700, X
	STA scr+$1700, X
	LDA rom+$1800, X
	STA scr+$1800, X
	LDA rom+$1900, X
	STA scr+$1900, X
	LDA rom+$1a00, X
	STA scr+$1a00, X
	LDA rom+$1b00, X
	STA scr+$1b00, X
	LDA rom+$1c00, X
	STA scr+$1c00, X
	LDA rom+$1d00, X
	STA scr+$1d00, X
;	LDA rom+$1e00, X
	STA scr+$1e00, X
	LDA rom+$1f00, X
	STA scr+$1f00, X
	DEX
	CPX #$FF
	BEQ _end_code
		JMP loop
_end_code:
	BRA _end_code
	
	.dsb	$c100-*, $ff

; *** images ***
rom:
	.bin	0, 0, "../../other/data/dl3.sv"

; *** end of ROM stuff ***
	.dsb	$FFD6-*, $FF	; filler

	.asc	"DmOS"			; standard sigature
	.dsb	$FFF9-*, $FF	; one byte before vectors
null:
	RTI						; null interrupt handler, just in case

	.word	reset			; NMI like reset
	.word	reset
	.word	null			; IRQ/BRK do nothing

