; nanoBoot NMI handler for 6502 v0.4a1
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20210202-1845

nb_nmi:
; received bits should be LSB first!
	CLC					; bits are *OFF* by default, will be inverted later (2)
	PHA					; preserve A, as ISR will change it! (3)
	CLI					; enable interrupts for a moment (2...)
; if /IRQ was low, ISR will *set* C, thus injecting a one
	SEI					; what happened? (2)
#ifdef	NBBEEP
; ** extra code in case feedback thru IOB is needed **
; ** may SEVERELY impair bit rate (+13t, worst total of 71t vs. 58) **
	PHP					; put C (and others) in stack
	PLA					; back as D0 (inverted!)
	EOR #1				; ** CHECK THIS
	STA $BFFF			; store at beeper flipflop
#endif
	PLA					; retrieve A, but C won't be affected (4)
	ROR nb_rcv			; inject C into byte, LSB first (5)
	DEC nb_flag			; this will turn 0 when done, if preloaded with 8 (5)
nb_rti:
	RTI					; (6) total 29, plus ISR
; ISR takes 7 clocks to acknowledge, plus 15 clocks itself, that's 22t for a grand total (including NMI ack) of 58 clocks per bit worst case
