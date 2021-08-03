; variables for PacMan
; (c) 2021 Carlos J. Santisteban
; last modified 20210527-1306 

; **************************
; *** zeropage variables ***
; **************************

	.zero

	* = 3					; minimOS-savvy, although will be a stand-alone game

; *** these not necessarily in ZP, but nice anyway for performance reasons ***
; note new order, where pacman is just a srpite like the ghosts
sprite_x	.dsb	5, 0	; sprite coordinates (in pixels), array for pacman [0] + ghosts [1...4]
sprite_y	.dsb	5, 0
sp_dir		.dsb	5, 0	; sprite direction is 0=right, 2=down, 4=left, 6=up *renumbered*
sp_stat		.dsb	5, 0	; sprite status, see below
sp_timer	.dsb	5, 0	; timer for next movement of every sprite
sp_speed	.dsb	5, 0	; increment for each timer
; should add some timers for scatter/chase modes
temp:
sel_gh		.byt	0		; temporarily selected ghost (index for arrays above), also other temporary use
score		.word	0		; score in BCD (a tenth of the original score, thus up to 99990 in the arcade)
goal		.byt	0		; desired goal for extra life, every 1000 points (MSB-only is $10 increments -- in BCD!) *new* 
lives		.byt	0		; remaining lives
level		.byt	0		; game level
; will need some timers for mode change
dots		.byt	0		; remaining dots
cur:
draw_x		.byt	0		; temporary copy of arrays at one index (and other temporary use)
draw_y		.byt	0
ds_stat		.byt	0
jiffy		.dsb	3, 0	; 24-bit jiffy counter, about 19 hours
stick		.byt	0		; read value from 'joystick', every ISR
stkb_tab	.word	0		; NEW pointer to stick or keyboard conversion table
seed		.word	$8988	; seed value for PRNG
tmp_arr:
dmask:						; 16-byte array with dot masks, also temporary space
mul_tmp		.byt	0		; formerly tmp_arr
hb_flag		.byt	0		; half-byte indicator (formerly tmp_arr+1)
pre_pt		.word	0		; temporary dest_pt creation (formerly tmp_arr+2)
des_dir		.byt	0		; desired direction (formerly tmp_arr+4)
vh_mask		.byt	0		; direction mask to allow/disable axis changes
cur_y		.byt	0		; current Y index for screen (formerly as cur)
s_rot		.word	0		; rotated animation sprite (formerly cur...cur+1)
swp_ct		.byt	0		; sweep sound counter (formerly temp)
sqk_par		.dsb	3, 0	; squeak parametrer (formerly from cur, also using swp_ct instrad of temp)
anim_pt		.byt	0		; frame counter (formerly temp)
bp_dly:						; new delay storage for 1.536 MHz beep
alt_msb		.byt	0		; formerly tmp_arr+15 (actually used?)

;		.dsb	16, 0	; 16-byte array with dot masks, also temporary space

; *** these MUST reside in zeropage ***
map_pt	.word	0			; pointer to descriptor map
spr_pt	.word	0			; pointer to sprite entry
org_pt	.word	0			; pointer to 'clean', sprite-less screen
dest_pt	.word	0			; VRAM pointer *** NOT used if IOSCREEN ***

; ***************************
; *** big data structures ***
; ***************************

	.bss

	* = $600				; more-or-less minimOS-savvy

d_map	.dsb	512, 0		; descriptor map (496 bytes actually needed, but rounded to 32x31=992), d7=wall, d6=dot, d5=pill
org_b	.dsb	2048, 0		; 'clean' screen buffer at $800, which is page-aligned with the VRAM ($7800 in picoVDU)

; ********************************
; *** magic number definitions ***
; ********************************

; bytes per line, may change for Durango·SV
#define	LWIDTH	16

; directions
#define	RIGHT	0
#define	DOWN	2
#define	LEFT	4
#define	UP		6
#define	KEEP	8

#define	VNOTH	2
#define REVERSE	4
#define	DIR_PT	6

; joystick bit values
#define	STK_R	1
#define	STK_D	2
#define	STK_L	4
#define	STK_U	8

#define	STK_K	0

; status codes *note new values, most logic order
#define	WAIT	0
#define	GROW	2
#define	SCATTER	4
#define	CHASE	6
#define	CLEAR	8
#define	EATEN	10
#define	FRIGHT	12
#define	FLASH	14
#define	FR_WAIT	16
#define	DISABLE	18
#define	FR_GROW	20
#define	FL_GROW	22

#define	FL_TOG	2

; map flags (as returned by chk_map)
#define	WALL	128
#define	DOT		64
#define	PILL	32
#define	TU_BASE	16

; possible status changes
; WAIT->GROW->SCATTER->CHASE... (switching between SCATTER and CHASE)
; S/C->FRIGHT->FLASH->S/C (FR.-FL. alternate 5 or 3 times, alwasy ending in FLASH)
; FRIGHT/FLASH->EATEN->GROW (being eaten, immediate exit from base)
; WAIT->FR_WAIT->FR_GROW->FL_GROW (rare, especially the latter)
; FLG->FRG->S (probably no time to switch more than once) fl_wait makes little sense

; usual changes are 4<->6, 12<->14 and, rarely, 20<->22, that is xxx*x
; pill does 4/6->12, 01x0->11*0, and sometimes 0->16 or 2->18
; eaten goes 12/14->10, 11x0->1010, then 0010
; initial sequence is 0->2->4 or, rarely, 16...20->22->12/14
; xx000 are invisible, and 10010 as well
