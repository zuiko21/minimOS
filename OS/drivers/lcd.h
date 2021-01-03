; minimOS driver for Hitachi-compatible LCD
; variables for v0.6
; (c) 2018-2021 Carlos J. Santisteban, just in case.
; last modified 20180801-2008

lcd_x:		.byt	0	; current column
lcd_y:		.byt	0	; current row
l_buff		.dsb	20, 0	; buffer for scrolling (one line)

; * these are only needed for international support *
nx_sub:		.byt	0	; next user character to be redefined (0-7)
cg_sub:		.dsb	8, 0	; glyphs assigned to user-defined
lc_tmp:		.byt	0	; temporary use
