; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180122-1048

; ***********************
; SET_ISR, set IRQ vector
; ***********************
;	INPUT
; kerntab	= pointer to ISR (24b)
;	OUTPUT
; kerntab	= currently set pointer (if was NULL at input)
; sizes irrelevant!

set_isr:
	_CRITIC
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
#ifdef	SUPPORT
	LDX run_arch		; called from 8-bit code?
	BEQ si_16b			; no, bank address already provided
		STZ kerntab+2		; otherwise, set it to zero
si_16b:
#endif
	LDA kerntab+1		; check MSB and bank address
	BNE fw_s_isr		; set ISR as was not NULL
		LDA fw_isr			; get whole pointer otherwisw
		LDX fw_isr+2
		STA kerntab			; store result
		STX kerntab+2
; no need to skip next instruction as will be harmless
fw_s_isr:
	LDA kerntab			; get original pointer
	LDX kerntab+2
	STA fw_isr			; store for firmware
	STX fw_isr+2
	_NO_CRIT			; restore sizes and interrupt mask
	_DR_OK				; done

	.as: .xs			; just in case...
