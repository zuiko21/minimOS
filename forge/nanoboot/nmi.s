; nanoBoot NMI handler for 6502
; (c) 2018 Carlos J. Santisteban
; last modified 20180816-1722

nb_nmi:
	SEC
	ROL nb_rcv			; prepare for next bit, initially on (2+5)
	CLI					; enable IRQ for a moment... (2)
	SEI					; ...and disable it back! (2)
	ROR nb_flag			; this will set bit 7 accordingly (5)
	RTI					; (6) total 22 clocks + ISR
