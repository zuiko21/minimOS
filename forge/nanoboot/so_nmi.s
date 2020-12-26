; nanoBoot-SO NMI handler for 6502, v0.3a1
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20201226-1330

nb_nmi:
; received bits should be LSB first!
	CLV					; allow zero by default eeeeek (2)
	SEC					; let us insert a one... (2) eeeeeek
	BVC nn_vc			; ...if no overflow (3/4)
		CLC				; ...otherwise clear it
nn_vc:
	ROR nb_rcv			; inject C into byte, LSB first (5)
	DEC nb_flag			; this will turn 0 when done, if preloaded with 8 (5)
	RTI					; (6) total 23/24 clocks plus 7 of NMI, worst case 31 per bit
