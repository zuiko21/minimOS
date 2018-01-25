; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180125-1318

; ****************************
; PATCH, patch single function
; ****************************
;		INPUT
; kerntab	= 16b address of function code (NULL means reset from originally installed kernel)
; Y			= function to be patched
;		OUTPUT
; kerntab	= previously set address (new)
; uses local1 & local2 (.w)

-patch:
.(
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	.xs: SEP #$20			; ** 8-bit indexes **
; first get current address, not worth a subroutine
	LDA fw_table, Y			; current pointer... (5)
	STA local1				; ...temporarily stored (4)
; check what are we asking for
	LDA kerntab				; get full target pointer (4)
; *** this feature allows new resetting pointer from originally installed kernel ***
	BNE pt_nz				; there is a supplied address, use it for patching
; otherwise, extract original pointer from previously installed kernel!
		LDA fw_lastk			; original kernel jump table (5)
		STA local2				; use as indirect pointer (4)
		LDA (local2), Y			; perfect offset for addressed function! (6)
pt_nz:
; *** end of resetting feature ***
	STA fw_table, Y			; store into firmware, long addressing no longer needed (5)
; report previously registered address (new)
	LDA local1				; previous pointer... (4)
	STA kerntab				; ...as output parameter (4)
	_NO_CRIT				; restore interrupts and sizes (4)
	_DR_OK					; done (8)
.)
.as: .xs				; just in case
