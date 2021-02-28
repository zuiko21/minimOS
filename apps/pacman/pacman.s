; PacMan for Tommy2 breadboard computer!
; hopefully adaptable to other 6502 devices
; (c) 2021 Carlos J. Santisteban
; last modified 20210228-1635

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

; perhaps is time to init data...

	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots)
	JSR positions			; reset initial positions
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
level:


; create next level
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots)
	JSR positions			; reset initial positions
; some delay is in order
	JMP level				; and begin new level (without music)

; ***************************
; ***************************
; *** supporting routines ***
; ***************************
; ***************************

; preload map with initial state
; will just copy 1Kbyte, don't bother with individual coordinates (10.5 ms)
newmap:
	LDX #0
nm_loop:
		LDA i_map, X		; get initial data
		STA d_map, X		; copy into RAM
		LDA i_map+256, X	; ditto for remaining pages
		STA i_map+256, X
		LDA i_map+512, X
		STA i_map+512, X
		LDA i_map+768, X
		STA i_map+768, X
		INX
		BNE nm_loop
	RTS

; copy the intial screen to VRAM *and* the 'clean' buffer (about 62 ms @ 1 MHz w/IO, or 45 ms direct)
screen:
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
; now place dots according to current map *** TBD
	RTS

; reset initial positions
positions:
	LDX #15					; number of bytes to be copied
ip_loop:
		LDA init_p-1, X		; get data from tables, note offsets
		STA sprite_x-1, X	; into ZP variables
		DEX
		BNE ip_loop
	RTS

; ****************************
; ****************************
; *** *** diverse data *** ***
; ****************************
; ****************************

; initial positions (note order is pac_x, pac_y, pac_dir and the respective arrays with ghost # as index
; ghost arrays (1...4) are blinky, pinky, inky and clyde, with pacman first (index 0)
; blinky is outside the base at startup
; note horizontal 2-px offset to make maze into 4-px boundaries at least
; vertical movements of ghosts inside the base should be ad hoc
init_p:
	.byt	54, 54, 54, 46, 62	; sprites initial X (2px offset, note "wrong" intial values)
	.byt	90, 42, 54, 54, 54	; sprites initial Y
	.byt	 2,  2,  3,  3,  3	; sprites initial direction
	.byt	 0,  0,  0,  0,  0	; ghosts initial state (nonsense for pacman)

; valid X values in current system (+2 offset)
; 2, 10, 22, 34, 46, (52 the base), 58, 70, 82, 94, 102
; which +2 become
; 4, 12, 24, 36, 48, (54), 60, 72, 84, 96, 104
; which fit into these (half)byte offsets
; 0.5, 1.5, 3, 4.5, 6, (6.75), 7.5, 9, 10.5, 12, 13
; since the base exit is for rising ghosts only, it might be an special case
; but some ghosts inside the base jump at X=44+2 and X=60+2 (5.75 & 7.75)

; not sure if i will use an offset table for the map

; initial map status
i_map:
#include "map.s"

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
