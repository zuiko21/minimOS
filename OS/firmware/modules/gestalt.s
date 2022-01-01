; firmware module for minimOS·65
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20180131-0942

; *********************************
; GESTALT, get system info, API TBD
; *********************************
;		OUTPUT
; cpu_ll	= CPU type
; c_speed	= speed code (now 16b)
; str_pt	= *machine name
; ex_pt		= *memory map
; k_ram		= pages of RAM
; NMOS savvy

-gestalt:
	LDX #<SPD_CODE		; CPU speed
	LDA #>SPD_CODE
	LDY fw_cpu			; CPU type
	STX c_speed			; set word
	STA c_speed+1
	STY cpu_ll
	LDX himem			; number of pages???
	STX k_ram			; set outputs
	LDY #<fw_mname		; get pointer to name
	LDA #>fw_mname
	STY str_pt			; set output
	STA str_pt+1
	LDY #<fw_map		; get pointer to map
	LDA #>fw_map
	STY ex_pt			; set output
	STA ex_pt+1
	_DR_OK
