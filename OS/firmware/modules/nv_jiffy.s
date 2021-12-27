; firmware module for minimOS
; (c) 2021 Carlos J. Santisteban
; last modified 20211227-1749

; **************************
; JIFFY, set/check IRQ speed *** for NON-VIA machines
; **************************
;		INPUT
; irq_hz	= desired period in uS (0 means no change) *** IGNORED
;		OUTPUT
; irq_hz	= actually set period (if error or no change) *** always 250 Hz (4000 µs) in Durango
; C			= error, did not set *** always set

	LDA #>4000				; fixed value
	LDY #<4000
	STA irq_hz+1			; confirm actual speed
	STY irq_hz
	_DR_ERR(INVALID)
