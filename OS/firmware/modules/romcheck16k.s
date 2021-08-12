; firmware module for minimOS
; 16 KiB ROM checksum routine 0.9.6a2
; suitable for most!
; (c) 2021 Carlos J. Santisteban
; last modified 20210813-0015

; *** note computed checksum is compared against word stored at $FFDE (sum)-$FFDF (chk)
.(
; *** declare some temprorary vars ***
ptr		= z_used
sum		= z_used+2
chk		= z_used+3			; sum of sums

; original version is 93b and ~427kt
; *** compute checksum *** initial setup is 12b, 16t
	LDA #$C0				; MSB of 16 KiB EPROM ($C000)
	STA ptr+1				; temporary ZP pointer
	LDY #0					; this will reset index too
	STY ptr
	STY sum					; reset values too
	STY chk
; *** main loop *** original version takes 23b, for 16K
loop:
			LDA (ptr), Y	; get ROM byte (5+2)
			CLC
			ADC sum			; add to previous (3+3+2)
			STA sum
			CLC
			ADC chk			; compute sum of sums too (3+3+2)
			STA chk
			INY
			BNE loop		; complete one page (3..., 6655t per page)
		INC ptr+1			; next page (5)
		LDX ptr+1			; check whether is the last one (3+2+3..., 420083t for 15.75K)
		CPX #$FF
		BNE loop
; this is the last page, must skip $FFDE-$FFDF, takes 19b, 6217t (including last LDY)
loop2:
		LDA (ptr), Y		; get ROM byte (5+2)
		CLC
		ADC sum				; add to previous (3+3+2)
		STA sum
		CLC
		ADC chk				; compute sum of sums too (3+3+2+2)
		STA chk
		INY
		CPY #$DE
		BNE loop2			; repeat until checksum position (3... 28t per iteration)
	LDY #$E0				; skip checksum (2)
; check remainder of last page, takes 15b, 831t
loop3:
		LDA (ptr), Y		; get ROM byte (5+2)
		CLC
		ADC sum				; add to previous (3+3+2)
		STA sum
		CLC
		ADC chk				; compute sum of sums too (3+3+2)
		STA chk
		INY
		BNE loop3			; repeat until end of ROM (3...)
; *** now compare computed checksum with stored one *** 24 bytes, irrelevant time
;	LDA chk					; this is the stored value in A, saves two bytes
	CMP $FFDF				; sum of sums is the same?
	BNE bad
		LDA sum
		CMP $FFDE			; sum is the same?
	BEQ good				; yes, all OK!
; *** this is a special pre-panic routine for Durango-X, L & Proto ***
bad:
		TYA					; clear A
toggle:
		STA $8000			; set or clear inverse mode
wait:
			INY
			BNE wait		; this takes 1280t or ~13 lines
		EOR #64				; toggle inverse mode
		JMP toggle			; forever!
good:

; ***********************
; *** compact version *** 68b, 550kt
; ***********************
; *** compute checksum *** initial setup is 12b, 16t
	LDX #$C0				; MSB of 16 KiB EPROM ($C000), will keep in register
	STX ptr+1				; temporary ZP pointer
	LDY #0					; this will reset index too
	STY ptr
	STY sum					; reset values too
	STY chk
; main loop is now 32b, ~550kt
loop:
			LDA (ptr), Y	; get ROM byte (5+2)
			CLC
			ADC sum			; add to previous (3+3+2)
			STA sum
			CLC
			ADC chk			; compute sum of sums too (3+3+2)
			STA chk
			INY
			CPY #$DE		; could be at stored checksum? (usually 2+3)
			BNE nskip
				CPX #$FF	; only for the last page
				BNE nskip
					LDY #$E0
nskip:
			CPY #0			; recheck index into page (2+3... 33 per iteration, ~8k5 per page)
			BNE loop
		INX					; next page
		STX ptr+1
		BNE loop
; *** now compare computed checksum with stored one *** 24 bytes, irrelevant time
;	LDA chk					; this is the stored value in A, saves two bytes
	CMP $FFDF				; sum of sums is the same?
	BNE bad
		LDA sum
		CMP $FFDE			; sum is the same?
	BEQ good				; yes, all OK!
; *** this is a special pre-panic routine for Durango-X, L & Proto ***
bad:
		TYA					; clear A
toggle:
		STA $8000			; set or clear inverse mode
wait:
			INY
			BNE wait		; this takes 1280t or ~13 lines
		EOR #64				; toggle inverse mode
		JMP toggle			; forever!
good:
