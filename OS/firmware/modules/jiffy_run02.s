; firmware module for minimOS·65
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180202-0834
; specific code for run816 simulator running 8-bit kernel!

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
;		INPUT
; irq_hz	= frequency in Hz (0 means no change)
;		OUTPUT
; irq_hz	= actually set frequency (in case of error or no change)
; C			= could not set (not here)

-jiffy:
; this is generic
.(
	LDA irq_hz+1		; get input values
	LDY irq_hz
		BNE fj_set			; not just checking
	CMP #0				; MSB also 0?
		BNE fj_set			; not checking
	LDA irq_freq+1		; get current frequency
	LDY irq_freq
	STA irq_hz+1		; set return values
	STY irq_hz
	_DR_OK
fj_set:
	STA irq_freq+1		; store in sysvars
	STY irq_freq
	_DR_OK				; all done, no need to update as will be OK
.)
