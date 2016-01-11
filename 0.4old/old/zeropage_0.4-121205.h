; minimOS 0.4a2 zero-page system variables - SDx, 6502
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.05

.zero

; user space
* = 0

r6510		.word	0	; reserved for 6510
zp_used	.byt	0	; user-reserved space in ZP
user		.byt	0	; user space starts here... 

; kernel parameters
* = $EC

z10L		.word	0	; long word
z10W		.byt	0	; word (together with next byte)
z10		.byt	0	; byte
z6L		.word	0	; same as previous three...
z6W		.byt	0
z6		.byt	0
z2L		.word	0
z2W		.byt	0
z2		.byt	0
sysvec	.word	0	; ZP pointer for interrupts etc
sysvar	.byt	0	; variable for interrupts etc
sys_sp	.byt	0	; stack pointer
signature	.asc	"mOS*"	; process' short name

