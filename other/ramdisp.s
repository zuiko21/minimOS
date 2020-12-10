; display detected non-mirrored RAM on mux. display
; (c) 2020 Carlos J. Santisteban

; *** to be integrated with ramprobe.s and ltc4622s.s ***

	.zero

hexstr	.dsb	4			; room for 4 hex-chars
dp_str	.dsb	2			; decimal point pattern (will change)
count	.dsb	1			; delay counter

	.text

; * convert 16-bit value into 4 hex-char *
	LDX #1					; byte index
	LDY #3					; hex-char index
str_loop:
		LDA chkptr, X		; get this byte
		AND #$0F			; LSN only
; might convert to ASCII here
		STA hexstr, Y		; store non-ASCII value (absolute)
		DEY
		LDA chkptr, X		; get this byte again
		LSR					; MSN down x16
		LSR
		LSR
		LSR
; might convert to ASCII here
		STA hexstr, Y		; two hex-chars complete
		DEY
		DEX
		BPL str_loop		; go for value MSB

; * display size in loop *
	LDY #<dp_str			; fixed pointer to DP string
	LDX #>dp_str
	STY d_ptr
	STX d_ptr+1
	LDY #<hexstr			; get pointer to highest hex-chars
;	LDX #>hexstr
	STY c_ptr
	STX c_ptr+1				; all in ZP, no need to reload MSB
	LDA #$FF				; DP is off
	STA dp_str				; first char never has it
	STA dp_str+1			; ...neither second char, this time
cyc_loop:
		LDA #200			; about 1-sec delay
		STA count
ds_loop:
			JSR display
			DEC count
			BNE dh_loop
		LDA dp_str+1		; get DP status for second char
		EOR #$10			; toggle DP
		STA dp_str+1
; toggle somehow +/-2 c_ptr!
		AND #$10			; just keep updated D4 (is zero about to show LSB)
		EOR #$10			; we need the opposite
		LSR
		LSR
		LSR					; divide-by-8 for the offset of two... and clear C!
		ADC #<hexstr		; base pointer
		STA c_ptr			; display routine parameter updated
		JMP cyc_loop		; display forever
