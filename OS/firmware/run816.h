; firmware variables for minimOS on run65816 BBC simulator
; v0.9.6b2
; (c) 2017 Carlos J. Santisteban
; last modified 20171114-0933

-sysram:
; lowram option for testing purposes only
#ifndef	LOWRAM
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
#endif
fw_isr		.dsb	3			; ISR vector
fw_nmi		.dsb	3			; NMI vector, fortunately checks for integrity
fw_brk		.dsb	3			; BRK vector, new
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'V'			; CPU type ('V'= 65C816)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
irq_freq	.word	200			; jiffy IRQs per second, still unused

; kernel sysvars to follow
