; minimOS driver for VIA-connected VDU
; variables for v0.6
; (c) 2017-2021 Carlos J. Santiateban, just in case.
; last modified 20170926-1715

vdu_xor		.byt	0		; mask to be EORed with glyph data
vdu_sch		.word	0		; limit address for scroll triggering
vdu_ba		.word	0		; CRTC start address, little-endian
vdu_cur		.word	0		; current position, little-endian

