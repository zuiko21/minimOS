; stub for optical Theremin app
; (c) 2018 Carlos J. Santisteban
; v0.2
; last modified 20180314-0911

; to be assembled from OS/
#include "usual.h"

; new approach, notes are generated via PB7/T1 interrupts
; volume is set via PWM thru Serial register, T2 at full speed
; buzzer sounds when PB7=0 & CB2=1 (use a diode or suitable amp)
; volume polling was done every ~80ms, this way could be up to 145ms, still OK

; *** init code ***
; must set SS in T2 free-run mode, T1 as continuous interrupts (toggling PB7)
; CA2 is independent interrupt on low-to-high (for pitch ionterrupt)
; PB7 output, PA7 input (volume interrupt*) and PA0...6 as output
; perhaps CA1 as volume interrupt will make things simpler!
; pitch DAC thru weighted resistors at PA0...4, volume DAC at PA5-PA6
ot_init:
;	LDA #%
	
	LDA #110			; counter LSB value, about 440Hz PB7 @ 1 MHz (will be set later, but at least get it running)
	STA VIA_J+T1CL		; set counter (and latch)
	LDA #4				; same for MSB
	STA VIA_J+T1CH		; start counting!

; *** jiffy interrupt task, will increase counters and poll the volume sensor ***
ot_irq:
	PHA					; will be altered anyway
; *** must check whether periodic (next value) or from CA2 (set pitch) ***
	LDA #1				; mask for CA2
	BIT VIA_J+IFR		; check interrupt sources
		BNE ot_pitch		; it is CA2, set pitch
		BVC ot_vol			; it is jiffy
; in case CA1 is used for volume interrupt...
		
		; otherwise it is spurious!
; *** it is the jiffy interrupt task ***
ot_vol:
; must acknowledge interrupt!!!
		INC VIA_J+IORA		; increase counters
		NOP					; *** small delay allowing the OpAmp to rise its output!
		LDA #%00011111		; set mask for pitch ADC bits
		BIT VIA_J+IORA		; check against current value (respect 4uS delay from INC!!!)
		BNE ot_exit			; volume bits will not change
		BPL ot_exit			; or we have not detected current volume
; PA7 went high, we must set volume the first time ONLY
; this will be MUCH simpler if we use, say, positive-transition CA1 for volume interrupt instead of polling!
			_PHX				; will use this
			LDA VIA_J+IORA		; still scanning, get stored value as %xvvttttt
			
			AND #%01111111		; must clear bit 7!
			LSR					; shift as needed, now %00vvtttt
			LSR					; %000vvttt
			LSR					; %0000vvtt
			LSR					; %00000vvt
			LSR					; %000000vv as needed
			TAX					; eeeeeeeeeeeeeek
			LDA ot_patts, X		; get bit pattern for this volume
			STA VIA_J+VSR		; set for PWM control output
			_PLX				; restore reg
; *** end of ISR ***
ot_exit:
	PLA					; restore reg
	RTI					; and we are done

; *** arrive here whenever CA2 is triggered (pitch value is set)
; assume A is already pushed into stack
ot_pitch:
	_PHX				; will be needed
; as CA2 was independent interrupt, must acknowledge source!
	LDA VIA_J+IORA		; get counter value
	AND #%00011111		; filter pitch bits
	ASL					; twice...
	TAX					; ...as index
	LDA ot_notes, X		; get pitch LSB
	STA VIA_J+T1LL		; set T1 LSB
	LDA ot_notes+1, X	; same for MSB
	STA VIA_J+T1LH		; this will load upon next cycle
	_PLX				; restore regs and exit
; standard ISR exit, not worth reusing the above one
	PLA
	RTI

; *** diverse data ***
; shifted bit patterns for diverse volume levels (hopefully!)
ot_patts:
	.byt	0			; 0 = MUTE
	.byt	%10000000	; 1 = 12.5%
	.byt	%10010010	; 2 = 37.5% (will not use 25 & 50% as per log ear response)
	.byt	%11111111	; 3 = 100%, continuous PB7 output

; VIA T1 values for 32 chromatic notes
ot_notes:
