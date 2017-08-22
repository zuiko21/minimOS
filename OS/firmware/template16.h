; firmware variables for minimOS·16
; v0.9.6a1
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20170822-1555

-sysram:
; 65816 systems have ram enough
fw_table	.dsb	256, $0		; new address 150204, avoid speed penalty, move towards the end otherwise, NOT available in 128-byte systems
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'V'			; CPU type ('B'=generic 65C02...)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
; should add some high ram and rom shadowing info
irq_freq	.word	200			; jiffys per second
