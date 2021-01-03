; firmware module for minimOS·65 (& ·16)
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20190118-0945

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
;		OUTPUT
; *** X	= 0 (periodic), 2 (async IRQ @ 65xx) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values hardware dependent
; 65816 MUST be called on 8-bit sizes! Otherwise NMOS savvy
; *** *********** TWEAKED version for run02/run816 *********** ***
; *** ALWAYS returns as ASYNC interrupt, allowing BRK handler! ***
-irq_src:
.(
	LDX #2				; always async! (2)
	RTS					; no error handling for speed! (6)
.)
