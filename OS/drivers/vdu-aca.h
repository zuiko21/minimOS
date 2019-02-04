; minimOS driver for Acapulco built-in VDU
; variables for v0.6
; last modified 20190204

va_xor		.byt	0		; mask to be EORed with glyph data
va_sch		.word	0		; limit address for scroll triggering
va_ba		.word	0		; CRTC start address, little-endian
va_cur		.word	0		; current position, little-endian

