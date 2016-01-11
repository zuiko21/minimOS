; minimOS 0.4b2 65(C)51 driver headers, 6502 SDx
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.14

ser_cont	.byt	0	; number of characters stored in buffer
ser_size	.byt	0	; max buffer size
ser_read	.byt	0	; queue output pointer
ser_write	.byt	0	; queue input pointer
ser_buf		.dsb	16, 0	; the serial buffer itself

