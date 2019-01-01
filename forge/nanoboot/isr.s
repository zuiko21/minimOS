; nanoBoot ISR for 6502
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180818-1021

nb_irq:
	LSR nb_rcv		; mimick IRQ level on least significant bit...
	ASL nb_rcv		; ...without affecting other than state
; not sure if while IRQ is held low, this will be retriggered upon return
; although will affect A, it is safer to mask I into the saved status
	PLA				; saved status...
	ORA #%00000100	; ...now with I set
	PHA				; restore all (A changed)
	RTI			; total 16 clocks! if on zeropage
; if I flag is to be set, takes 9 extra clocks (total 25)
