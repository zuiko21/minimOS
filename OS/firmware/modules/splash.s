; firmware module for minimOS on run65816
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20190222-1218

; *** direct print splash string ***
; NMOS and 65816 savvy

.(
	LDX #0				; reset index
fws_loop:
		LDA fw_splash, X	; get char, standard label from FW template
			BEQ fws_cr			; no more to print
; now using CONIO!
		TAY				; set CONIO parameter
		_PHX			; fw call will affect it!
		_ADMIN(CONIO)
		_PLX
		INX					; next char
		BNE fws_loop		; will abort instead of hanging
fws_cr:
	LDY #CR				; trailing CR, needed by console!
	_ADMIN(CONIO)
.)
