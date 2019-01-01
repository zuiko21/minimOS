; LED-keypad driver 0.9.6 variables
; (c) 2013-2019 Carlos J. Santisteban
; last modified 20171220-1346

; now defines here number of digits (nominally 4)
#define		DIGITS	4

; stupid led_len no longer used!
led_mux		.byt	0		; LED digit displayed by ISR
led_pos		.byt	0		; cursor position for LED keypad
led_buf		.dsb	DIGITS, 0	; 4-digit LED bitmap, lastly
; that was on dec-5...
lkp_cont	.byt	0		; specific single-byte buffer flag, new 130507
lkp_buf		.byt	0		; specific single-byte keypad buffer
lkp_new		.byt	0		; more keypad things, last decoded scancode
lkp_mat		.dsb	DIGITS, 0	; temporary column storage

