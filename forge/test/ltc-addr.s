; latch addressing test
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20210124-0110

#define	DOWNL	_DOWNL

	.zero

	* = 2

ptr	.dsb	1

	.text

#ifndef	DOWNL
	addr = $C000
#else
	addr = $0400	; standard download address, anything up to $4000 will do
#endif

	* = addr

reset:
; init stuff ** 2+15+3 bytes **
	SEI
	CLD						; eeeeeek

	LDX #$FF
	TXS
	LDY #$F0
	STY !ptr
	STX !ptr+1

; initial register values
	LDY #0
	LDX #100

	JMP exec

	.dsb	addr+$20-*, $FF
	.asc	"LTC-4622 LATCH TESTER", 0
	.dsb	addr+$100-*, $FF	; some ID, we need 256-byte blocks anyway

exec:
; *** test start, highest addresses should be OK for LTC ***
; print $FF ** 28+3 = 31 bytes **
_ff:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1 eeeeeek
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01111000		; F
		LDA #%01111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _ff				; 0.5s total as X was 100

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary EEEEEEEEEEEEEK

; print $FE
_fe:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01110000		; E
		LDA #%01111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _fe				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $FD
_fd:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _fd				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $FC
_fc:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01110001		; C
		LDA #%01111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _fc				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $FB
_fb:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%11010000		; B
		LDA #%11011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _fb				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $FA
_fa:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011000		; A
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _fa				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F9
_f9:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011100		; 9
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f9				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F8
_f8:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010000		; 8
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f8				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F7
_f7:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011111		; 7
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f7				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F6
_f6:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01010000		; 6
		LDA #%01011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f6				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F5
_f5:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01010100		; 5
		LDA #%01011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f5				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F4
_f4:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10011100		; 4
		LDA #%10011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f4				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F3
_f3:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010110		; 3
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01100100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f3				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F2
_f2:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00110010		; 2
		LDA #%00111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f2				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F1
_f1:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10011111		; 1
		LDA #%10011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f1				; stay 0.5s

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	221, $EA		; padding up to page boundary

; print $F0
_f0:
;	.byt	%01111000		; F
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _f0				; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $EA		; padding up to page boundary

; print $E0
_e0:
;	.byt	%01110000		; E
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _e0				; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $EA		; padding up to page boundary

; print $D0
_d0:
;	.byt	%10010010		; D
		LDA #%10010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _d0				; stay 0.5s

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	216, $EA		; padding up to page boundary

; print $C0
_c0:
;	.byt	%01110001		; C
		LDA #%01110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _c0				; stay 0.5s
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	213, $EA		; padding up to page boundary

; *** from now on, muxed data won't show on LTC, scan display once at least ***
; print $B0
_b0:
;	.byt	%11010000		; B
		LDA #%11010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _b0				; stay 0.5s
; re-send display to actual LTC
		LDA #%11010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $A0
_a0:
;	.byt	%00011000		; A
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _a0				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%10000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $90
_90:
;	.byt	%00011100		; 9
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _90				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%11000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $80
_80:
;	.byt	%00010000		; 8
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _80				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; *** this area may be dangerous as may corrupt RAM contents ***
; print $70
_70:
;	.byt	%00011111		; 7
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _70				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%11110001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $60
_60:
;	.byt	%01010000		; 6
		LDA #%01010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _60				; stay 0.5s
; re-send display to actual LTC
		LDA #%01010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $50
_50:
;	.byt	%01010100		; 5
		LDA #%01010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _50			; stay 0.5s
; re-send display to actual LTC
		LDA #%01010010		; MSN1
		STA $FFF0			; put on port
		LDA #%01000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $40
_40:
;	.byt	%10011100		; 4
		LDA #%10010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _40				; stay 0.5s
; re-send display to actual LTC
		LDA #%10010010		; MSN1
		STA $FFF0			; put on port
		LDA #%11000001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $30
_30:
;	.byt	%00010110		; 3
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01100001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _30				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%01100001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $20
_20:
;	.byt	%00110010		; 2
		LDA #%00110010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _20				; stay 0.5s
