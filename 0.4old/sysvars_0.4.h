; minimOS 0.4b2 System Variables - SDx, 6502
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.19

.bss

#ifdef MTE
* = $0040	; for 128-byte RAM!
#else 
* = $0200
#endif

irqvec		.word	0	; ISR vector
himem		.byt	64	; number of SRAM pages
ptr_page	.byt	3	; first allocatable RAM page!
default_out	.byt	0
default_in	.byt	0
old_t1		.word	0	; keep old T1 latch value for FG

;driver-specific system variables come after this one, in main source
