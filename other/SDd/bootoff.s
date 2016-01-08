$0600	78	sei
	d8	cld
	a9 f0	lda #$f0
	8d f36f	sta $6ff3
	8d f16f	sta $6ff1
	a2 ff	ldx #$ff
	9a	txs
	a9 0f	lda #$0f
$060f	2d f16f	and $6ff1
	0a	asl
	aa	tax
	7c e0fe	jmp ($fee0, X)	; tabla @ $06E0

$FCE0 => $04E0: smoke...

$0000:	4c e0fc	jmp $FCE0
&00f8

NMI=$F85F (005F) en vez de $FF5F:
005f	a9 ff	lda #$ff
	8d f26f	sta $6ff2
	8d f36f	sta $6ff3
	9c f66f	stz $6ff6	; t1l-l
	a9 32	lda #50		; 1 kHz
	8d f76f	sta $6ff7	; t1l-h
	8d f56f	sta $6ff5	; t1c-h
	a9 e0	lda #$e0	; pb7 out
	8d fb6f	sta $6ffb	; acr
	4c a9fa	jmp $FAA9	; patrón @ $2a9

02a9	48	pha
	80 fd	bra -3 