; re-send display to actual LTC
		LDA #%00110010		; MSN1
		STA $FFF0			; put on port
		LDA #%00100001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page*16, takes 9 bytes
	LDX #100
	LDA ptr+1
	SEC
	SBC #$10
	STA ptr+1

	.dsb	190, $EA		; padding up to page boundary

; print $10
_10:
;	.byt	%10011111		; 1
		LDA #%10010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _10				; stay 0.5s
; re-send display to actual LTC
		LDA #%10010010		; MSN1
		STA $FFF0			; put on port
		LDA #%11110001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $0F
_0f:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01111000		; F
		LDA #%01111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _0f			; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%01111000		; MSN2
		STA $FFF0			; put on port
		LDA #%10000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $0E
_0e:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01110000		; E
		LDA #%01111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _0e			; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%01111000		; MSN2
		STA $FFF0			; put on port
		LDA #%00000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $0D
_0d:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10010010		; D
		LDA #%10011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _0d				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%10011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00100100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $0C
_0c:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01110001		; C
		LDA #%01111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _0c				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%01111000		; MSN2
		STA $FFF0			; put on port
		LDA #%00010100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $0B
_0b:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%11010000		; B
		LDA #%11011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _0b				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%11011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $0A
_0a:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011000		; A
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%10000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _0a				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%10000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $09
_09:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011100		; 9
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _09				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%11000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $08
_08:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010000		; 8
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _08				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $07
_07:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00011111		; 7
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _07				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%11110100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $06
_06:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01010000		; 6
		LDA #%01011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _06				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%01011000		; MSN2
		STA $FFF0			; put on port
		LDA #%00000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $05
_05:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%01010100		; 5
		LDA #%01011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _05				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%01011000		; MSN2
		STA $FFF0			; put on port
		LDA #%01000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $04
_04:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10011100		; 4
		LDA #%10011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11000100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _04				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%10011000		; MSN2
		STA $FFF0			; put on port
		LDA #%11000100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $03
_03:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010110		; 3
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%01100100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _03				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%00011000		; MSN2
		STA $FFF0			; put on port
		LDA #%01100100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $02
_02:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00110010		; 2
		LDA #%00111000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00100100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _02				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%00111000		; MSN2
		STA $FFF0			; put on port
		LDA #%00100100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $01	* STACK *
_01:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%10011111		; 1
		LDA #%10011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _01				; stay 0.5s
; re-send display to actual LTC
		LDA #%00010010		; MSN1
		STA $FFF0			; put on port
		LDA #%00010001		; LSN1
		STA $FFF0			; put on port
		LDA #%10011000		; MSN2
		STA $FFF0			; put on port
		LDA #%11110100		; LSN2
		STA $FFF0			; put on port
		INY
		BNE *-21			; inline delay
	STX $FFF0				; *** clear display ***

; next tested page, takes just 4 bytes
	LDX #100
	DEC ptr+1

	.dsb	195, $EA		; padding up to page boundary

; print $00	* ZEROPAGE *
_00:
;	.byt	%00010001		; 0
		LDA #%00010010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%00010001		; 0
		LDA #%00011000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%00010100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
; repeat display for a while
		DEX
		BNE _00				; stay 0.5s
; *** no need to show anything else as is the end of the test ***
; ...BUT FIRST DISABLE INTERRUPT, FOR GOD'S SAKE!
	LDA $AFF0				; any ODD address will do

	.dsb	222, $EA		; padding up to page boundary

lock:
; print '..' at regular port address
	LDX #$FF
	STX ptr+1				; back to $FFF0
;	.byt	%11101111		; .
		LDA #%11100010		; MSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110001		; LSN1
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
;	.byt	%11101111		; .
		LDA #%11101000		; MSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		LDA #%11110100		; LSN2
		STA (ptr), Y		; put on port
			INY
			BNE *-1			; inline delay
		JMP lock			; stay forever!

#ifndef	DOWNL
; *** filling ***
	.dsb	$FFFA-*, $FF	; ROM filling

; HW vectors
vectors:
	.word	lock			; NMI
	.word	reset
	.word	lock			; IRQ/BRK
#endif
