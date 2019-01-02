; firmware module for minimOS·16
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20181107-1050

; ************************
; INSTALL, copy jump table
; ************************
;		INPUT
; Y			= API_SIZE, 0 means whole page ***new***
; kerntab	= address of supplied pointer table (16b)
;			NULL means reset from previously installed one
;		OUTPUT
; kerntab	= previously installed jump table (16b)
; sizes irrelevant, but SAFE option expects to enter in 8-bit indexes (as usually does)

-install:
.(
#ifdef	SAFE
.xs:
	CPY #API_SIZE & $FF	; fits current firmware?
	BCC fwi_ok			; yeah, proceed
	BEQ fwi_ok			; good enough
		_ERR(FULL)			; otherwise, not enough room for that kernel!
fwi_ok:
#endif
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
; first get current address, not worth a subroutine
	LDA fw_lastk		; previous jump table... (5)
	STA tmp_ktab		; ...temporarily stored (4)
; proceed
	LDA kerntab			; get whole pointer, 16b as all kernels! (4)
	BNE fwi_nz			; not zero, proceed (3/2)
		LDA tmp_ktab		; or get last value, new faster address (4)
		STA kerntab			; set parameter as previous value (4)
fwi_nz:
	STA fw_lastk		; eeeeeeeeeeeeeeek (5)
#ifdef	SAFE
; API_SIZE must be even! Will check so
	TYA					; how many entries?
	LSR					; even or odd?
	BCC fwi_loop		; even as expected, proceed
		DEY					; odd, must do single-byte check
		.as: SEP #$20		; 8-bit memory for a moment
		LDA (kerntab), Y	; get word from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (5)
		.al: REP #$20		; back to 16-bit
#endif
fwi_loop:
		DEY					; backwards two bytes (2+2)
		DEY
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA fw_table, Y		; copy where the firmware expects it (6)
		TYX					; check counter LSB, not in A!
		BNE fwi_loop		; until whole TABLE is done (3/2)
	LDA tmp_ktab		; set previous table...
	STA kerntab			; ...as output
	_NO_CRIT			; restore interrupts if needed, will restore sizes too (4)
	_DR_OK				; all done (8)
.)

