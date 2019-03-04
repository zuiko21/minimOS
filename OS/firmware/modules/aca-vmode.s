; Acapulco firmware module for minimOS
; (c) 2019 Carlos J. Santisteban
; last modified 20190304-1410

; *** set Acapulco video mode at boot ***

.(
; *** it would be a good idea to set some safe values on CRTC registers ***
	LDX #9				; last register to set
afw_ci:
		STX crtc_rs			; *** label from driver ***
		LDA afw_si, X		; get safe value
		STA crtc_da			; set register
		DEX
		BPL afw_ci			; until done
	BMI afw_rm			; go read mode, no need for BRA
afw_si:
	.byt 47, 32, 37, 38, 32, 13, 30, 31, 0, 15		; *** revise safe values ***
; *** this reads desired video mode from column 1 of ASCII-keyboard ***
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
