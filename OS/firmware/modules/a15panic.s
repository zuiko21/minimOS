; A15 PANIC firmware module
; (c) 2020-2021 Carlos J. Santisteban
; last modified 20200509-1251

; ***********************************************************************************
; *** in case of a gross HW fault (no VIA...) will pulse A15 at 0.33 s intervals) ***
; *** A8 - A14 will pulse together with A15                                       ***
; *** A5 - A7  will stay low (with recommended addresses)                         ***
; *** A4       will stay high (with recommended addresses)                        ***
; *** A2 - A3  will stay low nearly all the time (with recommended addresses)     ***
; ***********************************************************************************

	a15del	= $FF10		; recommended to keep A4 high
	a15zp	= $0010		; exactly $FF00 bytes less, change with above
	a15siz	= a15end-a15del	; delay code size for convenience

; *** zeropage install routine ***

	*	= $FF00		; recommended address

	LDX #a15siz			; number of bytes to be copied
a15p_cp:
		LDA a15del-1, X		; take byte from ROM...
		STA a15zp-1, X		; ...and copy it into Zeropage
		DEX
		BNE a15p_cp		; complete copy
	DEC a15zp+a15siz-1	; will turn JMP $0010 into JMP $FF10, returning to ROM

; *** filler space ***

	.dsb	a15del-*, $EA	; fil with NOPs for A4 alignment

; *** delay loop, about 0.33 s @ 1 MHz ***

	*	= $a15del	; just in case (should be at $FF10 already)

a15del:
			INX
			BNE a15del			; inner loop
		INY
		BNE a15del			; outer loop
	JMP a15zp			; zeropage version will become JMP a15del
a15end:
