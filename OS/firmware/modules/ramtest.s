; firmware module for minimOS
; RAMtest 0.5.2b2
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180201-1321

; *** RAMtest, 6510-savvy ***
; check zeropage first (except bytes 0-1)

.(
	LDX #$FD		; bytes to check, 6510-savvy
	LDA #$FE		; value to be written, 6510-savvy
rt_fill:
		STA z_used, X	; store different values, 6510-savvy
		CMP z_used, X	; check if properly stored
		BEQ ram_nfail
			JMP lock		; serious RAM failure
ram_nfail:
		DEX				; go to previous byte
		_DEC			; change value, strange correction 20150309
		BNE rt_fill		; fill out zero-page
	LDX $82			; check for mirroring, should be $81 w/o or $1 with
	BMI	rtest		; not a 128-byte system (BPL if it's)
		STA himem		; A known to be zero, thus no STZ macro; assume it's 128-byte RAM (not less)
		_BRA ram_ok		; skip measuring number of pages
rtest:
	LDA #1			; zeropage already checked
	LDY #3			; best offset (minus 1) suitable for SDd (goes into T1CL, which won't pass the test)
	STA z_used+1	; set pointer MSB
	STY z_used		; (re)set pointer LSB, avoids NMOS macro
	LDA #$55		; initial pattern
	LDX #SRAM		; get last page
rt_chk:
		STA (z_used), Y	; store it
		CMP (z_used), Y	; and check it
			BNE measure		; most likely the end of decoded SRAM
		EOR #$FF		; reverse pattern
		BMI rt_chk		; try once again
	CPX z_used+1	; end of SRAM?
	BEQ measure		; exit then
		INC z_used+1	; next page otherwise
		BNE rt_chk		; no need for BRA
measure:
	DEC z_used+1	; last page is one less
	LDX z_used+1	; keep for mirroring check
rt_page:
		LDA z_used+1	; data to be written
		STA (z_used), Y	; store value
		LSR z_used+1	; try half the amount
		BNE rt_page		; until we get to zeropage
	STX z_used+1	; last page number
	LDA (z_used), Y	; value at last actual page
	_INC			; add one for number of pages
	STA himem		; SRAM pages found
ram_ok:
; *** SRAM already measured and tested ***
.)
