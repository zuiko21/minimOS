; nanoBoot ISR for 6502
; (c) 2018 Carlos J. Santisteban
; last modified 20180816-1641

nb_isr:
	LSR nb_rcv		; mimick IRQ level on least significant bit...
	ASL nb_rcv		; ...without affecting other than state
	RTI			; total 16 clocks! if on zeropage
