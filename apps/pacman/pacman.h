; variables for PacMan
; (c) 2021 Carlos J. Santisteban
; last modified 20210228-1751

; **************************
; *** zeropage variables ***
; **************************

	.zero

	* = 3					; minimOS-savvy, although will be a stand-alone game

; *** these not necessarily in ZP, but nice anyway for performance reasons ***
; note new order, where pacman is just a srpite like the ghosts
sprite_x	.dsb	5, 0	; sprite coordinates (in pixels), array for pacman [0] + ghosts [1...4]
sprite_y	.dsb	5, 0
sprite_d	.dsb	5, 0	; sprite direction is 0=right, 1=down, 2=left, 3=up
sprite_s	.dsb	5, 0	; sprite status is 0=scatter, 1=chase, 2=frightened, 3=eaten (makes no sense for pacman)
sel_gh		.byt	0		; temporarily selected ghost (index for arrays above), also temporary use
score		.word	0		; score (a tenth of the original score, thus up to 655350 in the arcade)
lives		.byt	0		; remaining lives
draw_x		.byt	0		; temporary copy of arrays at one index
draw_y		.byt	0
draw_d		.byt	0
draw_s		.byt	0

; *** these MUST reside in zeropage ***
map_pt	.word	0			; pointer to descriptor map
spr_pt	.word	0			; pointer to sprite enry
org_pt	.word	0			; pointer to 'clean', sprite-less screen
dest_pt	.word	0			; VRAM pointer

; ***************************
; *** big data structures ***
; ***************************

	.bss

	* = $600				; more-or-less minimOS-savvy

d_map	.dsb	1024, 0		; descriptor map (868 bytes actually needed, but rounded to 32x31=992), d7=wall, d6=dot, d5=pill
org_b	.dsb	2048, 0		; 'clean' screen buffer at $A00, which is page-aligned with the VRAM ($7800 in Tommy2)
