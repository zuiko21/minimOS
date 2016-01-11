; minimOS 0.4rc1 basic monitor, SDd 65C02
; (c) 2013 Carlos J. Santistenban
; last modified 2013-05-21 (extracted from main source)

	LDY default_out	; default device, should be LED keypad
	_KERNEL(_cin)	; get character
	BCS shell		; no key was pressed
	_KERNEL(_cout)	; output it
	_BRA shell		; repeat forever!
