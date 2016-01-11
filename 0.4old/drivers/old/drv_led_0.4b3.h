; minimOS 0.4b3 LED-keypad variables
; (C) 2013 Carlos J. Santisteban
; last modified 2013.02.21

led_len		.byt	4	; display size, please keep order!
led_mux		.byt	0	; LED digit displayed by ISR
led_pos		.byt	0	; cursor position for LED keypad
led_buf		.dsb	4, 0	; 4-digit LED bitmap, lastly
; that was on dec-5...
buf_size	.byt	1	; first buffer variable, please keep order!
buf_cont	.byt	0
buf_read	.byt	0
buf_write	.byt	0
buffer		.byt	0	; keypad buffer, keep it last
lkb_new		.byt	0	; more keypad things
lkb_mat		.dsb	4, 0

