; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180124-1307

; ****************************
; PATCH, patch single function
; ****************************
; kerntab <- address of code
; Y <- function to be patched

-patch:
.(
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	.xs: SEP #$20			; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab				; get full pointer (4)
	TYX						; no Y-indexed long addressing! (2)
	STA @fw_table, X		; store into firmware, note long addressing (6)
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)
.)
.as: .xs				; just in case
