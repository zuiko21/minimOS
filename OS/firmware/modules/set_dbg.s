; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20180131-1420

; ***********************
; SET_DBG, set BRK vector
; ***********************
;	INPUT
; kerntab	= pointer to ISR
;	OUTPUT
; kerntab	= currently set pointer (if was NULL at input)

-set_dbg:
.(
	LDY kerntab			; get LSB, nicer (3)
	_CRITIC				; disable interrupts! (5)
	LDA kerntab+1		; get MSB (3)
		BEQ fw_r_brk		; read instead (2/3)
	STY fw_dbg			; store for firmware (4+4)
	STA fw_dbg+1
fwsb_end:
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; done (8)
fw_r_brk:
	LDY fw_dbg			; get current if read (4+4)
	LDA fw_dbg+1
	STY kerntab			; store result (3+3)
	STA kerntab+1
	_BRA fwsb_end		; go away
.)
