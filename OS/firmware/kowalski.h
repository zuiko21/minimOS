; firmware variables for minimOS on Kowalski simulator
; v0.9a1
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160331-0859

-sysram:
fw_table	.dsb	256, $0		; new address 150204, avoid speed penalty, move towards the end otherwise, NOT available in 128-byte systems
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'B'			; CPU type ('B'=generic 65C02...)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
