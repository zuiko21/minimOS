; firmware module for minimOS
; 16 KiB ROM checksum routine 0.9.6a3
; based on Fletcher-16 algorithm
; expects signature value at $FFDE-$FFDF for a final checksum of 0
; relocate down $A000 bytes in case of DOWNLOADable module
; designed for Durango, suitable for most!
; (c) 2021 Carlos J. Santisteban
; last modified 20210915-2234

; *** note computed checksum is expected to be ZERO thanks to the word stored at $FFDE (sum)-$FFDF (chk)
; make that $5FDE-$5FDF for DOWNLOAD option
.(
; *** declare some temprorary vars ***
ptr		= z_used
sum		= z_used+2
chk		= z_used+3			; sum of sums

; new scheme takes 44b, 426kt -- much less size than old compact, even faster than old original!
; *** compute checksum *** initial setup is 12b, 16t
#ifdef	DOWNLOAD
	LDX #$40				; MSB of downloaded 8K
#else
	LDX #$E0				; MSB of 8 KiB EPROM ($E000)
#endif
	STX ptr+1				; temporary ZP pointer
	LDY #0					; this will reset index too
	STY ptr
	STY sum					; reset values too
	STY chk
; *** main loop *** original version takes 20b, 426kt for 16KB ~0.28s on Durango-X
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
		INX					; next page (2)
		STX ptr+1			; update pointer (3)
#ifdef	DOWNLOAD
		CPX #$60			; VRAM is the limit for downloaded modules
#endif
		BNE loop			; will end at last address! (3...)
; *** now compare computed checksum with ZERO *** 4b
;	LDA chk					; this is the stored value in A, saves two bytes
	ORA sum					; any non-zero bit will show up
	BEQ good				; otherwise, all OK!
; *** this is a special pre-panic routine for Durango-X, L & Proto *** 12b
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
