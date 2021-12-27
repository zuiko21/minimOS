; firmware module for minimOS·65 (& ·16)
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20211227-1751

; ****************************************
; IRQ_SRC, investigate source of interrupt *** for non-VIA systems
; ****************************************
;		OUTPUT
; *** X	= 0 (periodic), 2 (async IRQ @ 65xx) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values hardware dependent
; 65816 MUST be called on 8-bit sizes! Otherwise NMOS savvy

-irq_src:
	LDA IOAie				; check interrupt status
	AND #1					; only d0 is on for periodic interrupts
	EOR #1					; ...the opposite is expected...
	ASL						; ...times two!
	TAX						; special ABI
