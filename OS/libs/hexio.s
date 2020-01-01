; shared library for minimOS
; hexadecimal routines
; version 0.5rc2, seems OBSOLETE since 2016
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20160512-0853

#ifndef	HEXIO
#define		HEXIO	_HEXIO

; *** needs two bytes of storage at tmp (not necessaryly in zeropage) ***
; *** iodev holds device number for standard output (not necessaryly in zeropage) ***

; * print a character in A *
prnChar:
	STA io_c			; store character
	LDY iodev			; get device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print a NULL-terminated string pointed by $AAYY *
prnStr:
	STA str_pt+1		; store MSB
	STY str_pt			; LSB
	LDY iodev			; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS

; * convert two hex ciphers into byte@tmp, A is current char, X is cursor *
hex2byte:
	LDY #0				; reset loop counter
	STY tmp				; also reset value
h2b_l:
		SEC					; prepare
		SBC #'0'			; convert to value
			BCC h2b_err			; below number!
		CMP #10				; already OK?
		BCC h2b_num			; do not shift letter value
			CMP #23			; should be a valid hex
				BCS h2b_err			; not!
			SBC #6			; convert from hex (had CLC before!)
h2b_num:
		ASL tmp				; older value times 16
		ASL tmp
		ASL tmp
		ASL tmp
		ORA tmp				; add computed nibble
		STA tmp				; and store full byte
		JSR gnc_do			; go for next hex cipher *** THIS IS OUTSIDE THE LIB ***
		INY					; loop counter
		CPY #2				; two ciphers per byte
		BNE h2b_l			; until done
	RTS					; value is at tmp
h2b_err:
	DEX					; will try to reprocess this char
	RTS

; * print a byte in A as two hex ciphers *
prnHex:
	JSR ph_conv			; first get the ciphers done
	LDA tmp				; get cipher for MSB
	JSR prnChar			; print it!
	LDA tmp+1			; same for LSB
	JMP prnChar  ; will return
ph_conv:
	STA tmp+1			; keep for later
	AND #$F0			; mask for MSB
	LSR					; convert to value
	LSR
	LSR
	LSR
	LDY #0				; this is first value
	JSR ph_b2a			; convert this cipher
	LDA tmp+1			; get again
	AND #$0F			; mask for LSB
	INY					; this will be second cipher
ph_b2a:
	CMP #10				; will be letter?
	BCC ph_n			; numbers do not need this
		ADC #'A'-'9'-2		; turn into letter, C was set
ph_n:
	ADC #'0'			; turn into ASCII
	STA tmp, Y
	RTS

#endif
