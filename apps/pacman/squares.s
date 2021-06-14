; squares table
; separate LO and HI bytes
; intended for Pacman, only up to 28 needed!
; ...but doing up to 31, anyway

; old format, LSB.8, then MSB.2
; * LSBs of squares table *
;sq_lo:
;	.byt	0,	1,	4,	9,	16,	25,	36,	49,	64,	81,100,121,144,169,196,225
;	.byt	0,	33,	68,105,144,185,228,	17,	64,113,164,217,	16,	73,132,193

;sq_hi:
;	.dsb	16,	0			; 0...15 squared are single-byte values
;	.byt	1,	1,	1,	1,	1,	1,	1,	2,	2,	2,	2,	2,	3,	3,	3,	3

; new format, just MSB.8, no need for LSB as is either 0 (even) or 64 (odd)
; actually the square divided by 4!
; this is faster, just compare MSBs and, if equal, check LSB as well (simply take account of odd numbers)
sq_hi:
	.byt	0,	0,	1,	2,	4,	6,	9,	12,	16,	20,	25,	30,	36,	42,	49,	56
	.byt	64,	72,	81,	90,100,110,121,132,144,156,169,182,196,210,225,240
