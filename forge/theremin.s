; stub for optical Theremin app
; (c) 2018 Carlos J. Santisteban
; v0.1
; last modified 20180312-1049

; to be assembled from OS/
#include "usual.h"

; *** jiffy interrupt task, will increase counters and poll the volume sensor ***
ot_irq:
	PHA			; will be altered
; *** must check whether periodic or from CA2 ***
	LDA VIA_J+IFR		; interrupt sources
	AND #???
; *** jiffy interrupt task ***
	INC VIA_J+IORA		; increase counters
	LDA #%00011111		; set mask for tone ADC bits
	BIT VIA_J+IORA		; check against current value
	BNE ot_nvol		; volume bits did not change
		BMI ot_nvol		; otherwise, check if we had set volume
			_PHX			; will use this
			LDA VIA_J+IORA		; no, update stored value
			ROL			; rotate as needed
			ROL
			ROL
			ROL
			AND #%00000011		; filter relevant
			LDA ot_patts, X		; get bit pattern for this volume
			STA VIA_J+VSR		; set for output
			_PLX			; restore reg
ot_nvol:
	PLA				; restore reg
	RTI				; and we are done

; *** arrive here whenever CA2 is triggered
; assume A is pushed into stack
ot_tone:
	_PHX				; will be needed

	_PLX				; restore regs and exit
	PLA
	RTI
