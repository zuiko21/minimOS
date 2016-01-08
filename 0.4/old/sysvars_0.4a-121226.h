; minimOS 0.4a2 System Variables - SDx, 6502
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.26

.bss

* = $0200

irqvec		.word	isr	; ISR vector
led_pos		.byt	0	; cursor position for LED keypad
led_len		.byt	4	; display size
led_buff	.dsb	4, 0	; 4-digit LED bitmap
led_digit	.byt	0	; LED digit displayed by ISR
ptr_page	.byt	3	; first allocatable RAM page!
; that was on dec-5...
himem		.byt	64	; number of SRAM pages
