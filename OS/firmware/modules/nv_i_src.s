; firmware module for minimOS·65 (& ·16)
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20211231-1621

; ****************************************
; IRQ_SRC, investigate source of interrupt *** for non-VIA systems
; ****************************************
;		OUTPUT
; *** X	= 0 (periodic), 2 (async IRQ @ 65xx) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values hardware dependent
; 65816 MUST be called on 8-bit sizes! Otherwise NMOS savvy

; note Durango-X cannot check interrupt enable status!
; will only return ASYNC if BRK
-irq_src:
	TSX
	LDA $104,X
	AND #$10				; ···B···· BRK flag
	LSR						; ····B···
	LSR						; ·····B··
	LSR						; ······B· means 0 if periodic, 2 if BRK!
	TAX						; special ABI, cannot tell otherwise
