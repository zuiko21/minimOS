; firmware module for minimOS·16
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20181109-1110

; *** preset default BRK handler *** temporarily set as default NMI
; expects std_nmi label, possibly from ROM file
; 65816 only, MUST enter in 16-bit memory!
.al:
	LDA #std_nmi		; default like the standard NMI (3)
	STA fw_dbg			; store default handler (5)
	STZ fw_dbg+2		; eeeeeeeek
#ifndef	SAFE
	STA fw_nmi			; store default handler (5)
	STZ fw_nmi+2		; eeeeeeeeeek
#endif
