; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180122-1318

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
	.al: REP #$20		; *** 16-bit memory *** (3)
	.xs: SEP #$10		; *** 8-bit indexes *** (3)

#ifdef	SUPPORT
	LDX run_arch		; called from 8-bit code? (4)
	BEQ si_16b			; no, bank address already provided (3/2)
		STZ kerntab+2		; otherwise, set it to zero (0/4)
si_16b:
#endif

	LDA kerntab+1		; check MSB and bank address
	BNE fw_s_isr		; set ISR as was not NULL
		LDY fw_isr			; get whole pointer otherwisw
		LDA fw_isr+1
		STY kerntab			; store result
		STA kerntab+2
; no need to skip next instruction as will be harmless
fw_s_isr:
	LDY kerntab			; get missing LSB (3)
	STY fw_isr			; store for firmware (4+5)
	STA fw_isr+1
	_NO_CRIT			; restore sizes and interrupt mask
	_DR_OK				; done

	.as: .xs			; just in case...
