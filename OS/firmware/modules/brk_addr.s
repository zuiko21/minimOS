; firmware module for minimOS·65
; (c) 2017-2022 Carlos J. Santisteban
; last modified 20220102-1412

; *** preset default BRK handler *** temporarily set as default NMI
; expects std_nmi label, possibly from ROM file
; *** do not confuse NMI _handler_ (ends in RTI) with NMI _service routine_ (ending in RTS) ***
; to make things worse, the BRK HANDLER has been at brk_02! Thus fw_dbg is OK for SERVICE always
; IRQ has no separate service for performance reasons, fw_isr is the HANDLER+SERVICE, only JMP(fw_isr) in firmware
; NMOS and 65816 savvy

.(
	LDA #>nanomon		; default BRK like the standard NMI (2+2)
	LDY #<nanomon
	STY fw_dbg			; store default SERVICE (4+4) always OK
	STA fw_dbg+1
#ifndef	DOWNLOAD
	STY fw_nmi			; store default SERVICE (4+4)
	STA fw_nmi+1
#else
; DOWNLOADed firmware uses fw_nmi/fw_dbg for the HANDLERS, not SERVICES
	STY fds_nmi			; store default SERVICE (4+4) *** new FW var, DOWNLOAD only
	STA fds_nmi+1
	LDA #>nmi_hndl		; default NMI HANDLER (2+2)
	LDY #<nmi_hndl
	STY fw_nmi			; store default HANDLER (4+4)
	STA fw_nmi+1
	LDA #>brk_hndl		; default BRK HANDLER (2+2)
	LDY #<brk_hndl
	STY brk_02			; store default HANDLER (4+4) *** DOWNLOADed FW only!
	STA brk_02+1
#endif
.)
