; firmware module for minimOS
; (c) 2019-2021 Carlos J. Santisteban
; last modified 20190225-0838

; ****************************************
; CONIO, simple console driver in firmware
; ****************************************
;	INPUT
; Y <-	char to be printed (1...255)
;		0	= ask for one character (non-locking)
;		12	= clear screen AND initialise device
;	OUTPUT
; C ->	no available char (if Y was 0)
; NMOS and 65816 savvy

.(
	TYA					; check mode (and put into A, just in case)
	BEQ cn_in			; Y=0 means input mode
		CMP #CR				; newline?
		BNE cn_ncr			; UNIX uses LF instead
			LDA #LF
;			BNE cn_out			; no need for BRA... and may fall directly into cn_out
cn_ncr:
;		CMP #FORMFEED		; reset device?
;		BNE cn_out			; no, just print it
; *** no way to initialise run816, just keep this as a template ***
cn_out:
		JSR $c0c2
cn_end:
		_DR_OK			; make sure C is clear
cn_in:
	JSR $c0bf
	TAY					; check received character
	BEQ cn_empty		; nothing here, keep trying
		CPY #LF				; UNIX-like linefeed?
		BNE cn_end			; no, just return it
			LDY #CR				; otherwise use minimOS newline instead!
			BNE cn_end
cn_empty:
	_DR_ERR(EMPTY)			; set C instead eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
.)
