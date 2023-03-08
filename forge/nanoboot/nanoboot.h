; zeropage variables for nanoBoot, v0.6b2
; (c) 2018-2023 Carlos J. Santisteban
; last modified 20230215-2220


timeout	= 2					; timeout counter (6510-savvy)
nb_cur	= timeout+2			; selected anode on LTC4622 display (or digit)
nb_disp	= nb_cur+1			; bitmap patterns (including selected anode)
nb_rcv	= nb_disp+4			; received value
nb_flag	= nb_rcv+1			; a byte is ready when zero (must be preset every byte)
nb_ptr	= nb_flag+1			; initial address, will be used as pointer (will reuse for screen drawing)
nb_fin	= nb_ptr+2			; final address (consecutive) after downloaded chunk
nb_ex	= nb_fin+2			; copy of initial address
; will use three more bytes temporarily
;__end	= nb_ex+2
