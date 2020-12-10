; *** LTC-4622 simple driver (2x 2 1/2 digits)
; call periodically for display (4 digits)
; 4-hex char string pointed from zeropage
; takes ~10 ms, port is any write to $FFFx
; (c) 2020 Carlos J. Santisteban
; last modified 20201210-1212

	.zero

	* = $F4					; minimOS compatible string address

c_ptr	.dsb 2				; single parameter, pointer to hex-string (4 char)
anode	.dsb 1				; index for selected anode
ch_i	.dsb 1				; index for read hex-char


	. text

	* = $FF00

	LDA #7					; max anode index
	STA anode
	LSR						; now it's 3
	STA ch_i				; pointing to last character
cloop:
		LDY ch_i			; retrieve index
		LDA (c_ptr), Y		; read pointed character
		TAX					; use as bitmap index
		LDA bitmap, X		; get pattern
		AND #$F0			; keep MSN only
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
; format (MSb to LSb) is gfed*cba, where * is the decimal point (not used)
; being cathodes, 0 means ON
bitmap:
	.byt	%10001000		; 0
	.byt	%11111001		; 1
	.byt	%01001100		; 2
	.byt	%01001000		; 3
	.byt	%00111001		; 4
	.byt	%00101010		; 5
	.byt	%00001010		; 6
	.byt	%11111000		; 7
	.byt	%00001000		; 8
	.byt	%00111000		; 9
	.byt	%00011000		; A
	.byt	%00001011		; B
	.byt	%10001110		; C
	.byt	%01001001		; D
	.byt	%00001110		; E
	.byt	%00011110		; F
	.byt	$FF				; special blank value (16)
