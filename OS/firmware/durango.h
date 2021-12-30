; generic firmware variables for minimOS·65
; including Durango specifics
; v0.6.1a4
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20211230-1840

-sysram:
fw_isr
fw_irq		.word	0				; ISR vector (was fw_isr)
fw_nmi		.word	0				; NMI vector, fortunately checks for integrity
fw_brk
fw_dbg		.word	0				; BRK (debug) vector, eeeeeeeeeeeek
ticks		.dsb	4				; jiffy IRQ count (4 bytes) newest format 170822 relocated 211227
fw_warm		.word	0				; start of kernel, new 20150220
fw_cpu		.byt	'B'				; CPU type ('B'=generic 65C02...)
himem		.byt	0				; number of available 'kernel-RAM' pages, 0 means 128-byte RAM
; should add some high ram and rom shadowing info
irq_freq	.word	250				; jiffys per second
;old_t1		.word	0				; keep old T1 latch value for FREQ_GEN
#ifndef	LOWRAM
fw_table	.dsb	API_SIZE, $0	; more efficient usage 171114, NOT available in 128-byte systems
fw_lastk	.word	0				; address of last installed kernel jump table! new 20180116
#endif
fw_cbin		.byt	0				; integrated picoVDU/Durango-X specifics
fw_fnt		.word	0				; (new, pointer to relocatable 2KB font file)
fw_mask		.byt	0				; (for inverse/emphasis mode)
fw_chalf	.byt	0				; (remaining pages to write)
fw_sind		.dsb	3, 0
fw_ccol		.dsb	4, 0			; (no longer SPARSE array of two-pixel combos, will store ink & paper)
fw_ctmp
fw_cbyt		.byt	0				; (temporary glyph storage) other tmp
fw_ccnt		.byt	0				; (bytes per raster counter, no longer X) other tmp
fw_ciop		.word	$6000			; cursor position
fw_vbot		.byt	$60				; page start of screen at current hardware setting (updated upon FF)
fw_vtop		.byt	$80				; first non-VRAM page (new)
fw_io9		.byt	0				; received keypress
