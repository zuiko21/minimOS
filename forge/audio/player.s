; 4-bit PCM audio player for PSG and bankswitching cartridge! (16K banks)
; (c) 2023 Carlos J. Santisteban
; last modified 20231210-1208

; *** definitions ***
IO_PSG	= $DFDB				; PSG
IOBank	= $DFFC				; Bankswitching register
pb_buf	= $8000				; play back from mirrored ROM, no I/O page between $8000-$BFFF!

; *** zeropage usage ***
sample	= $FE				; indirect pointer to audio sample
temp	= $FD				; temporary usage for delays
nxt_bnk	= 1					; increment this between banks!

; * BANK 0 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio0.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 1 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio1.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 2 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio2.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 3 *
; *** audio data ***
* = $C000

;	.bin	0, 0, "audio3.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 4 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio4.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 5 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio5.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 6 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio6.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)

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

; * BANK 7 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio7.4bit"			; 15 KiB 4-bit PCM audio chunk!

; ***************************
; *** player code ($FC00) ***
; ***************************
; aim to 70 cycles/sample for 22.05 kHz rate (actually 0.6% slower)
.(
reset:
; first playing bank has PSG initialising code
#ifndef PSGINIT
#define	PSGINIT
	CLC
	LDA #%10111111			; channel 2 max. attenuation
init:
		STA IO_PSG			; shut off all channels (except 1)
		JSR delay2
		NOP					; to be safe (35t total delay)
		ADC #32
		BMI init
	LDA #%10000001			; channel 1 freq. to 1 => DC output
	STA IO_PSG
	JSR delay2
	JSR delay
	STZ IO_PSG				; set MSB to zero
#else
	-nxt_bnk = nxt_bnk + 1	; just compute next bank number
#endif
; *** standard bank playing code ***
	LDY #<pb_buf			; 2 actually 0 eeek
	STY sample				; 3 eeeek
	LDA #>pb_buf			; 2 eeeek
	STA sample+1			; 3 eeeek
	JMP first				; 3 skip extra delay
h_nopage:
	JSR delay				; 12 delays up to 38+12=50t
h_nobank:
		JSR delay2			; 24
		NOP					; 2 delays up to 12+26=38t
first:
			LDA (sample), Y	; 5
			TAX				; 2
			LDA hi_nyb, X	; 4 get PSG value from high nybble
			JSR delay		; 12t minimal delay section
			STA IO_PSG		; 4 send sample to output (avoiding jitter)
			INY				; 2
			BNE h_nopage	; 3 total for non-page = 20t (lacking 50t)
		INC sample+1		; -1+5 next page
		LDA sample+1		; 3
		CMP #$FC			; 2 already at code page?
		BNE h_nobank		; 3 nope, next page = 32t (lacking 38t eeek)
	LDA #nxt_bnk			; -1+2 next bank address
;	JMP switch				; 3+9 then 10+3 after switching = 58t (lacking just 12t)
; *** *** playback ends here, do not switch banks *** ***
	JSR delay2
	LDA #%10011111			; max. attenuation for channel 1
	STA IO_PSG
lock:
	JMP lock				; THIS IS THE LAST ONE
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
