; minimOS 0.5a4 zero-page system variables
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160406-0928

.zero

; ** user space **
* = 0
res6510		.word	0	; reserved for 6510, free for user otherwise -- but NOT saved via _software_ as multitasking context
z_used		.byt	0	; user-reserved space in ZP, not really used with _hardware_ multitasking
user:user_zp:			; older labels for compatibility
uz						; user context starts here, $03...$E3 newname 20150128,0206


; ** local variables for kernel functions **
* = $E4						; new address 130603, hope it stays forever! 4 more bytes 150122
locals:						; old label for compatibility

; *** include aliases here for local1/locpt1 ***
local1:locpt1	.dsb	4	; variables for kernel functions @ $E4, new name 150122, 150619

; *** include aliases here for local2/locpt2 ***
local2:locpt2	.dsb	4	; variables for kernel functions @ $E8, new name 150122, 150619

; *** include aliases here for local3/locpt3 ***
local3:locpt3	.dsb	4	; variables for kernel functions @ $EC, new name 150122, 150619


; ** kernel parameters **
; new standardised aliases for ABI freedom 20160406

z10:z10W:z10L:				; old labels for compatibility, new alias 20150615 for Ax registers on 680x0!
; *** include aliases here for zpar3/zaddr3 ***
zpar3:zaddr3	.dsb	4	; up to 4 bytes, including older names @ $F0

z6:z6W:z6L:					; old labels for compatibility
; *** include aliases here for zpar2/zaddr2 ***
zpar2:zaddr2	.dsb	4	; up to 4 bytes, including older names @ $F4

z2:z2W:z2L:					; old labels for compatibility
; *** include aliases here for zpar3/zaddr3 ***
zpar:zaddr		.dsb	4	; up to 4 bytes, including older names @ $F8


; ** reserved for system use **

sysptr:sysvec	.word	0	; ZP pointer for interrupts only @ $FC
systmp:sysvar	.byt	0	; temporary storage for interrupts only @ $FE
sys_sp			.byt	0	; stack pointer for context switch @ $FF
