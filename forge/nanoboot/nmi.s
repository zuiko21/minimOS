; nanoBoot NMI handler for 6502
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190110-1219

nb_nmi:
	SEC
	ROL nb_rcv			; prepare for next bit, initially on (2+5)
	PHA					; must save A before IRQ! (3)
	CLI					; enable IRQ for a moment... (2)
	SEI					; ...and disable it back! (2)
	PLA					; restored (4)
; do not know if keeping IRQ low will retrigger the interrupt
; perhaps ISR should alter saved status masking I, anyway this SEI is needed
; will affect A, worth saving it here
	ROL nb_flag			; this will set bit 7 after eight executions (5) EEEEEEEEEEEK
	RTI					; (6) total 29 clocks + ISR
; 7 clocks to acknowledge IRQ plus 25 of the ISR itself, grand total 61 clocks
