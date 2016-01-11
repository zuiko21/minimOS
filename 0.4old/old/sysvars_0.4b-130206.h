; minimOS 0.4b2 System Variables - SDx, 6502
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.06

.bss

* = $0200

irqvec		.word	isr	; ISR vector
himem		.byt	64	; number of SRAM pages
default_out	.byt	0
default_in	.byt	0
old_t1		.word	0	; keep old T1 latch value for FG

;driver-specific system variables come after this one, in main source
