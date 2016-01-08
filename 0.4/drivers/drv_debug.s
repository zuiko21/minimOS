; minimOS 0.4b4 DEBUG Porculete driver, 65C02 SDx
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.05.05


; *** begins with sub-function addresses table ***
	.word	led_reset	; initialize device and appropiate sysvars, called by POST only
	.word	led_get		; poll, read keypad into buffer (called by ISR)
	.word	ledg_rts	; req, his one can't generate IRQs, thus SEC+RTS
	.word	led_cin		; cin, input from buffer
	.word	led_cout	; cout, output to display
	.word	ledg_rts	; NEW, 1-sec, no need for 1-second interrupt
	.word	ledg_rts	; NEW, sin, no block input
	.word	ledg_rts	; NEW, sout, no block output
	.word	ledg_rts	; NEWER, bye, no shutdown procedure
	.byt	%10110000	; poll, no req., I/O, no 1-sec and neither block transfers, non relocatable (NEWEST HERE)
	.byt	0		; reserved for new 20-byte block

; *** output ***
led_cout:
	LDA z2			; get char in case is control
	CMP #13			; carriage return? (shouldn't just clear, but wait for next char instead...)
	BNE no_blank	; if so, clear LED display
	STZ _VIA+_iora
	STZ _VIA+_iorb
	_BRA led_end
no_blank:
	LDX _VIA+_iora	; take last char
	STX _VIA+_iorb	; scroll to the left
	STA _VIA+_iora	; 'print' character
led_end:
	_EXIT_OK

; *** input ***
led_cin:
	_ERR(_empty)	; mild error, so far

; *** poll ***
led_get:
	INC sysvar		; interrupt counter, every 1.28 seconds
	BNE led_end		; not much to do in the while
	LDA _VIA+_pcr	; get CB2 status
	EOR #%00100000	; toggle CB2
	STA _VIA+_pcr	; set CB2 status
ledg_rts:
	_EXIT_OK

; *** initialise ***

led_reset:
	_STZA _VIA+_iora	; clear digits
	_STZA _VIA+_iorb	; clear digits
	LDA #$FF		; all output
	STA _VIA+_ddra	; set direction
	STA _VIA+_ddrb
	_STZA sysvar	; some more odd init code
	_EXIT_OK
