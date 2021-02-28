; PacMan for Tommy2 breadboard computer!
; hopefully adaptable to other 6502 devices
; (c) 2021 Carlos J. Santisteban
; last modified 20210228-1339

; can be assembled from this folder

; variables, esp. zeropage
#include "pacman.h"

; *** constants definitions ***
	vram = $7800			; suitable for Tommy2

; uncomment this if non-direct, IO-based connection is used
#define	IOSCREEN	_IOSCREEN

; *** actual code starts here ***
	.text

	* = $4000				; standard system download address, hopefully will suffice!

; basic 6502 init, as this is a stand-alone game
start:
	SEI
	CLD
	LDX #$FF
	TXS
	STX $FFF0				; turn off Tommy2 display

; must copy the intial screen to VRAM *and* the 'clean' buffer (about 62 ms @ 1 MHz w/IO, or 45 ms direct)
	LDY #<maze				; pointer to fresh maze
	LDA #>maze
	STY spr_pt				; load origin pointer (temporarily)
	STA spr_pt+1
	LDY #<vram				; pointer to VRAM
	LDA #>vram
	STY dest_pt				; load destination pointer
	STA dest_pt+1
#ifdef	IOSCREEN
	STA $8000				; preload page into high-address latch
#endif
;	LDY #<org_b				; pointer to clean screen (Y known to be zero, as both blocks are page-aligned)
	LDA #>org_b
	STY org_pt				; load parallel destination
	STA org_pt+1
sc_loop:
		LDA (spr_pt), Y		; get data... (5)
		STA (org_pt), Y		; ...into buffer... (6)
		STA (dest_pt), Y	; ...and into VRAM (6)
#ifdef	IOSCREEN
		STY $8001			; low-address latch (4)
		STA $8003			; actual data transfer (4)
#endif
		INY					; (2)
		BNE sc_loop			; (usually 3 for 255 times, then 2)
			INC spr_pt+1	; page crossing (5+5+5)
			INC org_pt+1
			INC dest_pt+1	; VRAM is last, as will set N flag when finished!
#ifdef	IOSCREEN
			LDA dest_pt+1	; new page value... (3)
			STA $8000		; ...gets into high-address latch (4)
#endif
		BPL sc_loop			; (usually 3, just 8 times)

; perhaps is time to init data...
	LDX #15					; number of bytes to be copied
id_loop:
		LDA init_p-1, X		; get data from tables, note offsets
		STA pac_x-1, X		; into ZP variables
		DEX
		BNE id_loop

; now coordinates are set, draw all ghosts and pacman on screen... *** TBD

; screen is ready, now play the tune... that started it all!
	STX sel_gh				; reset cursor (temporary use, X known to be zero **** sure? **** at this point)
m_loop:
		LDY sel_gh			; get index
		LDA m_len, Y		; get length from duration array
			BEQ m_end		; length=0 means END of score
		TAX
		LDA m_note, Y		; get note period (10A+20 t) from its array
		BEQ m_rest			; if zero, no sound!
; *** ** beeping routine ** *** inlined
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
m_beep:
			TAY				; determines frequency (2)
			STX $BFF0		; send X's LSB to beeper (4)
rb_zi:
				DEY			; count pulse length (y*2)
				BNE rb_zi	; stay this way for a while (y*3-1)
			DEX				; toggles even/odd number (2)
			BNE m_beep		; new half cycle (3)
		STX $BFF0			; turn off the beeper!
		BEQ m_next			; go for next note
; *** ** rest routine ** *** inlined
; ***     X = length     ***
; ***    t = X 1.28 ms   ***
m_rest:
		TAY					; if period is zero for rests, this resets the counter
r_loop:
			INY
			BNE r_loop		; this will take ~ 1.28 ms
		DEX					; continue
		BNE m_rest
m_next:
		INC sel_gh			; advance cursor to next note
		BNE m_loop
m_end:

; music finished, now start the game!


; ****************************
; ****************************
; *** *** diverse data *** ***
; ****************************
; ****************************

; initial positions (note order is pac_x, pac_y, pac_dir and the respective arrays with ghost # as index
; ghost arrays are blinky, pinky, inky and clyde
; blinky is outside the base at startup
; *** note fucking 2-px offset! will surely make maze into 4-px boundaries at least
init_p:
	.byt	52, 90, 2		; pacman
	.byt	52, 52, 44, 60	; ghosts initial X
	.byt	42, 54, 54, 54	; ghosts initial Y
	.byt	 2,  3,  3,  3	; ghosts initial direction
; not sure if i will use an offset table for the map

; *******************
; *** music score ***
; *******************

; array of lengths (rests are computed like G5?)
m_len:
	.byt	 70,  52, 140,  52, 104,  52,  88,  52, 140, 104, 104, 176, 104
	.byt	 74,  52, 148,  52, 110,  52,  92,  52, 148, 110, 104, 184, 104
	.byt	 70,  52, 140,  52, 104,  52,  88,  52, 140, 104, 104, 176, 104
	.byt	 82,  88,  92,  52,  92,  98, 104,  52, 104, 110, 116,  52, 255, 130,   0	; *** end of score ***

; array of notes (rests are 0)
m_note:
	.byt	190,   0,  94,   0, 126,   0, 150,   0,  94, 126,   0, 150,   0
	.byt	179,   0,  88,   0, 118,   0, 141,   0,  88, 118,   0, 141,   0
	.byt	190,   0,  94,   0, 126,   0, 150,   0,  94, 126,   0, 150,   0
	.byt	159, 150, 141,   0, 141, 133, 126,   0, 126, 118, 112,   0,  94,   0		; no need for extra byte as will be discarded

; ****************
; *** graphics ***
; ****************

; original maze (full 128x128 screen)
maze:

; *** sprites ***
; pacman towards right
s_pac_r:
; pacman downwards *** need new scheme for vertical!
s_pac_d:
; pacman towards left
s_pac_l:
; pacman upwards ***
s_pac_u:
; pacman dies! (animation)
pac_dies:
; ghost towards right
s_gh_r:
; ghost downwards ***
s_gh_d:
; ghost towards left
s_gh_l:
; ghost upwards ***
s_gh_u:
; frightened ghost towards right
s_fg_r:
; frightened ghost downwards ***
s_fg_d:
; frightened ghost towards left
s_fg_l:
; frightened ghost upwards ***
s_fg_u:
