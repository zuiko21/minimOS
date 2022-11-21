; Convert an 16 bit binary value to BCD
;
; This function converts a 16 bit binary value into a 24 bit BCD. It
; works by transferring one bit a time from the source and adding it
; into a BCD value that is being doubled on each iteration. As all the
; arithmetic is being done in BCD the result is a binary to decimal
; conversion. All conversions take 915 clock cycles.
;
; See BINBCD8 for more details of its operation.
;
; Andrew Jacobs, 28-Feb-2004

		.ORG $0200

BINBCD16:	SED		; Switch to decimal mode
		LDA #0		; Ensure the result is clear
		STA BCD+0
		STA BCD+1
		STA BCD+2
		LDX #16		; The number of source bits

CNVBIT:		ASL BIN+0	; Shift out one bit
		ROL BIN+1
		LDA BCD+0	; And add into result
		ADC BCD+0
		STA BCD+0
		LDA BCD+1	; propagating any carry
		ADC BCD+1
		STA BCD+1
		LDA BCD+2	; ... thru whole result
		ADC BCD+2
		STA BCD+2
		DEX		; And repeat for next bit
		BNE CNVBIT
		CLD		; Back to binary

		BRK		; All Done.

; A test value to be converted

		.ORG $0300

BIN		.DW  12345
BCD		.DS  3
