; Bankswitching PSM player via PSG on Durango·X
; (c) 2023 Carlos J. Santisteban
; last modified 20231230-1824
; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 102 cycles/sample for 15 kHz rate (actually 15059 Hz)
; loading PSG every 34 cycles makes a three-times oversampling digital filter!
; some jitter is acceptable, as long as the main samples are loaded every 102t

.(
; *** definitions ***
IO_PSG	= $DFDB				; PSG
IOBank	= $DFFC				; Bankswitching register
pb_buf	= $8000				; play back from mirrored ROM, no I/O page between $8000-$BFFF!
end_buf	= $BC00

; *** zeropage usage ***
sample	= $FE				; indirect pointer to audio sample
temp	= $FD				; temporary usage for delays

reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10011111			; channel 1 max. attenuation
init:
		STA IO_PSG			; shut off all channels
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	CLC
	LDA #%10000001			; channel 1 freq. to 1 => DC output
set:
		STA IO_PSG			; make all channels play
		JSR delay2
		INC temp
		NOP					; some more delay (24+5+2)
		STZ IO_PSG			; set MSB to zero (total 35 between writes)
		JSR delay2
		NOP					; 26t of delay
		ADC #32
		BMI set				; complete cycle +2+3+4, total 35t

	JSR delay;CHECK
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
; CHECK THESE DELAYS
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
; *** new code ***
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value (ch1) from high nybble
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			JSR delay2		; 24
			NOP				; 2
			NOP				; 2
			ORA #%01000000	; 2 turn into ch3
			STA IO_PSG		; 4 next output
			JSR delay2		; 24
			NOP				; 2
			NOP				; 2
			AND #%11011111	; 2 turn into ch2
			STA IO_PSG		; 4 next output
; ditto for the low nybble! always 102t


			LDA (sample), Y	; 5
			TAX				; 2
			LDA lo_nyb, X	; 4 get PSG value from low nybble eeeeek
			JSR delay2		; 24
			JSR delay2		; 24
			STA temp		; 3
			NOP
			NOP				; 2+2
			STA IO_PSG		; 4
; go for next byte
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #>end_buf		; 2 already at code page? eeeek
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
#if	nxt_bnk<lst_bnk
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)
#else
; *** *** playback ends here, do not switch banks *** ***
	CLC
	LDA #%10011111			; max. attenuation for channel 1
quiet:
		JSR delay2
		NOP					; suitable delay
		STA IO_PSG			; shut this channel down
		ADC #32				; next channel
		BMI quiet
	STA $DFA0				; turn off LED
lock:
	JMP lock				; THIS IS THE LAST ONE
#endif
; *** auxiliary code ***
delay2:						; 24 calling this
	JSR delay
delay:						; 12 calling this
	RTS

; *** look-up tables ***
	.dsb	$FD00-*, $FF	; make certain it's page-aligned for timing accuracy!
hi_nyb:
	.dsb	16, $9F
	.dsb	16, $9E
	.dsb	16, $9D
	.dsb	16, $9C
	.dsb	16, $9B
	.dsb	16, $9A
	.dsb	16, $99
	.dsb	16, $98
	.dsb	16, $97
	.dsb	16, $96
	.dsb	16, $95
	.dsb	16, $94
	.dsb	16, $93
	.dsb	16, $92
	.dsb	16, $91
	.dsb	16, $90
;	.dsb	$FE00-*, $FF	; already there
lo_nyb:
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
	.byt	$9F, $9E, $9D, $9C, $9B, $9A, $99, $98, $97, $96, $95, $94, $93, $92, $91, $90
; ************************
; *** fill and vectors ***
; ************************
	.dsb	$FFD5-*, $FF
; *** void interrupt handlers ***
irq_hndl:
nmi_hndl:
	RTI
	.asc	"DmOS"			; standard minimOS signature
; *** bankswitching code ***
	.dsb	$FFDE-*, $FF
switch:
	STA IOBank				; 3 set bank from A...
	JMP ($FFFC)				; 6 ...and restart from it!

	.dsb	$FFFA-*, $FF

	.word nmi_hndl			; NMI will do warm start
	.word reset				; RESET does full init
	.word irq_hndl			; IRQ will do nothing
.)
