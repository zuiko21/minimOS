; zeropage variables for nanoBoot, v0.2a2
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190219-1422

.zero

* = 2				; 6510-compatible (uz on minimOS)

nb_rcv	.word	0		; received value
nb_flag	.word	0		; a byte is ready if bit 7 is high (must be reset every byte)
nb_ptr	.word	0		; initial address, will be used as pointer
nb_fin	.word	0		; final address (consecutive) after downloaded chunk
nb_ex	.word	0		; copy of initial address
; will use three more bytes temporarily

#ifdef	TIMEBOOT
timeout	.word	0		; timeout counter
#endif
.text
