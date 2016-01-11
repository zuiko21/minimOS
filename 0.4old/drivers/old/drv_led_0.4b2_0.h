led_pos		.byt	0	; cursor position for LED keypad
led_len		.byt	4	; display size
led_buf		.dsb	4, 0	; 4-digit LED bitmap
led_mux		.byt	0	; LED digit displayed by ISR
ptr_page	.byt	3	; first allocatable RAM page!
; that was on dec-5...
buffer		.byt	0	; keypad buffer
buf_cont	.byt	0
buf_size	.byt	1
buf_read	.byt	0
buf_write	.byt	0
lkb_mat		.dsb	4, 0	; more keypad things
lkb_new		.byt	0
