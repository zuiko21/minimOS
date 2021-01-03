; variables for simple ASCII keyboard driver
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20180825-1335

ak_get	.byt	0		; single-char buffer
ak_ddra	.byt	0		; old config
ak_rmod	.byt	0		; raw and coocked modifier combo
ak_cmod	.byt	0
ak_tof	.byt	0		; tabke offset from modifiers
ak_scod	.byt	0		; last scancode
