; Acapulco firmware module for minimOS
; (c) 2019 Carlos J. Santisteban
; last modified 20190304-1346

; *** set Acapulco video mode at boot ***

.(
	_STZA VIA_U+DDRA	; safest way
; do I need to set DDRB?
	LDA VIA_U+IORB		; get command
	AND #%10001000		; keep these PB bists, just in case
	ORA #%00100101		; select ASCII keyboard
	STA VIA_U+IORB		; set command
	LDA #$F0
	STA VIA_U+DDRA		; PA0-3 as input, PA4-7 as output
	LDA #$10			; PA4 high...
	STA VIA_U+IORA		; ...selects column 1
; Acapulco is not fast enough to create a problem
	LDA VIA_U+IORA		; get column
	AND #$0F			; input bits only
	STA va_mode			; firmware variable!
.)
