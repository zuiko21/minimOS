; optical Theremin (app version)
; (c) 2018 Carlos J. Santisteban
; v0.4b2
; last modified 20180320-1010

#include "usual.h"

; *** app version must use the usual header, install both IRQ (for handlers)
; and NMI (for exit!) routines and let the interrupts run...
; upon NMI will restore all interrupt handlers and exit as a regular app! ***

.(
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	ot_ddra		= uz			; previous VIA register values
	ot_ddrb		= ot_ddra+1
	ot_pcr		= ot_ddrb+1
	ot_acr		= ot_pcr+1
	ot_ier		= ot_acr+1
	ot_t1l		= ot_ier+1
	ot_oirq		= ot_t1l+2		; keep pointers to old interrupt routines!
	ot_onmi		= ot_oirq+3		; these might be 24b in 65816 systems!
; update final label!!!
	__last		= ot_onmi+3		; ##### just for easier size check ##### 65(C)02 could use +2

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
thHead:
; *** header identification ***
	BRK							; do not enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE		; minimOS app! it is 816 savvy
	.asc	"****", 13			; some flags TBD

; *** filename and optional comment ***
	.asc	"theremin", 0				; file name (mandatory)
	.asc	"Optical Theremin v0.4", 0	; comment

; advance to end of header
	.dsb	thHead + $F8 - *, $FF		; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4AC0		; time, 09.22
	.word	$4C73		; date, 2018/3/19

thSize	=	thEnd - thHead -$100		; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	thSize		; filesize
	.word	0			; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; ********************************
; *** initialise minimOS stuff ***
; ********************************

; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_th			; enough space
	BEQ go_th			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_th:
#endif
	STA z_used			; set needed ZP space as required by minimOS
; will not use iodev as will work on default device
; ##### end of minimOS specific stuff #####
	LDA #>banner		; address of banner message
	LDY #<banner
	STY str_pt			; store parameter
	STA str_pt+1
	LDY #0				; default device
	_KERNEL(STRING)		; print the string!

; new approach, notes are generated via PB7/T1 interrupts
; volume is set via PWM thru Serial register, T2 at full speed
; buzzer sounds when PB7=0 & CB2=1 (use a diode or suitable amp)
; volume polling was done every ~80ms, interrupt-driven could be up to 145ms, still OK

; *****************
; *** init code ***
; *****************
; must set SS in T2 free-run mode, T1 as continuous interrupts (toggling PB7)
; CA2 is independent interrupt on low-to-high (for pitch setting)
; now uses CA1 as volume interrupt, makes things simpler!
; PB7 and PA0...7 as output (no longer using PA7 for volume interrupt, now is volume MSB)
; pitch DAC thru weighted resistors at PA0...4, volume DAC at PA5-PA7 (now 3 bits)
; *** any previous config must be saved ***
; I/O direction
	SEI					; ***be safe while tinkering...
	LDA VIA_J+DDRA		; ***save previous DDRA (4+3)
	STA ot_ddra
	LDX #255			; whole bit mask (2)
	STX VIA_J+DDRA		; PA0...PA7 as output (4)
	INX					; now it is 0 (CMOS could just use STZ) (2)
	STA VIA_J+IORA		; reset DAC! (4)
	LDA VIA_J+DDRB		; current PB status (4)
	STA ot_ddrb			; ***saved! (3)
	ORA #%10000000		; set PB7 as output (2)
	STA VIA_J+DDRB		; do not disturb PB0...PB6 (4)
	LDA VIA_J+PCR		; original PCR settings (4)
	STA ot_pcr			; ***saved! (3)
	AND #$F0			; respect CBx
	ORA #%0111			; CA2 as independent positive edge, CA1 as positive edge
	STA VIA_J+PCR
; set timer modes
	LDA VIA_J+ACR		; ***save previous timer modes (4+3)
	STA ot_acr
	LDA #%11110000		; PB7 square wave, PB6 count (so far), free-run shift, no latching (2) 
	STA VIA_J+ACR		; set timer modes (4)
; enable suitable interrupts
	LDA VIA_J+IER		; ***save previous interrupt mask (4+3)
	STA ot_ier
	LDA #%11000011		; enable T1, CA1 & CA2 (2+4)
	STA VIA_J+IER
; ***must save timer latches too
	LDY VIA_J+T1LL		; T1 latch... (4+4+3+3)
	LDA VIA_J+T1LH
	STY ot_t1l
	STA ot_t1l+2
; start oscillator
	LDA #110			; counter LSB value, about 440Hz PB7 @ 1 MHz (will be set later, but at least get it running) (2)
	STA VIA_J+T1CL		; set counter (and latch) (4)
	LDA #4				; same for MSB (2)
	STA VIA_J+T1CH		; start counting! (4)
; *** set interrupt handlers, saving old routines!
; IRQ handler (as theremin is interrupt-driven)
	LDY #<ot_irq		; get pointer to new ISR
	LDA #>ot_irq
	STY ex_pt			; set firmware parameter
	STA ex_pt+1
	_U_ADM(SET_ISR)		; unusual firmware call!
	LDY ex_pt			; retrieve old address
	LDA ex_pt+1
	LDX ex_pt+2			; get bank just in case!
	STY ot_oirq			; and save it for later
	STA ot_oirq+1
	STX ot_oirq+2
; NMI handler (will allow exit)
	LDY #<ot_nmi		; get pointer to new handler
	LDA #>ot_nmi
	STY ex_pt			; set firmware parameter
	STA ex_pt+1
	_U_ADM(SET_NMI)		; unusual firmware call!
	LDY ex_pt			; retrieve old address
	LDA ex_pt+1
	LDX ex_pt+2			; get bank just in case!
	STY ot_onmi			; and save it for later
	STA ot_onmi+1
	STX ot_onmi+2
; enable interrupts and let theremin go... until NMI is hit!
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
	RTI

; ****************************************************
; *** NMI handler, will restore things and exit!!! ***
; ****************************************************
ot_nmi:
; just restoring state previous from app launch, discard registers and system pointers!
; all stored in zeropage, thus no need for stack
	LDA ot_ddra			; restore previous VIA register values
	STA VIA_J+DDRA
	LDA ot_ddrb
	STA VIA_J+DDRB
	LDA	ot_pcr
	STA VIA_J+PCR
	LDA ot_acr
	STA VIA_J+PCR
	LDX #255			; full mask for clearing pending interrupts
	LDA ot_ier			; this were the enabled interrupts (plus bit 7=1)
;	ORA #%10000000		; make sure d7 is 1, we want to enable them back
	STA VIA_J+IER		; re-enable as before
	STX VIA_J+IFR		; none pending
	LDY ot_t1l			; restore latches and counters
	LDA ot_t1l
	STY VIA_J+T1LL
	STA VIA_J+T1LH
	STA VIA_J+T1CH		; this will restore count!
	LDY ot_oirq			; get pointers to old interrupt routines!
	LDA ot_oirq+1
	STY kerntab
	STA kerntab+1
	_U_ADM(SET_ISR)
	LDY ot_onmi			; ditto for NMI
	LDA ot_onmi+1
	LDX ot_onmi+2		; this might be 24b in 65816 systems!
	STY ex_pt
	STA ex_pt+1
	STX ex_pt+2
	_U_ADM(SET_NMI)
; discard all status and exit to system
	_KERNEL(GET_PID)	; who am I?
	LDA #SIGKILL		; will suicide
	STA b_sig
	_KERNEL(B_SIGNAL)	; I am done...
#ifdef	SAFE
	_PANIC("{SIGKILL}")	; should never arrive here...
#endif

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

banner:
	.asc	"Theremin v0.4", CR
	.asc	"(hit NMI to exit)", CR, 0

thEnd:					; ### for easy size computation ###
.)
