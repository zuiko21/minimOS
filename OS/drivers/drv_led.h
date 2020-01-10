; LED-keypad driver 0.9.6 variables
; (c) 2013-2020 Carlos J. Santisteban
; last modified 20200110-0933

; now defines here number of digits (nominally 4)
#define		DIGITS	4

; stupid led_len no longer used!
led_mux		.byt	0			; LED digit displayed by ISR
led_pos		.byt	0			; cursor position for LED keypad
led_buf		.dsb	DIGITS, 0	; 4-digit LED bitmap, lastly
; that was on dec-5...
lkp_cont	.byt	0			; shift mode flag instead of buffer not-empty flag 200110
lkp_buf		.byt	0			; specific single-byte keypad buffer (0 means empty, no longer has flag)
lkp_new		.byt	0			; more keypad things, last decoded scancode
lkp_mat		.dsb	DIGITS, 0	; temporary column storage

