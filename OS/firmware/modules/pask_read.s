; firmware module for minimOS·65
; (c) 2019-2022 Carlos J. Santisteban
; last modified 20190414-1124

; *** read from polled PASK ***
; returns read code on Y, clear C
; ...or empty error on Y, if C is set

.(
#ifdef	SAFE
	_STZA VIA_U+DDRA	; all input on PA
#endif
; the very basic FW drivers polls IFR until bit 1 is set
; otherwise, a suitable async interrupt task could put IORA on a FIFO for later CIN/BLIN read
; ...but I do not think it is worth it!
	LDA #2				; check CA1 interrupt (unlike a full driver!)
	BIT VIA_U+IFR		; was something latched? eeeeeeek
	BNE psk_no			; no, just report as empty
		LDY VIA_U+IORA		; or clear interrupt and read latched data
		CLC					; return with no error
		BCC psk_end			; no need for BRA
psk_no:
	SEC					; return empty error code
	LDY #EMPTY
psk_end:
.)
