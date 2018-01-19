; firmware module for minimOS on run65816
; (c)2018 Carlos J. Santisteban
; last modified 20180119-0949

; *** direct print splash string ***
; NMOS and 65816 savvy

.(
	LDX #0				; reset index
fws_loop:
		LDA fw_splash, X	; get char, standard label from FW template
			BEQ fws_cr			; no more to print
; as direct print uses no regs, nothing to save and reload
		JSR $c0c2			; *** EhBASIC output ***
		INX					; next char
		_BRA fws_loop		; eeeek
fws_cr:
	LDA #LF				; trailing CR, needed by console!
	JSR $c0c2			; direct print
.)
