; nanoBoot-SO NMI handler for 6502, v0.2a1
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190112-1700

nb_nmi:
	CLV					; allow zero by default eeeeek (2)
	CLC					; let us insert a zero... (2)
	BVC nn_vc			; ...if no overflow (3/4)
		SEC					; ...otherwise set it
nn_vc:
	ROL nb_rcv			; inject new bit (5)
	SEC					; must set another bit on flag (2)
	ROR nb_flag			; this will set bit 7 after 8 shifts (5)
	RTI					; (6) total 25/26 clocks plus 7 of NMI
