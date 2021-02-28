; variables for PacMan
; (c) 2021 Carlos J. Santisteban
; last modified 20210228-1339

; **************************
; *** zeropage variables ***
; **************************

	.zero

	* = 3					; minimOS-savvy, although will be a stand-alone game

; *** these not necessarily in ZP, but nice anyway for performance reasons ***
pac_x	.byt	0			; player coordinates (in pixels)
pac_y	.byt	0
pac_dir	.byt	0			; player direction is 0=right, 1=down, 2=left, 3=up
ghost_x	.dsb	4, 0		; ghost coordinates, array for 4 ghosts
ghost_y	.dsb	4, 0
ghost_d	.dsb	4, 0		; ditto for directions
sel_gh	.byt	0			; temporarily selected ghost (index for arrays above)

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
