; minimOS 0.4b2 LED-keypad variables
; (C) 2013 Carlos J. Santisteban
; last modified 2013.02.19

led_pos		.byt	0	; cursor position for LED keypad
led_len		.byt	4	; display size
led_buf		.dsb	4, 0	; 4-digit LED bitmap
led_mux		.byt	0	; LED digit displayed by ISR
; that was on dec-5...
buffer		.byt	0	; keypad buffer
buf_cont	.byt	0
buf_size	.byt	1
buf_read	.byt	0
buf_write	.byt	0
lkb_mat		.dsb	4, 0	; more keypad things
lkb_new		.byt	0
