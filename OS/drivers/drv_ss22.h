; SS-22 driver variables for minimOS
; v0.5a1
; (c) 2012-2015 Carlos J. Santisteban
; last modified 20150212-1211

ss_speed	.byt	0	; speed code for reception
ss_stat		.byt	0	; flags for asynchronous operation, new 20150212
ss_cont		.byt	0	; number of characters stored in buffer
ss_read		.byt	0	; queue output pointer
ss_write	.byt	0	; queue input pointer
ss_buf		.dsb	16, 0	; the buffer itself

