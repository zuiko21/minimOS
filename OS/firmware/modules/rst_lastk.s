; firmware module for minimOS·65
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20180320-1001

; reset last installed kernel pointer!
; no interface needed, affects FW vars

#ifndef	LOWRAM
	_STZA fw_lastk+1	; as 8-bit code will just check MSB!
#endif
