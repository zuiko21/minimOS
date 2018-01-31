; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180124-1315

; *********************************
; GESTALT, get system info, API TBD
; *********************************
;		OUTPUT
; cpu_ll	= CPU type
; c_speed	= speed code (now 16b)
; str_pt	= *machine name
; ex_pt		= *memory map
; k_ram		= pages of RAM
; sizes irrelevant

-gestalt:
.(
	PHP					; keep sizes (3)
	.al: REP #$20		; ** 16-bit memory **
	.xs: SEP #$10		; ** 8-bit indexes **
	LDX fw_cpu			; get kind of CPU previoulsy stored or determined (4)
	STX cpu_ll			; store this value (3)
	LDA #SPD_CODE		; speed code as determined in options.h (3)
	STA c_speed			; store this value (3) 
	STZ b_ram			; no "high" RAM??? (4) *** TO DO ***
	LDX himem			; get pages of kernel SRAM (4)
	STX k_ram			; store output (3)
	LDA #fw_mname		; get pointer to name (3)
	STA str_pt			; set value (4)
	LDA #fw_map			; get pointer to map (3) ***globally defined
	STA ex_pt			; set output (4)
	PLP					; restore sizes (4)
	_DR_OK				; done (8)
.)
	.as: .xs			; just in case...
