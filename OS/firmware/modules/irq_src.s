; firmware module for minimOS·65 (& ·16)
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20180124-0855

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
;		OUTPUT
; *** X	= 0 (periodic), 2 (async IRQ @ 65xx) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values hardware dependent
; 65816 MUST be called on 8-bit sizes! Otherwise NMOS savvy

-irq_src:
.(
	BIT VIA_J+IFR		; much better than LDA + ASL + BPL! (4)
	BVS fis_per			; from T1 (3/2)
		LDX #2				; standard async otherwise (0/2)
		RTS					; no error handling for speed! (0/6)
fis_per:
	LDA VIA_J+T1CL		; acknowledge periodic interrupt!!! (4)
	LDX #0				; standard value for jiffy IRQ (2)
	RTS					; return ASAP, all OK (6)
.)
