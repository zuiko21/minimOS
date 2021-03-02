; squares table
; separate LO and HI bytes
; intended for Pacman, only up to 28 needed!
; ...but doing up to 31, anyway

; * MSBs of squares table *
sq_lo:
	.byt	0,	1,	4,	9,	16,	25,	36,	49,	64,	81,100,121,144,169,196,225
	.byt	0,	33,	68,105,144,185,228,	17,	64,113,164,217,	16,	73,132,193

sq_hi:
	.dsb	16,	0			; 0...15 squared are single-byte values
	.byt	1,	1,	1,	1,	1,	1,	1,	2,	2,	2,	2,	2,	3,	3,	3,	3
