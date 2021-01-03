; minimOS driver for Acapulco built-in VDU
; variables for v0.6
; (c) 2019-2021 Carlos J. Santisteban, just in case
; last modified 20200117-1434

; surely needed variables
; LOCAL data if using windows
va_xor		.byt	0		; mask to be EORed with glyph data
va_y		.byt	0		; current row
va_x		.byt	0		; current column
va_attr		.byt	0		; current attributes, %ppppiiii
va_col		.byt	0		; flag 0=normal, 16=binary mode, 18=wait for ink, 20=wait for paper, 23=wait for Y, 24=wait for X

; some variables for convenience
; perhaps local?
va_wdth		.byt	0		; copy number of columns here, may remove widths array too!
va_hght		.byt	0		; ditto for number of rows

; new font RAM pointer, not sure if local or global
va_font		.word	0

; newer variables for hardware scroll
; GLOBAL data
va_bi		.byt	0		; first element on circular pointer array
va_lpl		.dsb	30, 0	; LSB of line pointers
va_lph		.dsb	30, 0	; MSB of line pointers

; *** older variables with probably no more use ***
va_sch		.word	0		; limit address for scroll triggering
va_ba		.word	0		; CRTC start address, little-endian
va_cur		.word	0		; cursor position, little-endian
