; Acapulco firmware module for minimOS
; (c) 2019 Carlos J. Santisteban
; last modified 20190306-1057

; *** set Acapulco video mode at boot ***

.(
; *** it would be a good idea to set some safe values on CRTC registers ***
; ...including those 6345/6445 specific!
	LDX #30				; last register (first one to be set)
afw_63r:
		STX crtc_rs			; *** label from driver ***
		LDA afw_63d-27, X	; get safe value, note offset!
		STA crtc_da			; set register
		DEX
		CPX #29				; down to 30, 29 means exit! could be 27/26 if VSYNC adjust
		BNE afw_63r			; complete
; safe 6845 register setting
	LDX #9				; last register to set
afw_ci:
		STX crtc_rs			; *** label from driver ***
		LDA afw_si, X		; get safe value
		STA crtc_da			; set register
		DEX
		BPL afw_ci			; until done
	BMI afw_rm			; go read mode, no need for BRA

; *** data tables ***
afw_si:
	.byt 47, 32, 37, 38, 31, 13, 30, 30, 0, 15		; *** safe values for 6845 ***
; specific 6345/6445 registers
afw_63d:
	.byt 8				; R30, d3=SY (enable VS adjust)
	.byt 0				; R31, no smooth scrolling neither raster interpolation
	.byt 2				; R32, d1=TC (enable tristate control ASAP!)
; R27 might set the VS adjust value... if not set, put a 0 on R30!

; *** this reads desired video mode from column 1 of ASCII-keyboard ***
afw_rm:
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
