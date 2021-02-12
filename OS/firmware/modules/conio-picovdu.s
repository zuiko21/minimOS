; firmware module for minimOS
; (c) 2021 Carlos J. Santisteban
; last modified 20210212-1427

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
		CMP #FORMFEED		; reset device?
		BNE cn_out			; no, just print it
; clear screen here
cn_out:
		CMP #BS				; backspace?
		BNE cn_prn
; back one char
cn_prn:
; anything else?
; PRINT HERE
cn_end:
		_DR_OK			; make sure C is clear
cn_in:
#include "../firmware/modules/pask-read.s"
	BCS cn_empty		; nothing here, keep trying
		BCC cn_end		; send received otherwise
cn_empty:
	_DR_ERR(EMPTY)			; set C instead eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
.)
