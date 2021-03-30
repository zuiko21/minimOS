; variables for PacMan
; (c) 2021 Carlos J. Santisteban
; last modified 20210330-1913

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
sp_stat		.dsb	5, 0	; sprite status is 0=scatter, 2=chase, 4=frightened, 6=inverse (frightened) *new*, 8=eaten (makes no sense for pacman), 10=invisible, 12=disabled *** note new values
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
tmp_arr:
dmask		.dsb	16, 0	; 16-byte array with dot masks, also temporary space

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
org_b	.dsb	2048, 0		; 'clean' screen buffer at $800, which is page-aligned with the VRAM ($7800 in Tommy2)

; ********************************
; *** magic number definitions ***
; ********************************

; directions
#define	RIGHT	0
#define	DOWN	2
#define	LEFT	4
#define	UP		6

; status *note new values
#define	WAIT	0
#define	GROW	2
#define	SCATTER	4
#define	CHASE	6
#define	FRIGHT	8
#define	FLASH	10
#define	EATEN	12
#define	CLEAR	14
#define	DISABLE	16


