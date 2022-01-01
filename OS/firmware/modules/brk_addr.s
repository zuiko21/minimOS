; firmware module for minimOS·65
; (c) 2017-2022 Carlos J. Santisteban
; last modified 20180905-1728

; *** preset default BRK handler *** temporarily set as default NMI
; expects std_nmi label, possibly from ROM file
; NMOS and 65816 savvy

	LDA #>std_nmi		; default like the standard NMI (2+2)
	LDY #<std_nmi
	STY fw_dbg			; store default handler (4+4)
	STA fw_dbg+1
#ifndef	SAFE
	STY fw_nmi			; store default handler (4+4)
	STA fw_nmi+1
#endif
