; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20180131-1226

; ************************
; INSTALL, copy jump table
; ************************
;		INPUT
; kerntab	= address of supplied pointer table
;			NULL means reset from previously installed one
;		OUTPUT
; kerntab	= previously installed jump table
; uses local1

-install:
.(
; first get current address, not worth a subroutine
	LDX fw_lastk		; get last value...
	LDA fw_lastk+1
	STX local1			; ...temporarily stored
	STA local1+1
; new feature, a null pointer means reinstall previously set jump table!
	LDY kerntab			; get this LSB for later
	LDA kerntab+1		; check whether null (cannot be in zeropage anyway)
	BNE fwi_nz			; not zero, proceed...
		LDA loca11+1		; otherwise get lost MSB @ local1
		STX kerntab			; reset to previous value
		STA kerntab+1
fwi_nz:
	STY fw_lastk		; ...and store as last valid pointer!
	STA fw_lastk+1
; end of new feature, remove if not required
	LDY #0				; reset index (2)
	_CRITIC				; disable interrupts! (5)
fwi_loop:
		LDA (kerntab), Y	; get from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4+2)
		INY
		CPY #API_SIZE		; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
		BNE fwi_loop		; until whole page is done (3/2)
; kernel successfully installed, return previously set address (LSB still in X)
	LDA local1+1		; get missing MSB...
	STX kerntab			; ...ans set whole pointer as output
	STA kerntab+1
; end of table address storage
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; all done (8)
.)
