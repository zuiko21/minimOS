; firmware module for minimOS
; (c) 2019-2022 Carlos J. Santisteban
; last modified 20190414-1339

; ****************************************
; CONIO, simple console driver in firmware
; ****************************************
; template with PASK input support
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
		_DR_ERR(UNAVAIL)	; template has no output
cn_end:
		_DR_OK			; make sure C is clear
cn_in:
#include "../firmware/modules/pask-read.s"
	BCS cn_empty		; nothing here, keep trying
		CPY #LF				; UNIX-like linefeed?
		BNE cn_end			; no, just return it
			LDY #CR				; otherwise use minimOS newline instead!
			BNE cn_end
cn_empty:
	_DR_ERR(EMPTY)			; set C instead eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
.)
