; firmware module for minimOS·65
; (c) 2017-2022 Carlos J. Santisteban
; last modified 20220102-0011

; *** preset default BRK handler *** temporarily set as default NMI
; expects std_nmi label, possibly from ROM file
; NMOS and 65816 savvy

.(
	LDA #>nmi_sf		; default like the standard NMI (2+2)
	LDY #<nmi_sf
	STY fw_dbg			; store default handler (4+4)
	STA fw_dbg+1
; as nanomon is expected to be called with NMI stack on frame, put it
	LDY #<nmi_sf
	LDA #>nmi_sf
	STY fw_nmi			; store default handler (4+4)
	STA fw_nmi+1
	BRA cont
nmi_sf:
		PHA
		_PHX
		_PHY
		LDA systmp
		PHA
		LDA sysptr+1
		PHA
		LDA sysptr
		PHA
		JSR nanomon		; note offset +2, they seemed OK then
		PLA
		STA sysptr
		PLA
		STA sysptr+1
		PLA
		STA systmp
		_PLY
		_PLX
		PLA
		RTI
cont:
.)
