; LTC-4622 driver (2x 2 1/2 digits mux. display)
; 4 ASCII char string pointed from zeropage
; call periodically for display, takes ~10 ms, port is any write to $FFFx
; port bits 4...7 = pins 5...2 on LEDs (cathodes) -- NOTE ORDER!
; port bit 3 might be connected to pin 1 on LEDs, but software must set d3 on port (leading "1" cathode, NOT currently used)
; port bits 0...2 = 3-to-8 decoder input ('238 -> '245 or '138 -> '240)
; (buffered) decoder outputs 0...7 go to anode pins on LEDs A9...A6, then B9...B6 -- NOTE ORDER!
; bitmap format is now abc*defg, simplifying both hard and soft
; (c) 2020 Carlos J. Santisteban
; last modified 20201217-1817

	.zero

	* = $F4					; minimOS compatible string address

c_ptr	.dsb 2				; pointer to string (4 char)
anode	.dsb 1				; index for selected anode
ch_i	.dsb 1				; index for read char


	.text

	* = $FF00

display:
	LDA #7					; max anode index
	STA anode
	LSR						; now it's 3
	STA ch_i				; pointing to last character
cloop:
		LDY ch_i			; retrieve index
		LDA (c_ptr), Y		; read pointed character
; might use bit 7 as emphasis, perhaps setting (or inverting) decimal point
		SEC
		SBC #32				; only printable ASCII
		AND #$7F			; just in case
		TAX					; use as bitmap index
		LDA bitmap, X		; get pattern
		AND #$F0			; keep MSN only
;		ORA #%1000			; set D3 if connected to pin 1 *** COMMENT otherwise ***
		JSR disdel			; enable anode and make delay
		LDA bitmap, X		; get pattern again
		ASL					; will set LSN as MSN
		ASL
		ASL
		ASL
		JSR disdel			; enable, store and delay
		DEC ch_i			; back to previous character
		BPL cloop
	RTS

; *** delay routine ***
disdel:
	ORA anode				; add anode selection to cathode pattern
	STA $FFF0				; set output port
dl_loop:
		INY
		BNE dl_loop			; about 1.3 ms delay
	DEC anode				; enable next anode
	RTS

; *** bitmap ***
; being cathodes, 0 means ON
bitmap:
;			 abc*defg
	.byt	%11111111		; SPACE
	.byt	%10001111		; !
	.byt	%10111101		; "
	.byt	%10010110		; #
	.byt	%01010101		; $
	.byt	%10101010		; %
	.byt	%11111101		; '
	.byt	%01110001		; (
	.byt	%00010111		; )
	.byt	%10011010		; *
	.byt	%10011110		; +
	.byt	%11111011		; ,
	.byt	%11111110		; -
	.byt	%11101111		; .
	.byt	%10111010		; /
	.byt	%00010001		; 0
	.byt	%10011111		; 1
	.byt	%00110010		; 2
	.byt	%00010110		; 3
	.byt	%10011100		; 4
	.byt	%01010100		; 5
	.byt	%01010000		; 6
	.byt	%00011111		; 7
	.byt	%00010000		; 8
	.byt	%00011100		; 9
	.byt	%01110111		; :
	.byt	%11100111		; ;
	.byt	%11110011		; <
	.byt	%11110110		; =
	.byt	%11010111		; >
	.byt	%00101010		; ? 
	.byt	%00010010		; @
	.byt	%00011000		; A
	.byt	%11010000		; B
	.byt	%01110001		; C
	.byt	%10010010		; D
	.byt	%01110000		; E
	.byt	%01111000		; F
	.byt	%01010001		; G
	.byt	%10011000		; H
	.byt	%10011111		; I
	.byt	%00010011		; J
	.byt	%11111000		; K
	.byt	%11110001		; L
	.byt	%00011001		; M
	.byt	%11011010		; N
	.byt	%00010001		; O
	.byt	%00111000		; P
	.byt	%00100001		; Q
	.byt	%11111010		; R
	.byt	%01010100		; S
	.byt	%11110000		; T
	.byt	%10010001		; U
	.byt	%10111000		; V
	.byt	%10000001		; W
	.byt	%10011001		; X
	.byt	%10011101		; Y
	.byt	%00110010		; Z
	.byt	%01110001		; [
	.byt	%11011100		; \ 
	.byt	%00010111		; ]
	.byt	%00111101		; ^
	.byt	%11110111		; _
	.byt	%10111111		; `
	.byt	%00010010		; a
	.byt	%11010000		; b
	.byt	%11110010		; c
	.byt	%10010010		; d
	.byt	%00110000		; e
	.byt	%01111000		; f
	.byt	%00010100		; g
	.byt	%11011000		; h
	.byt	%11011111		; i
	.byt	%10010111		; j
	.byt	%11111000		; k
	.byt	%11110001		; l
	.byt	%00011001		; m
	.byt	%11011010		; n
	.byt	%11010010		; o
	.byt	%00111000		; p
	.byt	%00001100		; q
	.byt	%11111010		; r
	.byt	%11010110		; s
	.byt	%11110000		; t
	.byt	%11010011		; u
	.byt	%10111000		; v
	.byt	%11000011		; w
	.byt	%11011011		; x
	.byt	%10010100		; y
	.byt	%00110010		; z
	.byt	%10011110		; {
	.byt	%11111001		; |
	.byt	%11111000		; }
	.byt	%11111100		; ~
	.byt	%01110110		; DEL
