; zeropage variables for nanoBoot, v0.3a1
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20201226-1315

.zero

* = 2						; 6510-compatible (uz on minimOS)

#ifdef	TIMEBOOT
timeout	.word	0			; timeout counter
#endif
nb_rcv	.byt	0			; received value
nb_flag	.byt	0			; a byte is ready when zero (must be preset every byte)
nb_ptr	.word	0			; initial address, will be used as pointer
nb_fin	.word	0			; final address (consecutive) after downloaded chunk
nb_ex	.word	0			; copy of initial address
; will use three more bytes temporarily

.text
