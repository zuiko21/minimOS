; PacMan for Tommy2 breadboard computer!
; hopefully adaptable to other 6502 devices
; (c) 2021 Carlos J. Santisteban
; last modified 20210228-2001

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
	INX						; gets a zero
	STX score				; reset score
	STX score+1
	LDA #5					; initial lives
	STA lives

; initial screen setup, will be done every level as well
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots)
	JSR positions			; reset initial positions
; now coordinates are set, draw all ghosts and pacman on screen... *** TBD

; **********************************************************
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
; **********************************************************
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

; *** draw one sprite... ***
draw:
	LDX draw_d				; check direction
	JMP (sp_dir, X)			; *** CMOS only *** execute appropriate code
sp_dir:
	.word	sd_right		; table of pointers for sprite drawing routines
	.word	sd_down
	.word	sd_left
	.word	sd_up

; sample routine for sprite drawing, towards right ***
sd_right:
	LDY draw_x
	INY						; try one pixel to the right
	TYA
	LDX draw_y
	JSR chk_map				; check status of suggested tile
	BMI sr_abort
		;***check dot/pill (perhaps in chk_map)
		INC draw_x			; one pixel to the right
		LDA draw_x
		AND #7				; bit within byte
		BNE nowrap
; perhaps could clear here the leftmost column
			LDY org_pt		; if wrapped, advance one byte
			INY
			STY org_pt
			STY dest_pt
			BNE sr_nb		; page boundary crossing
				INC org_pt+1
				INC dest_pt+1
sr_nb:
#ifdef	IOSCREEN
		LDY dest_pt+1		; this needs to be ready always
		STY $8000
#endif
		ASL					; each pixel displacement takes 16 bytes of sprite file
		ASL
		ASL
		ASL
		CLC
		ADC spr_pt			; add to selected sprite file base address
		STA spr_pt
		BCC sr_now			; check for wrapping in sprite file
			INC spr_pt+1
sr_now:
		LDY #0				; reset sprite byte counter
sr_loop:
			LDA (org_pt), Y		; get clean data
			ORA (spr_pt), Y		; put sprite data on it
			STA (dest_pt), Y	; and place it on screen
#ifdef	IOSCREEN
			LDX dest_pt			; eeeeeeeek must get this pointer
			STX $8001			; latch low address, high byte was already done
			STA $8003			; copy data on screen!
#endif
			INY					; advance to adjacent byte in both sprite and screen
			LDA (org_pt), Y		; ditto with this second byte, get clean data
			ORA (spr_pt), Y		; put sprite data on it
			STA (dest_pt), Y	; and place it on screen
#ifdef	IOSCREEN
			LDX dest_pt			; eeeeeeeek must get this pointer
			STX $8001			; latch low address, high byte was already done
			STA $8003			; copy data on screen!
#endif
			INY					; prepare for next entry
			LDA org_pt			; advance screen pointers... backing off a bit as the index increases!
			CLC
			ADC #14				; must subtract the two processed entries on sprite file
			STA org_pt
			STA dest_pt			; VRAM pointer too
			BCC sr_nw
				INC org_pt+1	; page wrapping
				INC dest_pt+1
#ifdef	IOSCREEN
				LDX dest_pt+1
				STX $8000
#endif
			CPY #16				; until sprite file is done
			BNE sr_loop
sr_abort:
	RTS
; *** remaining sprite drawing functions TBD ***
sd_down:
	LDA draw_x
	LDX draw_y
	INX						; try one pixel down
	JSR chk_map				; check status of suggested tile
	BMI sd_abort

sd_abort:
	RTS

sd_left:
	LDY draw_x
	DEY						; try one pixel to the left
	TYA
	LDX draw_y
	JSR chk_map				; check status of suggested tile
	BMI sl_abort

sl_abort:
	RTS

sd_up:
	LDA draw_x
	LDX draw_y
	DEX						; try one pixel up
	JSR chk_map				; check status of suggested tile
	BMI sr_abort

sr_abort:
	RTS

; compute map data from pixel coordinates
chk_map:
; input is A=suggested draw_x, X=suggested draw_y
	LSR
	LSR
	TAY						; Y=map column (one each 4 pixels)
	TXA						; this gets suggesteddraw_y
	LSR						; will get map row from A (one each 4 pixels)
	LSR
	STZ map_pt				; clear temporary variable *** CMOS ***
	LSR						; each y advances 32 bytes in table, thus divide MSB by 8 (256/8=32)
	ROR map_pt
	LSR
	ROR map_pt
	LSR
	ROR map_pt				; this is the LSB
	STA map_pt+1			; save this MSB
	LDA #<d_map				; add LSB to offset.low
	ADC map_pt				; C known to be clear (ROR of a reset value)
	STA map_pt
	LDA #>d_map				; MSB too
	ADC map_pt+1
	STA map_pt+1			; pointer is ready
	LDA (map_pt), Y			; map entry for that position

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
	.byt	92, 44, 56, 56, 56	; sprites initial Y (new 2px offset, not much of a problem)
	.byt	 4,  4,  6,  6,  6	; sprites initial direction
	.byt	 0,  0,  0,  0,  0	; ghosts initial state (nonsense for pacman)

; valid X values in current system (+2 offset)
; 4, 12, 24, 36, 48, (54 for base), 60, 72, 84, 96, 104
; which fit into these (half)byte offsets
; 0.5, 1.5, 3, 4.5, 6, (6.75), 7.5, 9, 10.5, 12, 13
; since the base exit is for rising ghosts only, it might be an special case
; but some ghosts inside the base jump at X=46 and X=62 (5.75 & 7.75)

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
