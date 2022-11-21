; from 6502.org/source/integers/hex2dec.htm

; Convert a 16 bit binary value to BCD
; table-driven, by Garth Wilson

; *** assuming data in ZP, final string and tables elsewhere ***
; whole stuff takes 133b, 

						; The table below has high byte first just to
						; make it easier to see the number progression. (48 bytes)
TABLE:	.byt	0,  0,  1,		0,  0,  2,		0,  0,  4,		0,  0,  8
		.byt	0,  0,$16,		0,  0,$32,		0,  0,$64,		0,  1,$28
		.byt	0,  2,$56,		0,  5,$12,		0,$10,$24,		0,$20,$48
		.byt	0,$40,$96,		0,$81,$92,		1,$63,$84,		3,$27,$68


; actual conversion code takes 44b, 364-1068t
HTD:	SED				; Output gets added up in decimal. (2)

		STZ BCD			; Inititalize output as 0. (3*3)
		STZ BCD+1		; (NMOS 6502 will need LDA#0, STA...)
		STZ BCD+2

		LDX #2DH		; 2DH is 45 decimal, or 3x15 bits. (2)
loop:	ASL BIN			; (0 to 15 is 16 bit positions.) (16* (5+5))
		ROL BIN+1		; If the next highest bit was 0,
		BCC htd1s		; then skip to the next bit after that. (16* either 3 or 37)
		LDA BCD			; But if the bit was 1,
		CLC				; get ready to
		ADC TABLE+2,X	; add the bit value in the table to the
		STA BCD			; output sum in decimal--  first low byte,
		LDA BCD+1		; then middle byte,
		ADC TABLE+1,X
		STA BCD+1
		LDA BCD+2		; then high byte,
		ADC TABLE,X		; storing each byte
		STA BCD+2		; of the summed output in BCD.

htd1s:	DEX				; By taking X in steps of 3, we don't have to (16* (3*2+3)-1)
		DEX				; multiply by 3 to get the right bytes from the
		DEX				; table.
		BPL loop

		CLD				; (2)
;		RTS

; *** standard BCD-to-ASCII code follows, like div10aj.s ***
; string-generating code below is 42b, 161t (assuming all ZP but str)
		LDX #0			; reset index (2+3)
		LDA BCD+2
		JSR prndec		; only LSN is printed (6+18)
		LDA BCD+1
		JSR prnbcd		; first MSN, then LSN (3+56)
		LDA BCD
		JSR prnbcd		; last one (needed for the terminator) (3+56)
		LDA #0
		STA str, X		; terminate string (2+6+6)
		RTS

prnbcd:					; all this takes 38+18=56t
		TAY				; save value for LSN (make sure Y is intact!)
		LSR
		LSR
		LSR
		LSR				; MSN only, over 16
		JSR prndec		; print this number 0-9
		TYA				; retrieve value
		AND #15			; LSN only

prndec:					; all this takes 18t
		CLC
		ADC #'0'		; BCD to ASCII
		STA str, X		; place char
		INX				; next
		RTS
