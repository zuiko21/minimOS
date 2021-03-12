	* = $400
	
	lda $af00
	lda #%00001100
	sta $fff0
;	sta $bff0
l1:	inx
	bne l1
	iny
	bne l1
	lda $af01
	lda #%00000011
	sta $fff0
;	sta $bff0
l2: inx
	bne l2
	iny
	bne l2
	jmp $400
