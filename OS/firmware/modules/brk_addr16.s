; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180427-1052

; *** preset default BRK handler *** temporarily set as default NMI
; expects std_nmi label, possibly from ROM file
; 65816 only, MUST enter in 16-bit memory!
lda#'-'*257
jsr$c0c2
	LDA #std_nmi		; default like the standard NMI (2+2)
	STA fw_dbg			; store default handler (4+4)
