; zeropage variables for nanoBoot, v0.3a3
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20201227-1526

.zero

* = 2						; 6510-compatible (uz on minimOS)

#ifdef	TIMEBOOT
timeout	.word	0			; timeout counter
#endif
#ifdef	DISPLAY
nb_cur	.byt	0			; selected anode on LTC4622 display (or digit)
nb_disp	.dsb	4, 0		; bitmap patterns (including selected anode)
#endif
nb_rcv	.byt	0			; received value
nb_flag	.byt	0			; a byte is ready when zero (must be preset every byte)
nb_ptr	.word	0			; initial address, will be used as pointer
nb_fin	.word	0			; final address (consecutive) after downloaded chunk
nb_ex	.word	0			; copy of initial address
; will use three more bytes temporarily

.text
