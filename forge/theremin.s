; stub for optical Theremin app
; (c) 2018 Carlos J. Santisteban
; v0.1
; last modified 20180313-1011

; to be assembled from OS/
#include "usual.h"

; appropriate interrupt speed for a 1 MHz system
#define		IRQ_US		600

; *** init code ***
; must set SS in T2 free-run mode, T1 as continuous interrupts (NOT toggling PB7) every ~600 uS
; CA2 is NON-independent interrupt on low-to-high (for tone)
; make sure PB7 low, PA7 input (volume interrupt) and PA0...6 as output
ot_init:
	LDA #%
	
	LDA #<IRQ_US-2		; counter LSB value
	STA VIA_J+T1CL		; set counter (and latch)
	LDA #>IRQ_US-2		; same for MSB
	STA VIA_J+T1CH		; start counting!

; *** jiffy interrupt task, will increase counters and poll the volume sensor ***
ot_irq:
	PHA					; will be altered anyway
; *** must check whether periodic or from CA2 ***
	LDA #1				; mask for CA2
	BIT VIA_J+IFR		; check interrupt sources
		BNE ot_tone			; it is CA2, set tone
		BVC ot_nvol			; it is NOT jiffy, thus spurious
; *** otherwise it is the jiffy interrupt task ***
; must acknowledge interrupt!!!!!!
	INC VIA_J+IORA		; increase counters
	LDA #%00011111		; set mask for tone ADC bits
	BIT VIA_J+IORA		; check against current value
	BNE ot_nvol			; volume bits did not change
		BMI ot_nvol			; otherwise, check if we had set volume
			_PHX				; will use this
			LDA VIA_J+IORA		; still scanning, get stored value as %0vvttttt
			LSR					; shift as needed, now %00vvtttt (or CLC)
			LSR					; %000vvttt (if ROL, %vvttttt0)
			LSR					; %0000vvtt (if ROL, %vttttt00, C=v.h)
			LSR					; %00000vvt (if ROL, %ttttt00v, C=v.l)
			LSR					; %000000vv as needed (if ROL, %tttt00vv, C=t.h)
;			AND #%00000011		; filter relevant (only needed with CLC/ROL)
			TAX					; eeeeeeeeeeeeeek
			LDA ot_patts, X		; get bit pattern for this volume
			STA VIA_J+VSR		; set for output
			_PLX				; restore reg
ot_nvol:
	PLA					; restore reg
	RTI					; and we are done

; *** arrive here whenever CA2 is triggered
; assume A is pushed into stack
ot_tone:
	_PHX				; will be needed
	LDA VIA_J+IORA		; get counter value... and clear CA2 interrupt source!
	AND #%00011111		; filter tone bits
	ASL					; twice...
	TAX					; ...as index
	LDA ot_notes, X		; get tone LSB
	STA VIA_J+T2CL		; set T2 LSB
	LDA ot_notes+1, X	; same for MSB
	STA VIA_J+T2CH		; this will load upon next cycle
	_PLX				; restore regs and exit
	PLA
	RTI

; *** diverse data ***
; shifted bit patterns for diverse volume levels (hopefully!)
ot_patts:
	.byt	0			; 0 = MUTE
	.byt	%10000000	; 1 = 25%
	.byt	%11000000	; 2 = 50% (will not use 75% as per log ear response)
	.byt	%11110000	; 3 = 100%, fully symmetric square wave

; VIA T1 values for 32 chromatic notes
ot_notes:
