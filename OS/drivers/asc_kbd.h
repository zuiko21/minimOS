; variables for ASCII keyboard driver
; (c) 2018 Carlos J. Santisteban
; last modified 20180819-1549

ak_fi	.byt	0		; FIFO pointers
ak_fo	.byt	0
ak_buff	.dsb	AF_SIZ, 0	; FIFO buffer (16 char)
ak_ddra	.byt	0		; old config
ak_rmod	.byt	0		; raw and coocked modifier combo
ak_cmod	.byt	0
ak_scod	.byt	0		; last scancode
ak_dead	.byt	0		; deadkey mode
ak_del	.byt	0		; repeat variables
ak_vdel	.byt	0
ak_rep	.byt	0
ak_vrep	.byt	0

