; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181107-1047

; ************************
; INSTALL, copy jump table
; ************************
;		INPUT
; Y		= API_SIZE, 0 means 256-byte table ***new***
; kerntab	= address of supplied pointer table
;			NULL means reset from previously installed one
;		OUTPUT
; kerntab	= previously installed jump table
; uses tmp_ktab

-install:
.(
#ifdef	SAFE
	CPY #API_SIZE & $FF	; fits current firmware?
	BCC fwi_ok			; yeah, proceed
	BEQ fwi_ok			; good enough
		_ERR(FULL)			; otherwise, not enough room for that kernel!
fwi_ok:
#endif
; first get current address, not worth a subroutine
	LDX fw_lastk		; get last value...
	LDA fw_lastk+1
	STX tmp_ktab		; ...temporarily stored
	STA tmp_ktab+1
; new feature, a null pointer means reinstall previously set jump table!
	LDA kerntab+1		; check whether null (cannot be in zeropage anyway)
	BNE fwi_nz			; not zero, proceed...
		LDA tmp_ktab+1		; otherwise get lost MSB @ local1
		STX kerntab			; reset to previous value
		STA kerntab+1
fwi_nz:
	STA fw_lastk+1		; MSB is ready
	LDA kerntab			; do LSB too
	STA fw_lastk		; ...and store as last valid pointer!
; end of new feature, remove if not required
	_CRITIC				; disable interrupts! (5)
fwi_loop:
		DEY					; new backwards loop
		LDA (kerntab), Y	; get from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4+2)
		TYA					; have to check whether ended
		BNE fwi_loop		; until whole page is done (3/2)
; kernel successfully installed, return previously set address (LSB still in X)
	LDA tmp_ktab+1		; get missing MSB...
	STX kerntab			; ...and set whole pointer as output
	STA kerntab+1
; end of table address storage
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; all done (8)
.)
