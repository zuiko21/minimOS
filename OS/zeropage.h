; minimOS 0.5a3 zero-page system variables
; (c) 2012-2015 Carlos J. Santisteban
; last modified 20150619-1315

.zero

; user space
* = 0
reserved	.word	0	; reserved for 6510, free for user otherwise -- but NOT saved via _software_ as multitasking context
z_used		.byt	0	; user-reserved space in ZP, not really used with _hardware_ multitasking
-user:
-user_zp:
uz						; user context starts here, $03...$E3 newname 20150128,0206

; reserved for kernel functions
* = $E4					; new address 130603, hope it stays forever! 4 more bytes 150122
locals		.dsb	12	; variables for kernel functions @ $E4, new name 150122

local1	= locals		; new aliases for easy porting, new 20150619
locpt1	= local1
local2	= locals + 4
locpt2	= local2
local3	= locals + 8
locpt3	= local3

; kernel parameters
-z10L:
-z10W:
-z10:
zaddr3:					; new alias 20150615 for Ax registers on 680x0!
zpar3		.dsb	4	; up to 4 bytes, including older names @ $F0

-z6L:
-z6W:
-z6:
zaddr2:					; new alias 20150615 for Ax registers on 680x0!
zpar2		.dsb	4	; all @ $F4

-z2L:
-z2W:
-z2:
zaddr:					; new alias 20150615 for Ax registers on 680x0!
zpar		.dsb	4	; all @ $F8

; reserved for system use
-sysvec:
sysptr		.word	0	; ZP pointer for interrupts only @ $FC
-sysvar:
systmp		.byt	0	; temporary storage for interrupts only @ $FE
sys_sp		.byt	0	; stack pointer for context switch @ $FF
