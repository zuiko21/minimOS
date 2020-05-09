; FW module extensive memory test for minimOS
; (c) 2020 Carlos J. Santisteban
; last modified 20200509-1207

; *** check zeropage ***

	LDX #0
mt_zp:
		TXA
		STA 0, X
		INX
		BNE mt_zp
mt_zchk:
		TXA
		CMP 0, X
			BNE mt_erz
		INX
		BNE mt_zp

