; variables for 4bpp PacMan (Durango-X)
; (c) 2021-2023 Carlos J. Santisteban
; last modified 20230807-1158 

; **************************
; *** zeropage variables ***
; **************************

; minimOS-savvy, although will be a stand-alone game

; *** these not necessarily in ZP, but nice anyway for performance reasons ***
; note new order, where pacman is just a sprite like the ghosts
sprite_x	= 3				; sprite coordinates (in pixels), array for pacman [0] + ghosts [1...4]
sprite_y	= sprite_x + 5
sp_dir		= sprite_y + 5	; sprite direction is 0=right, 2=down, 4=left, 6=up *renumbered*
sp_stat		= sp_dir + 5	; sprite status, see below
sp_timer	= sp_stat + 5	; timer for next movement of every sprite
sp_speed	= sp_speed + 5	; increment for each timer
; should add some timers for scatter/chase modes
temp:
sel_gh		= sp_speed + 5	; temporarily selected ghost (index for arrays above), also other temporary use
temp		= sel_gh
score		= sel_gh + 1	; score in BCD (a tenth of the original score, thus up to 99990 in the arcade)
goal		= score + 2		; desired goal for extra life, every 1000 points (MSB-only is $10 increments -- in BCD!) *new* 
lives		= goal + 1		; remaining lives
level		= lives + 1		; game level
; will need some timers for mode change
dots		= level + 1		; remaining dots
draw_x		= dots + 1		; temporary copy of arrays at one index (and other temporary use)
cur			= draw_x
draw_y		= draw_x + 1
ds_stat		= draw_y + 1
jiffy		= ds_stat + 1	; 24-bit jiffy counter, about 19 hours
stick		= jiffy + 3		; read value from 'joystick', every ISR
stkb_tab	= stick + 1		; NEW pointer to stick or keyboard conversion table
seed		= stkb_tab + 2	; seed value for PRNG
; *** *** *** must check all of these TBD *** *** *** TBD
mul_tmp		= seed + 2		; formerly tmp_arr
tmp_arr		= mul_tmp
dmask:		= mul_tmp		; 16-byte array with dot masks, also temporary space
hb_flag		= mul_tmp + 1	; half-byte indicator (formerly tmp_arr+1)
pre_pt		= hb_flag + 1	; temporary dest_pt creation (formerly tmp_arr+2)
des_dir		= pre_pt + 2	; desired direction (formerly tmp_arr+4)
vh_mask		= des_dir + 1	; direction mask to allow/disable axis changes
cur_y		= vh_mask + 1	; current Y index for screen (formerly as cur)
s_rot		= cur_y + 1		; rotated animation sprite (formerly cur...cur+1)
swp_ct		= s_rot + 2		; sweep sound counter (formerly temp)
sqk_par		= swp_ct + 1	; squeak parametrer (formerly from cur, also using swp_ct instrad of temp)
anim_pt		= sqk_par + 3	; frame counter (formerly temp)
alt_msb		= anim_pt + 1	; formerly tmp_arr+15 (actually used?)
bp_dly		= alt_msb		; new delay storage for 1.536 MHz beep

;		.dsb	16, 0	; 16-byte array with dot masks, also temporary space

; *** these MUST reside in zeropage ***
map_pt		= alt_msb + 1	; pointer to descriptor map
spr_pt		= map_pt + 2	; pointer to sprite entry
org_pt		= spr_pt + 2	; pointer to 'clean', sprite-less screen
dest_pt		= org_pt + 2	; VRAM pointer *** NOT used if IOSCREEN ***

; ***************************
; *** big data structures ***
; ***************************


;	* = $600				; more-or-less minimOS-savvy

d_map		= $600			; descriptor map (496 bytes actually needed, but rounded to 32x31=992), d7=wall, d6=dot, d5=pill
org_b		= d_map + 512	; 'clean' 8 KiB screen buffer at $800-$27FF, which is page-aligned with the VRAM ($6000 in Durango-X)

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
