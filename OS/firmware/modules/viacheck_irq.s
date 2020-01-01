; firmware module for minimOS·65
; (c) 2017-2020 Carlos J. Santisteban
; last modified 20171221-1302

; *** check for VIA and disable all interrupt sources ***
; NMOS and 65816 savvy
; no interface needed, might jump to LOCK routine

.(
; disable all interrupt sources
	LDA #$7F		; disable all interrupts (2+4)
	STA VIA_J + IER	; *** this is for single VIA systems ***

; and optionally check for VIA presence
#ifdef	SAFE
	LDA VIA_J + IER	; check VIA presence, NEW 20150118 (4)
	CMP #$80		; should read $80 (2)
	BEQ via_ok		; panic otherwise! (slight modification 20150121 and 0220) (3/2)
		JMP lock		; no other way to tell the world... (3)
via_ok:
#endif
.)
