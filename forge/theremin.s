; optical Theremin (standalone ROM version)
; (c) 2018 Carlos J. Santisteban
; v0.4
; last modified 20180319-0915

; to be assembled from OS/
#include "usual.h"

; new approach, notes are generated via PB7/T1 interrupts
; volume is set via PWM thru Serial register, T2 at full speed
; buzzer sounds when PB7=0 & CB2=1 (use a diode or suitable amp)
; volume polling was done every ~80ms, interrupt-driven could be up to 145ms, still OK

* = ROM_BASE			; for stand-alone ROMs

; *****************
; *** init code *** 52t to lock...
; *****************
; must set SS in T2 free-run mode, T1 as continuous interrupts (toggling PB7)
; CA2 is independent interrupt on low-to-high (for pitch setting)
; now uses CA1 as volume interrupt, makes things simpler!
; PB7 and PA0...7 as output (no longer using PA7 for volume interrupt, now is volume MSB)
; pitch DAC thru weighted resistors at PA0...4, volume DAC at PA5-PA7 (now 3 bits)
ot_init:
; I/O direction
	LDX #255			; whole bit mask (2)
	STX VIA_J+DDRA		; PA0...PA7 as output (4)
	INX					; now it is 0 (CMOS could just use STZ) (2)
	STA VIA_J+IORA		; reset DAC! (4)
; as a stand-alone ROM, no need to keep remaining state unchanged
;	LDA VIA_J+DDRB		; current PB status
;	ORA #%10000000		; set PB7 as output
; enable PB7 output
	LDA #%10000000		; set PB7 as output (direct) (2)
	STA VIA_J+DDRB		; do not disturb PB0...PB6 (4)
; as a stand-alone ROM, no need to keep remaining state unchanged
;	LDA VIA_J+PCR		; original values
;	AND #$F0			; respect CBx
;	ORA #%0111			; CA2 as independent positive edge, CA1 as positive edge
; disable handshake and set interrupt mode
	LDA #%0111			; CA2 as independent positive edge, CA1 as positive edge (2+4)
	STA VIA_J+PCR
; set timer modes
	LDA #%11110000		; PB7 square wave, PB6 count (so far), free-run shift, no latching (2) 
	STA VIA_J+ACR		; set timer modes (4)
; enable suitable interrupts
	LDA #%11000011		; enable T1, CA1 & CA2 (2+4)
	STA VIA_J+IER
; start oscillator
	LDA #110			; counter LSB value, about 440Hz PB7 @ 1 MHz (will be set later, but at least get it running) (2)
	STA VIA_J+T1CL		; set counter (and latch) (4)
	LDA #4				; same for MSB (2)
	STA VIA_J+T1CH		; start counting! (4)

; ************************************************************************
; *** as a stand-alone ROM task, this will lock waiting for interrupts ***
; ************************************************************************
	CLD					; just in case... (2)
	CLI					; make certain interrupts are ON (2)
ot_lock:
	_BRA ot_lock		; wait for interrupts forever!

; **************************
; *** interrupt handlers *** =30t jiffy, 65t pitch, 70t volume, 45t spurious
; **************************

; *** ISR, check interrupt source and call appropriate handler *** +10t to jiffy, +25t to pitch, +29t to vol, =45t for spurious
ot_irq:
	PHA					; will be altered anyway (3)
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

; *** jiffy interrupt handler (increment counter for DACs) *** +20t to exit
; assume A was pushed
ot_cnt:
	LDA VIA_J+T1CL		; read dummy value for acknowledge (not needed for CMOS handler) (4)
	INC VIA_J+IORA		; increase counters (6)
; new 3-bit DAC for volume uses up all bits
; *** fast end of ISR ***
ot_exit:
	PLA					; restore accumulator (4)
	RTI					; and we are done (6)

; *** CA1 interrupt handler (volume setting *** +41t to exit
; assume A & X were pushed and interrupt source acknowledged
ot_vol:
	LDA VIA_J+IORA		; still scanning, get stored value as %vvvttttt (4)
	LSR					; shift as needed, now %0vvvtttt (2)
	LSR					; %00vvvttt (2)
	LSR					; %000vvvtt (2)
	LSR					; %0000vvvt (2)
	LSR					; %00000vvv as needed (2)
	TAX					; eeeeeeeeeeeeeek (2)
	LDA ot_patts, X		; get bit pattern for this volume (4)
	STA VIA_J+VSR		; set for PWM control output (4)
	_BRA ot_rti			; restore X and done (this is less accurate) (3)

; *** CA2 interrupt handler (pitch value is set) *** +40t to exit
; assume A & X were pushed and interrupt source acknowledged
ot_pitch:
	LDA VIA_J+IORA		; get counter value (4)
	AND #%00011111		; filter pitch bits (2)
	ASL					; twice... (2)
	TAX					; ...as index (2)
	LDA ot_notes, X		; get pitch LSB (4)
	STA VIA_J+T1LL		; set T1 LSB (4)
	LDA ot_notes+1, X	; same for MSB (4)
	STA VIA_J+T1LH		; this will load upon next cycle (4)
; *** standard ISR exit with full register restore ***
ot_rti:
	_PLX				; restore regs and exit (4+4+6)
	PLA
ot_nmi:					; NMI is actually disabled
	RTI

; ********************
; *** diverse data ***
; ********************
; shifted bit patterns for diverse volume levels (hopefully!)
ot_patts:
	.byt	0			; 0 = MUTE
	.byt	%10000000	; 1 = 12.5%
	.byt	%10001000	; 2 = 25%
	.byt	%10010010	; 3 = 37.5%
	.byt	%10101010	; 4 = 50%
	.byt	%11101010	; 5 = 62.5%
	.byt	%11101110	; 6	= 75% (will not use 87.5% as per log ear response)
	.byt	%11111111	; 7 = 100%, continuous PB7 output

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

; *** create padding for stand-alone ROM ***
	.dsb	$FFFA-*, $FF

; *********************************
; *** 6502 hardware ROM vectors ***
; *********************************
* = $FFFA				; standard address
	.word	ot_nmi		; NMI	@ $FFFA
	.word	ot_init		; RST	@ $FFFC
	.word	ot_irq		; IRQ	@ $FFFE
