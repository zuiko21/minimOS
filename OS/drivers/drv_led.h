; LED-keypad driver 0.9 variables
; (c) 2013-2015 Carlos J. Santisteban
; last modified 20150126-1214

led_len		.byt	4		; display size, please keep order!
led_mux		.byt	0		; LED digit displayed by ISR
led_pos		.byt	0		; cursor position for LED keypad
led_buf		.dsb	4, 0	; 4-digit LED bitmap, lastly
; that was on dec-5...
lkp_cont	.byt	0		; specific single-byte buffer flag, new 130507
lkp_buf		.byt	0		; specific single-byte keypad buffer
lkp_new		.byt	0		; more keypad things, last decoded scancode
lkp_mat		.dsb	4, 0	; temporary column storage

