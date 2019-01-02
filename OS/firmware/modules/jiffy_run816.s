; firmware module for minimOS·16
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180124-0854
; specific code for run816 simulator

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
; if could not change, then just set return parameter and C
.(
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA irq_hz			; get input value
	BNE fj_set			; not just checking
		LDA irq_freq		; get current frequency
		STA irq_hz			; set return values
fj_set:
	STA irq_freq		; store in sysvars, will not hurt anyway
	_NO_CRIT			; eeeeeeeeek
	_DR_OK
.)
	.as: .xs			; just in case...
