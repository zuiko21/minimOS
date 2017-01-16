; firmware variables for minimOS on run65816 BBC simulator
; v0.9b1
; (c) 2017 Carlos J. Santisteban
; last modified 20170116-0901

-sysram:
#ifndef	LOWRAM
fw_table	.dsb	256, $0		; new address 150204, avoid speed penalty, move towards the end otherwise, NOT available in 128-byte systems
#endif
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'V'			; CPU type ('V'= 65C816)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
