; minimOS 0.5.1rc1 zero-page system variables
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170301-1031

.zero
* = 0

; ** default I/O devices (except for C64) **
#ifndef	CBM64
std_in		.byt	0		; default parent input device (NOT for 6510)
stdout		.byt	0		; default parent outout device (NOT for 6510)
#else
res6510:	.word	0		; reserved for 6510
#endif

; ** measure of used ZP space **
z_used		.byt	0		; user-reserved space in ZP, also available zeropage space at app startup

; ** user space **
user:user_zp:				; older labels for compatibility
uz							; user context starts here, $03...$E3

; ** Commodore 64 places default I/O devices here **
#ifdef	CBM64
* = $E2						; just before local variables, see definition below
std_in		.byt	0		; default parent input device (for 6510)
stdout		.byt	0		; default parent outout device (for 6510)
#endif

; ******************************************
; ** local variables for kernel functions **
; ******************************************
* = $E4						; local variables standard start address
locals:						; old label for compatibility

; TO DO TO DO ** should add somewhere a pointer for execution parameters/registers **

; *** include aliases here for local1/locpt1 ***
dr_aut: ma_ix: mm_sig: rls_pid: iol_dev:
local1: locpt1	.dsb	4	; variables for kernel functions @ $E4

; *** include aliases here for local2/locpt2 ***
da_ptr: exec_p: rl_dev: ma_lim:
local2: locpt2	.dsb	4	; variables for kernel functions @ $E8

; *** include aliases here for local3/locpt3 ***
exe_sp: rh_scan: rl_cur:
local3: locpt3	.dsb	4	; variables for kernel functions @ $EC

; ***********************
; ** kernel parameters **
; ***********************

; *** include aliases here for zpar3/zaddr3 ***
b_sig: kerntab: ln_siz:
ex_pt: ma_rs:				; mandatory 24-bit size

z10:z10W:z10L:				; old labels for compatibility
zpar3: zaddr3	.dsb	4	; up to 4 bytes, including older names @ $F0

; *** include aliases here for zpar2/zaddr2 ***
up_ticks: def_io:
ma_pt: str_pt:				; mandatory 24-bit size

z6:z6W:z6L:					; old labels for compatibility
zpar2: zaddr2	.dsb	4	; up to 4 bytes, including older names @ $F4

; *** include aliases here for zpar/zaddr ***
io_c: ma_align: cpu_ll:
up_sec: w_rect:				; 32-bit

z2:z2W:z2L:					; old labels for compatibility
zpar: zaddr		.dsb	4	; up to 4 bytes, including older names @ $F8

; ***********************************************
; ** reserved for system use during interrupts **
; ***********************************************

sysptr:sysvec	.word	0	; ZP pointer for interrupts only @ $FC
systmp:sysvar	.byt	0	; temporary storage for interrupts only @ $FE
sys_sp			.byt	0	; stack pointer for context switch @ $FF
