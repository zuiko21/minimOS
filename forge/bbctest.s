* = $C000
boot:
	SEI
	CLD
	CLC			; go native!
	XCE
; init
	LDX #0
loop:
		JSR $c0bf	; input?
			TAY
			BEQ loop
;		LDA splash, X
;			BEQ lock
;		PHX
		JSR $c0c2
		LDA #'!'
		JSR $c0c2
;		PLX
		INX
		BRA loop
lock:
	BRA lock
irq:
	RTI
splash:
	.asc	"Probando el BBC", 0

	.dsb	$FFFA - *, $FF	; for ready-to-blow ROM, skip to firmware area
* = $FFFA						; skip I/O area for firmware

	.word	irq
	.word	boot
	.word	irq
