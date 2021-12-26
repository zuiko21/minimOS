; minimOS 0.6.1a2 zero-page system variables
; (c) 2012-2021 Carlos J. Santisteban
; last modified 20211227-0003

.zero
* = 0

; ** default I/O devices (except for C64) **
#ifndef	CBM64
; these will serve as GLOBAL default devices on LOWRAM systems
std_in		.byt	0	; default parent input device (NOT for 6510)
stdout		.byt	0	; default parent outout device (NOT for 6510)
#else
res6510:	.word	0	; reserved for 6510
#endif

; ** measure of used ZP space **
z_used		.byt	0	; user-reserved space in ZP, also available zeropage space at app startup

; ** user space **
user:user_zp:			; older labels for compatibility
uz						; user context starts here, $03...$E3

; ** Commodore 64 places default I/O devices here **
#ifdef	CBM64
* = $E0					; just before local variables...and the new NMOS macro, see definition below
std_in		.byt	0	; default parent input device (for 6510)
stdout		.byt	0	; default parent outout device (for 6510)
-nmos_ii	.word	0	; already defined for new NMOS macro
#endif

; ******************************************
; ** local variables for kernel functions **
; ******************************************
* = $E4								; local variables standard start address
locals:								; old label for compatibility

; TO DO TO DO ** should add somewhere a pointer for execution parameters/registers **

; *** include aliases here for local1/locpt1 ***
dr_aut: ma_ix: iol_dev:				; 8 bit (mm_sig seems of no use!)
tmp_ktab: rl_mask:					; 16 bit (v_src seems of no use!)

local1: locpt1	.dsb	4			; variables for kernel functions @ $E4

st_pg	= dr_aut					; 8b for firmware Fletcher-16
af_pg	= dr_aut+1
skipg	= dr_aut+2
dq_off	= dr_aut+1					; 8b
dq_ptr	= dr_aut+2					; 16b
cio_pt	= dr_aut+2					; 16b for 6502-firmware CONIO
cio_src	= dr_aut
; **********************************************

; *** include aliases here for local2/locpt2 ***
ma_lim: cio_of:						; 8 bit
pfa_ptr: un_ptch: exec_p:			; 16 bit (is v_dest of any use?)
bn_tab:								; 16/24 bit ***parameter***

local2: locpt2	.dsb	4			; variables for kernel functions @ $E8

f16sum	= exec_p					; 8b for firmware Fletcher-16
f16chk	= exec_p+1
rl_dev	= pfa_ptr+2					; 8b
dr_id	= rl_dev					; 8b
; dr_iid no longer used
; **********************************************

; *** include aliases here for local3/locpt3 ***
rl_cur: exe_sp:						; 8 bit
dte_ptr: tmptr:						; 16 bit
rh_scan: 							; 16/24 bit
sv_tab:								; 16/24 bit ***parameter***
; ex_wr no longer used

local3: locpt3	.dsb	4			; variables for kernel functions @ $EC
; **********************************************

; ***********************
; ** kernel parameters **
; ***********************

; *** include aliases here for zpar3/zaddr3 ***
b_sig:								; 8 bit
bl_ptr:								; 16/24 bit ptr
ex_pt:								; 16/24 bit ptr
ex_tab:								; 16/24 bit (pointer to code relocation table)

z10:z10W:z10L:						; old labels for compatibility
zpar3: zaddr3	.dsb	4			; up to 4 bytes, including older names @ $F0

k_ram	= b_sig+1					; 8b, Kernel RAM pages (0 = 128 byte system) changed for virtua6502 compatibility
b_ram	= b_sig+3					; 8b, Banks of "high" memory (65816 only)
da_ptr	= b_sig+2					; 16b, had conflict within LOWRAM I/O!
rle_src	= ex_pt						; 16b, FW RLE decoder origin
; *********************************************

; *** include aliases here for zpar2/zaddr2 ***
def_io: irq_hz: kerntab:			; 16 bit
ma_pt: str_pt:						; 16/24 bit pointers
ex_rlc:								; 16/24 bit ptr, base address for relocation

z6:z6W:z6L:							; old labels for compatibility
zpar2: zaddr2	.dsb	4			; up to 4 bytes, including older names @ $F4

bl_siz	= str_pt+2					; 16b *** was here
bnk_rl	= ex_rlc+2					; 8b, bank for relocation, part of the full address
rle_ptr	= ma_pt						; 16b, FW RLE decoder destination 
; *********************************************

; *** include aliases here for zpar/zaddr ***
io_c:  cpu_ll:						; 8 bit
sv_rlc:								; 16 bit pointer (sysvars relocation)
ma_rs:								; 16/24 bit
w_rect:	up_ticks:					; 32 bit

z2:z2W:z2L:							; old labels for compatibility
zpar: zaddr		.dsb	4			; up to 4 bytes, including older names @ $F8

c_speed		= cpu_ll+1				; 16b ***might recheck alignment***
up_sec		= up_ticks+1			; 24b, new source-compatible format
ma_align	= ma_rs+3				; 8b, moved for virtua6502 compatibility
ln_siz		= io_c+3				; 8b, maximum READLN input! moved for LOWRAM eeeeeeeeeeeek

; *******************************************

; ***********************************************
; ** reserved for system use during interrupts **
; ***********************************************

sysptr:sysvec	.word	0	; ZP pointer for interrupts only @ $FC
systmp:sysvar	.byt	0	; temporary storage for interrupts only @ $FE
sys_sp			.byt	0	; stack pointer for context switch @ $FF
