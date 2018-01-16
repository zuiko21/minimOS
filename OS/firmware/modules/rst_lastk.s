; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20180116-1055

; reset last installed kernel pointer!
; no interface needed, affects FW vars

	_STZA fw_lastk+1	; as 8-bit code will just check MSB!
