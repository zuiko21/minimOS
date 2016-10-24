; minimOS 0.5.1a6 zero-page system variables
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20161024-1221

.zero

; ** user space **
* = 0

#ifndef	C64
std_in		.byt	0		; default parent input device (NOT for 6510)
stdout		.byt	0		; default parent outout device (NOT for 6510)
#else
res6510:	.word	0		; reserved for 6510
#endif

z_used		.byt	0		; user-reserved space in ZP, also available zeropage space at app startup
user:user_zp:				; older labels for compatibility
uz							; user context starts here, $03...$E3

#ifdef	C64
* = $E2						; just before local variables, see definition below
std_in		.byt	0		; default parent input device (for 6510)
stdout		.byt	0		; default parent outout device (for 6510)
#endif

; ** local variables for kernel functions **
* = $E4						; local variables standard start address

locals:						; old label for compatibility

; *** include aliases here for local1/locpt1 ***
da_ptr: ma_l: mm_sig:
local1: locpt1	.dsb	4	; variables for kernel functions @ $E4

; *** include aliases here for local2/locpt2 ***
str_dev: br_cpu:
local2: locpt2	.dsb	4	; variables for kernel functions @ $E8

; *** include aliases here for local3/locpt3 ***
local3: locpt3	.dsb	4	; variables for kernel functions @ $EC


; ** kernel parameters **
; *** include aliases here for zpar3/zaddr3 ***
b_sig: ex_pt: kerntab:
z10:z10W:z10L:				; old labels for compatibility
zpar3: zaddr3	.dsb	4	; up to 4 bytes, including older names @ $F0

; *** include aliases here for zpar2/zaddr2 ***
ma_pt: up_sec: str_pt: cpu_ll:
z6:z6W:z6L:					; old labels for compatibility
zpar2: zaddr2	.dsb	4	; up to 4 bytes, including older names @ $F4

def_io	= cpu_ll+2			; *** special case ***

; *** include aliases here for zpar/zaddr ***
io_c: ma_rs: w_rect: up_ticks:
z2:z2W:z2L:					; old labels for compatibility
zpar: zaddr		.dsb	4	; up to 4 bytes, including older names @ $F8


; ** reserved for system use during interrupts **

sysptr:sysvec	.word	0	; ZP pointer for interrupts only @ $FC
systmp:sysvar	.byt	0	; temporary storage for interrupts only @ $FE
sys_sp			.byt	0	; stack pointer for context switch @ $FF
