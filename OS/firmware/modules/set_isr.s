; firmware module for minimOS·65
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20180320-1006

; ***********************
; SET_ISR, set IRQ vector
; ***********************
;	INPUT
; ex_pt		= pointer to ISR
;	OUTPUT
; ex_pt		= currently set pointer (if was NULL at input)

-set_isr:
.(
	LDY ex_pt			; get LSB, nicer (3)
	_CRITIC				; disable interrupts! (5)
	LDA ex_pt+1			; get MSB (3)
		BEQ fw_r_isr		; will read instead (2/3)
	STY fw_isr			; store for firmware (4+4)
	STA fw_isr+1
fwsi_end:
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; done (8)
fw_r_isr:
	LDY fw_isr			; get current if read (4+4)
	LDA fw_isr+1
	STY ex_pt			; store result (3+3)
	STA ex_pt+1
	_BRA fwsi_end		; finish (3+12)
.)
