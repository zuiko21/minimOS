; firmware variables for minimOS·16
; v0.9.6b2
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20171114-0933

-sysram:
; 65816 systems have ram enough
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'V'			; CPU type ('B'=generic 65C02...)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
; should add some high ram and rom shadowing info
irq_freq	.word	200			; jiffys per second
