; firmware module for minimOS·65
; (c) 2017-2020 Carlos J. Santisteban
; last modified 20200509-1434

; *** check for VIA and disable all interrupt sources ***
; NMOS and 65816 savvy
; no interface needed, might jump to LOCK routine

.(
; disable all interrupt sources
	LDX #$7F		; disable all interrupts (2+4)
	STX VIA_J + IER	; *** this is for single VIA systems ***
; could be repeated for multi-VIA systems

; and optionally check for VIA presence
#ifdef	SAFE
	INX				; now X holds $80, as IER should read... (2)
	CPX VIA_J + IER	; check VIA presence, NEW 20150118 (4)
	BEQ via_ok		; panic otherwise! (slight modification 20150121 and 0220) (3/2)
		JMP lock		; no other way to tell the world... (3)
via_ok:
#endif
.)
