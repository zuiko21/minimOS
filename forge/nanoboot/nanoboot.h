; zeropage variables for nanoBoot
; (c) 2018 Carlos J. Santisteban
; last modified 20180816-1747

.zero

* = 2				; 6510-compatible (uz on minimOS)

nb_ptr	.word	0		; initial address, will be used as pointer
nb_end	.word	0		; final address (consecutive)
nb_ex	.word	0		; keeps initial address
nb_rcv	.word	0		; received value (reset to 1)
nb_flag	.word	0		; a byte is ready if bit 7 is high

.text
