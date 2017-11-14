; firmware variables for minimOS on run65816 BBC simulator
; 8-bit kernels!
; v0.9.6b2
; (c) 2017 Carlos J. Santisteban
; last modified 20171114-0932

-sysram:
; lowram option for testing only
#ifndef	LOWRAM
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
#endif
fw_isr		.word	0			; ISR vector
fw_nmi		.word	0			; NMI vector, fortunately checks for integrity
fw_brk		.word	0			; BRK vector, new 20170602
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'V'			; CPU type ('V'= 65C816)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
irq_freq	.word	200			; jiffys per second

; kernel sysvars to follow
