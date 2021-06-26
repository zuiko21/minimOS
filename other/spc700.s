; SNES SPC-700 boot in 65C02 syntax!
; (c) 2021 Carlos J. Santisteban

RESET:
	LDX #$EF				; MOV X, #$EF
	TXS						; MOV SP, X


	LDA #0					; MOV A, #0
.clear:
		STA 0, X			; MOV (X), A	; ***OK?
		DEX					; DEC X
		BNE .clear


	LDA #$AA				; ***
	STA $F4					; MOV $F4, #$AA
	LDA #$BB				; ***
	STA $F5					; MOV $F5, #$BB
	LDA #$CC				; ***
.wait:
		CMP $F4				; CMP $F4, #$CC
		BNE .wait

	BRA Start


Block:
		LDY $F4				; MOV Y, $F4
		BNE Block

.data:
		CPY $F4				; CMP Y, $F4
		BNE .retry
			LDA $F5			; MOV A, $F5
			STY $F4			; MOV $F4, Y
			STA (0), Y		; MOV ($00)+Y, A
			INY				; INC Y
			BNE .data
		INC 1
.retry
		BPL .data

Start:
		LDY $F6				; ***
		LDA $F7				; MOVW YA, $F6	; ***OK?
		STY 0				; ***
		STA 1				; MOVW $00, YA	; ***OK?
		LDY $F4				; ***
		LDA $F5				; MOVW YA, $F4	; ***OK?
		STA $F4				; MOV $F4, A
		TYA					; MOV A, Y
		TAX					; MOV X, A
		BNE Block
	JMP (0, X)				; JMP ($0000+X)	; ***OK?


	.word	RESET			; dw RESET
