; firmware module for minimOS·65
; (c) 2019 Carlos J. Santisteban
; last modified 20190408-1057

; *** read from polled PASK ***
; returns read code on Y, clear C
; ...or empty error on Y, if C is set

.(
#ifdef	SAFE
	_STZA VIA_U+DDRA	; all input on PA
#endif
; the very basic FW drivers polls IFR until bit 1 is set
; otherwise, a suitable async interrupt task should put IORA on a FIFO for later CIN/BLIN read
	LDA #2				; check CA1 interrupt (unlike the full driver!)
	BIT VIA_U+IER		; was something latched?
	BNE psk_no			; no, just report as empty
		STA VIA_U+IER		; clear this interrupt source...
		LDY VIA_U+IORA		; ...and read latched data
		CLC					; return with no error
		BCC psk_end			; no need for BRA
psk_no:
	SEC					; return empty error code
	LDY #EMPTY
psk_end:
.)
