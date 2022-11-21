; from 6502.org/source/integers/hex2dec-more.htm

; Convert a 16 bit binary value to BCD
;
; This function converts a 16 bit binary value into a 24 bit BCD. It
; works by transferring one bit a time from the source and adding it
; into a BCD value that is being doubled on each iteration. As all the
; arithmetic is being done in BCD the result is a binary to decimal
; conversion. All conversions take 915 clock cycles.
;
; Andrew Jacobs, 28-Feb-2004

; will take 79b, ~0.583 ms in Durango-X
BINBCD16:
		SED			; Switch to decimal mode (2)
;		LDA #0		; Ensure the result is clear (3*3)
		STZ BCD+0
		STZ BCD+1
		STZ BCD+2
		LDX #16		; The number of source bits (2)
CNVBIT:				; whole loop is 671t in NMOS, 719 in CMOS (assuming ZP)
		ASL BIN+0	; Shift out one bit (16*5*2)
		ROL BIN+1
		LDA BCD+0	; And add into result (16*3*3+16)
		ADC BCD+0
		STA BCD+0
		LDA BCD+1	; propagating any carry (16*3*3+16)
		ADC BCD+1
		STA BCD+1
		LDA BCD+2	; ... thru whole result (16*3*3+16)
		ADC BCD+2
		STA BCD+2
		DEX			; And repeat for next bit (16*2)
		BNE CNVBIT	; (16*3-1)
		CLD			; Back to binary (2)
; above code is 37b, 734t (+14 if data not in ZP)
; string-generating code below is 42b, 161t (assuming all ZP but str)
; *** create string, for uniformity sake ***
		LDX #0		; reset index (2+3)
		LDA BCD+2
		JSR prndec	; only LSN is printed (6+18)
		LDA BCD+1
		JSR prnbcd	; first MSN, then LSN (3+56)
		LDA BCD
		JSR prnbcd	; last one (needed for the terminator) (3+56)
		LDA #0
		STA str, X	; terminate string (2+6+6)
		RTS

prnbcd:				; all this takes 38+18=56t
		TAY			; save value for LSN (make sure Y is intact!)
		LSR
		LSR
		LSR
		LSR			; MSN only, over 16
		JSR prndec	; print this number 0-9
		TYA			; retrieve value
		AND #15		; LSN only

prndec:				; all this takes 18t
		CLC
		ADC #'0'	; BCD to ASCII
		STA str, X	; place char
		INX			; next
		RTS
