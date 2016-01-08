; minimOS 0.4b3 zero-page system variables - SDx, 6502
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.05.04

.zero

; user space
* = 0

reserved	.word	0	; reserved for 6510
z_used		.byt	0	; user-reserved space in ZP, new name 130504
user:				; user space starts here... 

; kernel parameters
* = $EA				; new address! 130504

z10L:
z10W:
z10		.dsb	4	; up to 4 bytes, including older z10L and z10W
z6L:
z6W:
z6		.dsb	4
z2L:
z2W:
z2		.dsb	4

; reserved for system use
sysptr		.word	0	; ZP pointer for kernel functions, new 130504
sysvec		.word	0	; ZP pointer for interrupts only
sysvar		.byt	0	; variable for interrupts only
sys_sp		.byt	0	; stack pointer for context switch
signature	.asc	"mOS*"	; process' short name
