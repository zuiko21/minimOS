; nanoBoot-SO NMI handler for 6502, v0.3a3
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20201227-1604

nb_nmi:
; received bits should be LSB first!
	SEC					; let us insert a one... (2) eeeeeek
	BVC nn_vc			; ...if no overflow (3/4)
		CLC				; ...otherwise clear it
nn_vc:
	CLV					; back to default ASAP eeeeek (2)
	ROR nb_rcv			; inject C into byte, LSB first (5)
	DEC nb_flag			; this will turn 0 when done, if preloaded with 8 (5)
	RTI					; (6) total 23/24 clocks plus 7 of NMI, worst case 31 per bit
