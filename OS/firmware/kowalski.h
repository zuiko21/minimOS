; firmware variables for minimOS on Kowalski simulator
; v0.9.6a1
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20170822-1552

-sysram:
#ifndef	LOWRAM
fw_table	.dsb	256, $0		; new address 150204, avoid speed penalty, move towards the end otherwise, NOT available in 128-byte systems
#endif
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_brk		.word	0			; BRK vector, new
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'B'			; CPU type ('B'=generic 65C02...)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
irq_freq	.word	200			; just in case

; kernel sysvars to follow
