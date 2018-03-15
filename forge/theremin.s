; stub for optical Theremin app
; (c) 2018 Carlos J. Santisteban
; v0.2
; last modified 20180315-1342

; to be assembled from OS/
#include "usual.h"

; new approach, notes are generated via PB7/T1 interrupts
; volume is set via PWM thru Serial register, T2 at full speed
; buzzer sounds when PB7=0 & CB2=1 (use a diode or suitable amp)
; volume polling was done every ~80ms, this way could be up to 145ms, still OK

; *** init code ***
; must set SS in T2 free-run mode, T1 as continuous interrupts (toggling PB7)
; CA2 is independent interrupt on low-to-high (for pitch interrupt)
; let us try CA1 as volume interrupt, makes things simpler!
; PB7 and PA0...6 as output (no longer using PA7 for volume interrupt)
; keep PA7 as output in order to remain at zero (makes CA2 handler faster)
; pitch DAC thru weighted resistors at PA0...4, volume DAC at PA5-PA6
ot_init:
; I/O direction
	LDA #255			; whole bit mask
	STA VIA_J+DDRA		; PA0...PA7 as output
	LDA VIA_J+DDRB		; current PB status
	ORA #%10000000		; set PB7 as output
	STA VIA_J+DDRB		; do not disturb PB0...PB6
; disable handshake and set interrupt mode
	LDA VIA_J+PCR		; original values
	AND #$F0			; respect CBx
	ORA #%0111			; CA2 as independent positive edge, CA1 as positive edge
	STA VIA_J+PCR
; set timer modes
	LDA #%111
; start oscillator
	LDA #110			; counter LSB value, about 440Hz PB7 @ 1 MHz (will be set later, but at least get it running)
	STA VIA_J+T1CL		; set counter (and latch)
	LDA #4				; same for MSB
	STA VIA_J+T1CH		; start counting!

; *** jiffy interrupt task, will increase counters and poll the volume sensor ***
ot_irq:
	PHA					; will be altered anyway
; *** must check whether periodic (next value), from CA2 (set pitch) or CA1 (set volume) ***
; original handler (16b) takes 7t for jiffy, 15 for pitch, 19 for volume and 22 for spurious (besides exit)
; add 3b, 4t for interrupt acknowlege (worth it)
	BIT VIA_J+IFR		; check interrupt sources (4)
		BVS ot_cnt			; it is jiffy (3/2)
	_PHX				; otherwise will use X (3)
	LDA VIA_J+IFR		; get whole bit mask (/4)
	STA VIA_J+IFR		; acknowledge any interrupt, worth it, place below LDA on CMOS handler (4)
; for the above, CMOS could use LDA, STA, BIT #0, BVS, PHX instead
	ROR					; shift out CA2 (/2)
		BCS ot_pitch		; it is CA2, set pitch (/3/2)
; in case CA1 is used for volume interrupt...
	ROR					; shift out CA1 (//2)
		BCS ot_vol			; it is CA1, set volume (//3/2)
	BCC ot_rti			; otherwise it is spurious! must restore X (///3)
; *** alternative handler, CMOS only!!! ***
; 12b + 8b table, 9t for jiffy, 18t for pitch, volume and spurious
;	LDA VIA_J+IFR		; check interrupt sources (4)
;	ASL					; shift left, puts T1 as sign, plus makes CA1-CA2 as valid index (2)
;		BMI ot_cnt			; jiffy! (3/2)
;	AND #%00000110		; otherwise, could just be CAx (2)
;	TAX					; as index (2)
;	JMP (ot_srcs, X)	; CMOS only indexed jump (6)
;ot_srcs:
;	.word	ot_exit		; X=0, if not jiffy, was spurious interrupt
;	.word	ot_pitch	; X=2, CA2 means pitch setting
;	.word	ot_vol		; X=4, CA1 means volume setting
;	.word	ot_pitch	; X=6, both CA1 & CA2, the latter taking priority

; *** handle the jiffy interrupt task ***
; assume A was pushed
ot_cnt:
; must acknowledge interrupt!!!
	LDA VIA_J+T1CL		; read dummy value for acknowledge (not needed for CMOS handler)
	INC VIA_J+IORA		; increase counters
	BPL ot_exit			; bit 7 remains 0
		_STZA VIA_J+IORA	; otherwise, keep it zero!
; *** end of ISR ***
ot_exit:
	PLA					; restore accumulator
	RTI					; and we are done

; *** handle volume setting (CA1) ***
; assume A & X were pushed and interrupt source acknowledged
ot_vol:
	LDA VIA_J+IORA		; still scanning, get stored value as %xvvttttt
;	AND #%01111111		; must clear bit 7! no longer needed as jiffy does it
	LSR					; shift as needed, now %00vvtttt
	LSR					; %000vvttt
	LSR					; %0000vvtt
	LSR					; %00000vvt
	LSR					; %000000vv as needed
	TAX					; eeeeeeeeeeeeeek
	LDA ot_patts, X		; get bit pattern for this volume
	STA VIA_J+VSR		; set for PWM control output
	_BRA ot_rti			; restore X and done (this is less accurate)

; *** arrive here whenever CA2 is triggered (pitch value is set)
; assume A & X were pushed and interrupt source acknowledged
ot_pitch:
	LDA VIA_J+IORA		; get counter value
	AND #%00011111		; filter pitch bits
	ASL					; twice...
	TAX					; ...as index
	LDA ot_notes, X		; get pitch LSB
	STA VIA_J+T1LL		; set T1 LSB
	LDA ot_notes+1, X	; same for MSB
	STA VIA_J+T1LH		; this will load upon next cycle
; *** standard ISR exit with full register restore ***
ot_rti:
	_PLX				; restore regs and exit
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
	.byt	110,	4	; A4
	.byt	47,		4	; Bb4
	.byt	242,	3	; B4
	.byt	186,	3	; C5
	.byt	132,	3	; C#5
	.byt	81,		3	; D5
	.byt	34,		3	; Eb5
	.byt	244,	2	; E5
	.byt	202,	2	; F5
	.byt	162,	2	; F#5
	.byt	124,	2	; G5
	.byt	88,		2	; G#5
	.byt	54,		2	; A5
	.byt	22,		2	; Bb5
	.byt	248,	1	; B5
	.byt	220,	1	; C6
	.byt	193,	1	; C#6
	.byt	168,	1	; D6
	.byt	144,	1	; Eb6
	.byt	121,	1	; E6
	.byt	100,	1	; F6
	.byt	80,		1	; F#6
	.byt	61,		1	; G6
	.byt	43,		1	; G#6
	.byt	26,		1	; A6
	.byt	10,		1	; Bb6
	.byt	251,	0	; B6
	.byt	237,	0	; C7
	.byt	223,	0	; C#7
	.byt	211,	0	; D7
	.byt	199,	0	; Eb7
	.byt	188,	0	; E7
