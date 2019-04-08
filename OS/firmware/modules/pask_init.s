; firmware module for minimOS·65
; (c) 2019 Carlos J. Santisteban
; last modified 20190408-1051

; *** initialise PASK ***
; no interface needed

.(
	_STZA VIA_U+DDRA	; all input on PA
	LDA VIA_U+PCR		; get current config
	AND #%11110000		; keep unrelated bits (for actual PASK, might be removed)
	ORA #%00001011		; set CA1 positive, CA2 pulse (for actual PASK, might use just 1 as no ACK is needed)
	STA VIA_U+PCR		; set handshake configuration
	LDA VIA_U+ACR		; let us enable latching
	ORA #1				; only needs to set bit 0
	STA VIA_U+ACR		; ready for latched input
; the very basic FW drivers polls IFR until bit 1 is set
; otherwise, a suitable async interrupt task should put IORA on a FIFO for later CIN/BLIN read
	LDA #2				; disable CA1 interrupt (unlike the full driver!)
	STA VIA_U+IER		; all done
.)
