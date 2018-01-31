; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180131-1307

; ****************************
; PATCH, patch single function
; ****************************
;		INPUT
; kerntab	= 16b address of function code (NULL means reset from originally installed kernel)
; Y			= function to be patched
;		OUTPUT
; kerntab	= previously set address (new)
; uses tmp_ktab (.w)

-patch:
.(
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: .xl: REP #$30	; ** 16-bit memory AND indexes ** (3)
; first get current address
	LDX fw_table, Y		; current pointer will stay here! (5)
; check what are we asking for
	LDA kerntab			; get full target pointer (4)
; *** this feature allows new resetting pointer from originally installed kernel ***
	BNE pt_nz			; there is a supplied address, use it for patching
; otherwise, extract original pointer from previously installed kernel!
		LDA fw_lastk		; original kernel jump table (5)
		STA tmp_ktab		; use as indirect pointer (4)
		LDA (tmp_ktab), Y	; perfect offset for addressed function! (6)
pt_nz:
; *** end of resetting feature ***
	STA fw_table, Y		; store into firmware, long addressing no longer needed (5)
; report previously registered address (new)
	STX kerntab			; previous pointer as output parameter (4)
	_NO_CRIT			; restore interrupts and sizes (4)
	_DR_OK				; done (8)
.)
.as: .xs				; just in case
