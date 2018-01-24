; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180124-1240

; ************************
; INSTALL, copy jump table
; ************************
;		INPUT
; kerntab	= address of supplied pointer table (16b)
;			NULL means reset from previously installed one
; size irrelevant

install:
.(
	_CRITIC			; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
	LDA kerntab			; get whole pointer (16b as all kernels!)
	BNE fwi_nz			; not zero, proceed
		LDA fw_lastk		; or get last value (16b)
		STA kerntab			; set parameter as previous value
fwi_nz:
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA fw_table, Y		; copy where the firmware expects it (6)
		INY					; advance two bytes (2+2)
		INY
		CPY #API_SIZE & $FF	; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK (must be 8-bit, too)
		BNE fwi_loop		; until whole TABLE is done (3/2)
; perhaps could do up to LAST_API && %11111110, then check whether extra byte or not outside the loop
	_NO_CRIT			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)
.)
	.as: .xs
