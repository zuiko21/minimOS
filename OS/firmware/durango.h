; generic firmware variables for minimOS·65
; including Durango specifics
; v0.6a7
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20210409-1353

-sysram:
fw_isr		.word	0				; ISR vector
fw_nmi		.word	0				; NMI vector, fortunately checks for integrity
fw_dbg		.word	0				; BRK (debug) vector, eeeeeeeeeeeek
fw_warm		.word	0				; start of kernel, new 20150220
fw_cpu		.byt	'B'				; CPU type ('B'=generic 65C02...)
himem		.byt	0				; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
; should add some high ram and rom shadowing info
irq_freq	.word	244				; jiffys per second
old_t1		.word	0				; keep old T1 latch value for FREQ_GEN
#ifndef	LOWRAM
fw_table	.dsb	API_SIZE, $0	; more efficient usage 171114, NOT available in 128-byte systems
fw_lastk	.word	0				; address of last installed kernel jump table! new 20180116
#endif
fw_cbin		.byt	0				; integrated picoVDU-specifics
fw_ciop		.word	0
fw_io9		.byt	0				; received keypress
