; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180122-1054

; ********************************
; *** SET_DBG, set BRK handler ***
; ********************************
;		INPUT
; kerntab	= 24b address of BRK routine (ending in RTS)
;		zero means RETURN actual value! new 20170820

; ------------------- TO BE DONE ----------------------------
set_dbg:
	PHP					; save sizes! (3)
#ifdef	SUPPORT
	.xs: SEP #$10			; *** standard index size ***
	LDY run_arch		; called from unaware 6502 code?
	BEQ fw_sb24		; no, all set...
		STZ kerntab+2		; ...or clear bank
fw_sb24:
#endif
	.al: REP #$20		; ** 16-bit memory ** (3)
; first check whether read or set
	LDA kerntab+1			; get pointer highest... (4)
; no ISRs on page zero!
		BEQ fw_r_brk			; read instead! (2/3)
	STA @fw_brk+1			; store for firmware, note long addressing (6)
	LDA kerntab			; get pointer lowest (4)
	STA @fw_brk			; sets middle byte too, no problem (6)
fwb_end:
	PLP					; restore sizes (4)
	_DR_OK				; done
fw_r_brk:
	LDA @fw_brk		; get previous value... (6)
	STA kerntab		; ...and store it (4)
	LDA @fw_brk+2		; get bank and garbage! (6)
	STA kerntab+2		; will not hurt anyway (4)
	BRA fwb_end

	.as: .xs			; just in case...
