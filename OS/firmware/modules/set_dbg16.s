; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180124-0854

; ********************************
; *** SET_DBG, set BRK handler ***
; ********************************
;		INPUT
; kerntab	= 24b address of BRK routine (ending in RTS/RTL)
;		zero means RETURN actual value! new 20170820

-set_dbg:
.(
	_CRITIC
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***

#ifdef	SUPPORT
	LDX run_arch		; called from 8-bit code?
	BEQ sd_16b			; no, bank address already provided
		STZ kerntab+2		; otherwise, set it to zero
sd_16b:
#endif

	LDA kerntab+1		; check MSB and bank address
	BNE fw_s_dbg		; set ISR as was not NULL
		LDY fw_dbg			; get whole pointer otherwisw
		LDA fw_dbg+1
		STY kerntab			; store result
		STA kerntab+1
; no need to skip next instruction as will be harmless
fw_s_dbg:
	LDY kerntab			; get original pointer LSB, as MSB+bank already loaded
	STY fw_dbg			; store for firmware
	STA fw_dbg+1
	_NO_CRIT			; restore sizes and interrupt mask
	_DR_OK				; done
.)
	.as: .xs			; just in case...
