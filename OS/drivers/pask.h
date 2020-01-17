; minimOS driver for PASK keyboard
; variables for v0.6
; (c) 2018-2020 Carlos J. Santisteban, just in case.
; last modified 20200117-1339

#define		AF_SIZ	20
pk_fo:		.byt	0			; buffer output index
pk_fi:		.byt	0			; buffer input index
pk_buff:	.dsb	AF_SIZ, 0	; keyboard buffer, size as defined

