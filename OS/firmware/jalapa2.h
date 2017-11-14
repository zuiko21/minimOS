; firmware variables for minimOS•16 on Jalapa2
; v0.9.6b2
; (c) 2017 Carlos J. Santisteban
; last modified 20171114-0932

-sysram:
; no LOWRAM option for 65816
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
fw_isr		.dsb	3			; ISR vector
fw_nmi		.dsb	3			; NMI vector, fortunately checks for integrity
fw_brk		.dsb	3			; BRK vector, set by new SET_DBG
fw_warm		.word	0			; start of kernel, new 20150220
fw_cpu		.byt	'V'			; CPU type ('V'= 65C816)
himem		.byt	0			; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
; perhaps should add some 'high' memory measurement, and ROM shadowing
irq_freq	.word	200			; jiffy interrupts per second, was into sysvars

; kernel sysvars to follow
