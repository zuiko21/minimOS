; minimOS driver for Hitachi-compatible LCD
; variables for v0.6
; last modified 20180801-1943

lcd_x:		.byt	0	; current column
lcd_y:		.byt	0	; current row

; * these are only needed for international support *
nx_sub:		.byt	0	; next user character to be redefined (0-7)
cg_sub:		.ds	8	; glyphs assigned to user-defined
lc_tmp:		.byt	0	; temporary use
