; firmware module for minimOS·65
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20171225-2139

; *** preset IRQ frequency as NULL ***
; no interface needed, affects FW vars
; NMOS and 65816 savvy

; this should be done by installed kernel, but at least set to zero for 0.5.x compatibility!
	_STZA irq_freq		; store null speed... IRQ not set
	_STZA irq_freq+1
