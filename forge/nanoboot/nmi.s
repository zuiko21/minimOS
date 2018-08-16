; nanoBoot NMI handler for 6502
; (c) 2018 Carlos J. Santisteban
; last modified 20180816-1609

nb_nmi:
	SEC
	ROL nb_rcv			; prepare for next bit, initially on (2+5)
	CLI					; enable IRQ for a moment... (2)
	SEI					; ...and disable it back! (2)
	BCC nbn_end			; leading C still inside, not yet (3/2)
		PHA					; be clean... (3)
		LDA nb_rcv			; what was received...(3)
		STA (nb_ptr), Y		; ...will be stored (5)
		INY					; go for next (2)
		BNE nbr_nw			; check for wrap below (3/2+5)
			INC nb_ptr+1
nbr_nw:
; cleanup
		LDA #1
		STA nb_rcv			; reset receiving value (2+3)
		PLA					; restore and exit (4)
nbn_end:
	RTI					; (6)

; worst case 7+2+*+2+2+3+3+5+2+7+2+3+4+6 clocks

