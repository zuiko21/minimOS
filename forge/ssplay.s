; SS-22 audio play
; (c) 2018 Carlos J. Santisteban
; last modified 20181206-2210

; add appropriate minimOS headers here!

; this does 51.2 kHz sampling rate @ 2.304 MHz without glitch!
long_l:
		NOP				; add extra delay (16)
		NOP
		JSR delay
mid_l:
		NOP				; (8)
		NOP
		NOP
		NOP
short_l:
; *** add extra delay here, +7 does 44.3 kHz ***
		LDA [pointer], Y	; get audio data (6)
		TAX				; use as index (2)
		LDA dither, X		; convert to dithered pattern (4)
		STA VIA_S+VSR		; send it via SS22 (4)
		INY				; next byte (2)
			BNE long_l		; same page, add delay (3/2) 21 clocks
		INC pointer+1		; next page (5)
		BNE p_nw		; no wrap (3/2)
			INC pointer+2		; or next bank (0/5)
p_nw:
		LDA pointer+1		; compare against limit (3+3)
		CMP end_p
			BNE mid_l		; continue (3/2) 37 clocks
		LDA pointer+2		; compare MSB too (3+3)
		CMP end_p+1
		BNE short_l		; worst case (3) loop 45 clocks
delay:
	RTS
