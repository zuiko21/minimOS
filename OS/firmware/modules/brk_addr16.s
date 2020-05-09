; firmware module for minimOS·16
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20200509-1651

; *** preset default BRK handler *** temporarily set as default NMI
; expects std_nmi label, possibly from ROM file
; 65816 only, MUST enter in 16-bit memory!
.al:
	LDA #std_nmi		; default like the standard NMI (3)
	STZ fw_dbg+1		; eeeeeeeek^2, will clear +2 as is in 16-bit mode (5)
	STA fw_dbg			; store default handler (5)
#ifndef	SAFE
	STZ fw_nmi+1		; eeeeeeeeeek^2 (5)
	STA fw_nmi			; store default handler (5)
#endif
