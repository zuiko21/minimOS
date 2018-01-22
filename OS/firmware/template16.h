; firmware variables for minimOS·16
; v0.6a4
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180122-1303

-sysram:
; 65816 systems have enough RAM
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
fw_lastk	.word	0				; address of last installed kernel jump table! new 20180116
fw_isr		.dsb	3, 0			; ISR vector ***could be set by app, thus 24-bit ***
fw_nmi		.dsb	3, 0			; NMI vector, fortunately checks for integrity *** ditto above ***
fw_dbg		.dsb	3, 0			; BRK vector eeeeeeeeeeeek
fw_warm		.word	0				; start of kernel, new 20150220, 16-bit size
fw_cpu		.byt	'V'				; CPU type ('V'=65C816)
himem		.byt	0				; number of available 'kernel-RAM' pages
; should add some high ram and rom shadowing info
banks		.byt	0				; number of RAM banks (placeholder)
irq_freq	.word	200				; jiffys per second
