; minimOS 0.4b3? LED keypad driver, 6502 -- update
; (c) 2013 Carlos J. Santisteban
; last modified 2013.02.21

#define _kp_size	1
#define _led_digits	4

led_reset:
;	LDA #>(_VIA+_ddra)	; VIA MSB
;	STA z2+1		; parameter for su_poke()
;	LDA #<(_VIA+_ddra)	; LSB for DDRA
;	STA z2			; this one will change...
	LDY #%11110000		; bits PA4...7 for output
;	_KERNEL(_su_poke)	; set DDRA cleanly
	STY _VIA+_ddra		; easier with unprotected I/O, it's within kernel code anyway
;	LDA #<(VIA+_ddrb)	; LSB for DDRB (MSB remains!)
;	STA z2
	LDY #$FF		; PB is all output
;	_KERNEL (_su_poke)	; set DDRB cleanly
	STY _VIA+_ddrb		; easier with unprotected I/O, it's within kernel code anyway
	LDA #_kp_size		; keyboard buffer size, 1 should do fine w/o multitasking
	STA buf_size		; first byte of the pack
	CLC			; let's make a counter for the bytes to be cleared
	ADC #3			; cont+read+write (+ the buffer itself)
	TAX			; set counter as offset (won't reach first byte)
	LDA #0			; there's STZ on CMOS, but NMOS macros are worse here
led_bufclr:
	STA buf_siz, X		; clear variable... but may be protected in future?
	DEX			; previous
	BNE led_bufclr		; won't reach offset 0, where the size is stored!
	LDA #_led_digits	; display size
	STA led_len		; first byte of the pack
	CLC			; let's make a counter for the bytes to be cleared
	ADC #2			; mux+pos (+ the buffer itself)
	TAX			; set counter as offset (won't reach first byte)
	LDA #0			; there's STZ on CMOS, but NMOS macros are worse here
led_dispcl:
	STA led_len, X		; clear variable
	DEX			; previous
	BNE led_dispcl		; won't reach offset 0, where the size is stored!
	LDX led_len		; let's clear the keypad -- same columns as display, so far!
led_matclr:
	STA lkb_new, X		; clear variable
	DEX			; previous
	BPL led_matclr		; do 0 too, this must reset lkb_new too!
;	LDA #<(_VIA+_pcr)	; PCR LSB
;	STA z2			; let's hope the MSB stays OK!
;	_KERNEL(_su_peek)	; not really necessary, but...
;	TYA			; get current value
	LDA _VIA+_pcr		; easier with unprotected I/O
	AND #%00011111		; keep other PCR bits
	OR #%11000000		; CB2 low (display enable)
	STA _VIA+_pcr		; instead of the rest
;	TAY			; set new value
;	_KERNEL(_su_poke)	; update VIA register cleanly...
	_EXIT_OK
