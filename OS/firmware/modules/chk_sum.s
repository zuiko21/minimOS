; firmware module for minimOS
; (c) 2021 Carlos J. Santisteban
; last modified 20211227-1741

; *******************************
; CHK_SUM, verify Fletcher-16 sum v0.9.6a4
; *******************************
;		INPUT
; st_pg		= start page
; af_pg		= page after block (0 for regular ROMs)
; skipg		= IO page to skip (usually $DF)
;		OUTPUT
; f16sum	= basic sum of bytes
; f16chk	= sum of sums
; C <- result is not zero

; usually expects signature value at $FFDE(sum)-$FFDF(chk) for a final checksum of 0 (assuming ends at $FFFF)
; just reserve a couple of bytes for checksum matching

; NMOS savvy

.(
; *** declare some temporary vars ***
ptr		= cio_pt			; local space
sum		= f16sum			; included as output parameters
chk		= f16chk			; sum of sums

; new scheme takes 44b, 426kt -- much less size than old compact, even faster than old original!
; *** compute checksum *** initial setup is 12b, 16t
	LDX st_pg				; start page as per interface
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
; *** MUST skip IO page (usually $DF), very little penalty though ***
		CPX skipg			; I/O space?
		BNE f16_noio
			INX				; skip it!
f16_noio:
		STX ptr+1			; update pointer (3)
		CPX af_pg			; VRAM is the limit for downloaded modules, otherwise 0
		BNE loop			; will end at last address! (3...)
; *** now compare computed checksum with ZERO *** 4b
;	LDA chk					; this is the stored value in A, saves two bytes
	ORA sum					; any non-zero bit will show up
	BEQ good				; otherwise, all OK!
; *** non-zero is invalid, sum & check as output parameters for checking ***
		_DR_ERR(CORRUPT)
good:
	_DR_OK					; no errors
.)
