; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180131-1232

; ************************
; INSTALL, copy jump table
; ************************
;		INPUT
; kerntab	= address of supplied pointer table (16b)
;			NULL means reset from previously installed one
;		OUTPUT
; kerntab	= previously installed jump table (16b)
; size irrelevant

-install:
.(
	_CRITIC			; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
; first get current address, not worth a subroutine
	LDA fw_lastk			; previous jump table... (5)
	STA tmp_ktab			; ...temporarily stored (4)
; proceed
	LDA kerntab			; get whole pointer, 16b as all kernels! (4)
	BNE fwi_nz			; not zero, proceed (3/2)
		LDA tmp_ktab		; or get last value, new faster address (4)
		STA kerntab			; set parameter as previous value (4)
fwi_nz:
	STA fw_lastk		; eeeeeeeeeeeeeeek (5)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA fw_table, Y		; copy where the firmware expects it (6)
		INY					; advance two bytes (2+2)
		INY
		CPY #API_SIZE & $FF	; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK (must be 8-bit, too)
		BNE fwi_loop		; until whole TABLE is done (3/2)
	LDA tmp_ktab		; set previous table...
	STA kerntab			; ...as output
	_NO_CRIT			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)
.)
	.as: .xs
