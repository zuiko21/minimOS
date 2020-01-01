; nanoBoot NMI handler for 6502 v0.2a1
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20190112-1630

nb_nmi:
	SEC
	ROL nb_rcv			; prepare for next bit, initially on (2+5)
; do not know if keeping IRQ low will retrigger the interrupt
; ISR should alter saved status masking I, anyway this SEI is needed
; as it will affect A, must be kept here
	PHA					; must save A before IRQ! (3)
	CLI					; enable IRQ for a moment... (2)
; if IRQ is low, will clear nb_rcv LSB, otherwise will stay set
	SEI					; ...and disable it back! (2)
	PLA					; restored (4)
	ROL nb_flag			; this will set bit 7 after eight executions (5) EEEEEEEEEEEK
	RTI					; (6) total 29 clocks + ISR
; 7 clocks to acknowledge IRQ plus 25 of the ISR itself, grand total 61 clocks
