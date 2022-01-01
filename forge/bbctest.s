; (c) 2015-2022 Carlos J. Santisteban
* = $ff00
boot:
	SEI
	CLD
	CLC			; go native!
	XCE
.al:REP #$20
LDA #'&'
JSR $c0c2
; init
	LDX #0
loop:
;		JSR $c0bf	; input?
;			TAY
;			BEQ loop
		PHX
		LDA splash, X
			BEQ lock
		JSR $c0c2
		LDA #'!'
		JSR $c0c2
		PLX
		INX
		BRA loop
lock:
	BRA lock
irq:
	RTI
splash:
	.asc	"Probando el BBC", 0, 0

	.dsb	$FFFA - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = $FFFA						; skip I/O area for firmware

	.word	irq
	.word	boot
	.word	irq
