; firmware module for minimOS·16
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20180110-1416

; *** preset IRQ frequency ***
; no interface needed, affects FW vars
; 65816 only, MUST enter in 16-bit memory!

; this should be done by installed kernel, but at least set to zero for 0.5.x compatibility!
	STZ irq_freq		; store null speed... IRQ not set
