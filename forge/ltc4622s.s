; LTC-4622 simple driver (single 2 1/2 digits mux. display)
; 2-hex char string pointed from zeropage
; an independent string is used as an AND mask for the bitmaps, enabling Decimal Point ($EF)
; call periodically for display, takes ~5 ms, port is any write to $FFFx
; port bits 4...7 = pins 5...2 on LEDs (cathodes) -- NOTE ORDER!
; port bits 0...3 = pins 9...6 on LEDs (anodes) -- NOTE ORDER!
; NO access to pin 1 on LEDs (leading "1" cathode, NOT currently used)
; bitmap format is now abc*defg, simplifying both hard and soft
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20201210-1811

	.zero

	* = $F2					; minimOS compatible string address

d_ptr	.dsb 2				; pointer to AND-mask for each bitmap (abc* on MSN only)
c_ptr	.dsb 2				; pointer to hex-string (2 char)
anode	.dsb 1				; index for selected anode
ch_i	.dsb 1				; index for read hex-char


	.text

	* = $FF00

display:
	LDA #%1000				; highest anode select line
	STA anode
	LDA #1
	STA ch_i				; pointing to last character
cloop:
		LDY ch_i			; retrieve index
		LDA (c_ptr), Y		; read pointed character
		TAX					; use as bitmap index
		LDA bitmap, X		; get pattern
		AND (d_ptr), Y		; apply the mask, in case a dot is shown
		AND #$F0			; keep MSN only
		JSR disdel			; enable anode and make delay
		LDA bitmap, X		; get pattern again
; could add here AND with the mask for d...g segments, but retrieving Y index, not really worth it
		ASL					; will set LSN as MSN (mask won't apply as no DP here)
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
	LSR anode				; enable next anode, non decoded version
	RTS

; *** bitmap ***
; being cathodes, 0 means ON
bitmap:
;			 abc*defg
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
	.byt	%00011000		; A
	.byt	%11010000		; B
	.byt	%01110001		; C
	.byt	%10010010		; D
	.byt	%01110000		; E
	.byt	%01111000		; F
	.byt	$FF				; special blank value (16)
