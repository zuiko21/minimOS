; firmware variables for minimOS on Chihuahua (PLUS)
; v0.9.6b2
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20171114-0929

-sysram:
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_brk		.word	0			; BRK vector eeeeeeeeeek
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'B'			; CPU type ('B'=generic 65C02...)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
irq_freq	.word	200			; jiffy interrupts per second, was into sysvars

; kernel system variables to follow
