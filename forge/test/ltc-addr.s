; latch addressing test
; (c) 2020 Carlos J. Santisteban
; last modified 20201214-2357

	.zero

	* = 2

ptr	.dsb	1

	.text

	* = $C000

reset:
; init stuff ** 1+15+3 bytes **
	SEI

	LDX #$FF
	TXS
	LDY #$F0
	STY !ptr
	STX !ptr+1
	LDY #0
	LDX #100

	JMP exec

	.asc	0, "LATCH TESTER", 0
	.dsb	223, $FF		; some ID, we need 256-byte blocks anyway

exec:
; print $FF ** 28+3 = 31 bytes **
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01111000		; F
		LDA #%01110010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; 0.5s total as X was 100

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $FE
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01110000		; E
		LDA #%01110010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $FD
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $FC
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01110001		; C
		LDA #%01110010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $FB
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%11010000		; B
		LDA #%11010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $FA
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011000		; A
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F9
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011100		; 9
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F8
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010000		; 8
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F7
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011111		; 7
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F6
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01010000		; 6
		LDA #%01010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F5
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01010100		; 5
		LDA #%01010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F4
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10011100		; 4
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F3
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010110		; 3
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F2
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00110010		; 2
		LDA #%00110010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F1
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10011111		; 1
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $F0
;	.byt	%01111000		; F
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $E0
;	.byt	%01110000		; E
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $D0
;	.byt	%10010010		; D
		LDA #%10011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $C0
;	.byt	%01110001		; C
		LDA #%01111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $B0
;	.byt	%11010000		; B
		LDA #%11011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $A0
;	.byt	%00011000		; A
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $90
;	.byt	%00011100		; 9
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $80
;	.byt	%00010000		; 8
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $70
;	.byt	%00011111		; 7
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $60
;	.byt	%01010000		; 6
		LDA #%01011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $50
;	.byt	%01010100		; 5
		LDA #%01011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $40
;	.byt	%10011100		; 4
		LDA #%10011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $30
;	.byt	%00010110		; 3
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01100100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $20
;	.byt	%00110010		; 2
		LDA #%00111000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $FF		; padding up to page boundary

; print $10
;	.byt	%10011111		; 1
		LDA #%10011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $0F
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01111000		; F
		LDA #%01110010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $0E
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $0D
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $0C
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $0B
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $0A
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $09
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $08
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $07
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $06
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $05
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $04
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $03
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $02
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $01	* STACK *
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $FF		; padding up to page boundary

; print $00	* ZEROPAGE *
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE *-29			; stay 0.5s

	.dsb	225, $FF		; padding up to page boundary

lock:
; print '..' at regular port address
	LDX #FF
	STX ptr+1				; back to $FFF0
;	.byt	%11101111		; .
		LDA #%11101000		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%11101111		; .
		LDA #%11100010		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110001		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		JMP lock			; stay forever!


; *** filling ***
	.dsb	$FFFA-*, $FF	; ROM filling

; HW vectors
vectors:
	.word	lock			; NMI
	.word	reset
	.word	lock			; IRQ/BRK
