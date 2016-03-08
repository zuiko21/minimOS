; firmware variables for minimOS 0.5a2
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160308

-sysram:
#ifndef		LOWRAM
fw_table	.dsb	256, $0		; new address 150204, avoid speed penalty, move towards the end otherwise, NOT available in 128-byte systems
#endif
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'B'			; CPU type ('B'=generic 65C02...)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
