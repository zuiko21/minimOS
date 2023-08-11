; PacMan for Durango-X colour computer!
; (c) 2021-2023 Carlos J. Santisteban
; last modified 20230807-1124

; can be assembled from this folder

; uncomment if using PASK standard (ASCII key on port), otherwise is decoding standard matrix
#define	PASK	_PASK

; variables, esp. zeropage
#include "pacman4.h"

; *** addresses definition ***
	fw_isr	= $200			; standard minimOS firmware address
	vram	= $6000			; suitable for Durango-X
	sc_da	= vram + $C72	; address for score display, usually $6C72 (100,49)
	lv_da	= vram + $1275	; address for lives display, usually $7275 (106,73?)

; I/O addresses
	IO8attr	= $DF80			; screen latch high, actually video mode flags
	IO9kbd	= $DF9B			; keyboard input
	IO9pad1	= $DF9C			; gamepad input, also latch signal
	IO9clk	= $DF9D			; gamepad shift clock
	IOAie	= $DFAF			; enable hardware interrupt, note status is controlled via D0
	IOBeep	= $DFB0			; beeper address (latches D0 value)
	LTCdo	= $FFFF			; LTC display port

; *** actual code starts here ***
	.text

	* = $2800				; new download address, just after RAM data structures

; basic 6502 init, as this is a stand-alone game
start:
	SEI
	CLD
	LDX #$FF
	TXS

;	STX LTCdo				; turn off Durango debug display, just in case

	LDA #$39				; colour mode, non-inverted, screen 3, non-grey, also interrupt enable
	STA IO8attr				; Durango-X hardware init
; this value may enable interrupts in any machine
	STA IOAie				; hardware interrupts enabled, not yet in software!
jmp music
; the pseudo-random number generator must have a proper seed...
; ...will time it upon joystick/keyboard selection screen!
; NES Tetris used $8988, but might randomise it with some EOR with zp bytes?
	LDA #$89
	STA seed+1

; system setup
	LDY #<pm_isr			; set interrupt vector
	LDA #>pm_isr
	STY fw_isr				; standard minimOS address
	STA fw_isr+1			; now it's possible to execute CLI for input selection (and randomize)
	CLI						; interrupts won't harm unless sound effects

; perhaps is time to init data...
	INX						; gets a zero (X was known to be $FF)
	STX score				; reset score
	STX score+1
	LDA #5					; initial lives
	STA lives
	LDA #$10				; needs to be 10 in BCD eeeeeeek
	STA goal				; next extra life at 1000 points

; initial screen setup, will be done every level as well
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots), may modify X
; *** ask here for keyboard/joystick selection ***
	LDY #<(p_text+200)		; third chunk (new!) is the joystick/keyboard selection message ** check
	LDA #>(p_text+200)
	JSR l_text
	JSR sel_if				; for the sake of clarity, choose depending on IO9 input, 8=joystick (UP), 13=keyboard (CR)
; *** continue with screen setup ***
	JSR positions			; reset initial positions (and show 'Ready!' message)
	JSR sprites				; draw all ghosts and pacman on screen
music:
; **********************************************************
; screen is ready, now play the tune... that started it all!
	LDX #0					; *** don't know if X is still zero after positions AND drawing sprites
	STX temp				; reset cursor (temporary use)
m_loop:
		LDY temp			; get index
		LDA m_len, Y		; get length from duration array
			BEQ m_end		; length=0 means END of score
		TAX
		LDA m_note, Y		; get note period (10A+20 t) from its array
		BEQ mc_rest			; if zero, no sound!
			JSR m_beep		; play this note (exits with Z)
			BEQ m_next		; go for next note
; *** ** rest routine ** *** inlined
; ***     X = length     ***
; ***    t = X 1.28 ms   ***
mc_rest:
		JSR m_rest
m_next:
		INC temp			; advance cursor to next note
		BNE m_loop
m_end:
; **********************************************************
; **********************************************************
; ***  ***   music finished, now start the game!    ***  ***
; **********************************************************
; **********************************************************

play:
	LDY #<s_clr				; clear area in order to delete 'Ready!' message
	LDA #>s_clr
	JSR l_text
;	CLI						; make sure interrupts are enabled as will be needed for timing

; game engine
	LDX #4					; first of all, preset all timers for instant start
t_pres:
		LDA #1				; immediate movement (placeholder, as some ghosts will appear later)
		STA sp_timer, X		; reset timer
		LDA i_speed, X		; initial speed for that sprite
		STA sp_speed, X
		DEX
		BPL t_pres

; *************************
; *** *** main loop *** ***
; *************************
g_start:
		LDX #0				; displayed sprite counter
g_loop:
			STX sel_gh		; X is selected sprite, must keep this!
			LDA jiffy		; current time
			CMP sp_timer, X	; time to update position?
			BMI g_next		; * might use BNE instead of BMI for testing
				CLC			; prepare next event
				ADC sp_speed, X
				STA sp_timer, X
; ** do something to update coordinates and sp_dir ** X holds sprite number
; might abort loop if death and/or game over
				JSR move	; separated routine for the sake of clarity
				JSR draw	; not worth unifying with move as that has a lot of RTSs
g_next:
			LDX sel_gh		; ** no need for PLX **
			INX				; next sprite
			CPX #5			; all sprites done?
			BNE g_loop
		LDA dots			; all dots done?
		BNE g_start			; repeat loop

g_end:
; *************************************************
; *** if arrived here, level ended successfully ***
; *************************************************
	LDA #100				; two-second delay
	JSR ms20
; worth showing a flashing map (4 times) for a couple of seconds
	LDA #8					; clear inverse video flag, d0-3 is down counter
fl_loop:
		EOR #64				; toggle inverse flag
		STA temp			; store counter and inverse flag
		STA IO8attr			; works on both Durango-X and picoVDU
		LDA #12				; ~quarter second delay
		JSR ms20
		LDA temp			; check counter
		DEC					; CMOS, could be swapped by SEC, SBC #1 as well; or DEC temp, LDA temp instead
		BNE fl_loop

; *************************************
; *** *** restart another level *** ***
; *************************************
	INC level
	JSR newmap				; reset initial map (and dot count)
g_again:
; entry point after losing one life, continue level from current state (but with reset positions)
	JSR screen				; draw initial field (and current dots)
	JSR positions			; reset initial positions (and print 'Ready!')
	JSR sprites				; draw all ghosts and pacman on screen (uses draw, in development)
	LDA #100				; 2-second delay
	JSR ms20
	JMP play				; and begin new level (without music)

; *************************************
; *** *** pacman death sequence *** ***
; *************************************
die:
	JSR death				; create animation and sound
; check for gameover
	LDA lives
	BNE g_again				; continue playing if lives remaining
;	BEQ gameover			; ...or end play otherwise

; ***************************
; *** *** end of game *** *** if lives is 0 after death
; ***************************
gameover:
	LDY #<(p_text+100)		; second chunk is the 'Game Over' message ** check offset
	LDA #>(p_text+100)
	JSR l_text
; shall I wait for some key to start a new game? exit option?
release:
	LDA IO9in

; ***************************
; ***************************
; *** supporting routines ***
; ***************************
; ***************************

; * select between joystick and keyboard *
; sets stkb_tab accordingly, reads from IO9
sel_if:
		LDA IO9in			; get port input
		CMP #8				; is it joystick up?
		BEQ sel_joy
#ifdef	PASK
			CMP #13			; is it keyboard instead? ** only if using PASK standard **
#else
			LDA #$C0		; RETURN key column (scancode $C1)
			STA IO9kbd		; select matrix column
 			LDA IO9kbd		; check keyboard instead
			AND #1			; filter row signal (inverted) ** could use LSR, BCS instead, saving one byte
#endif
		BNE sel_if			; if neither, keep trying ** could check for Escape or joy down for exit **
; if arrived here, keyboard is selected
	LDY dir_tab				; pointer for keyboard tables ** should add extra label for clarity
	LDA dir_tab+1
	BNE sel_ok				; no need for BRA
sel_joy:
		LDY dir_tab+2		; pointer for joystick tables
		LDA dir_tab+3
sel_ok:
	STY stkb_tab			; prepare input pointer
	STA stkb_tab+1
	LDA jiffy				; this will change during selection screen, initial value irrelevant (most likely 0 if memory was tested)
	STA seed				; randomized generator
	RTS

; * 20ms generic delay *
; delay ~20A ms, assuming 1.536 MHz clock! NEW
ms20:
	LDX #11					; computed iterations for a 20ms delay
	LDY #44					; first iteration takes ~0.17 the time, actually ~10.17 iterations
m20d:
;			STY bp_dly		; delay for 1.536 MHz, 4% slower, worth changing initial values ***
			DEY				; inner loop (2y)x
			BNE m20d		; (3y-1)x, total 1279t if in full, ~220 otherwise
		DEX					; outer loop (2x)
		BNE m20d			; (3x-1)
	DEC						; ** CMOS **
		BNE ms20
	RTS						; add 12t from call overhead

; * preload map with initial state *
; will just copy 0.5 Kbyte, don't bother with individual coordinates (5.9 ms)
; don't think it's worth dealing with RLE
; returns X=0, modifies A
newmap:
	LDX #0
nm_loop:
		LDA i_map, X		; get initial data
		STA d_map, X		; copy into RAM
		LDA i_map+256, X	; ditto for remaining pages
		STA d_map+256, X
		INX
		BNE nm_loop
; after resetting the new map, it's time to reset dot counter
	LDA #244				; number of dots (no longer automatic, not really worth it)
	STA dots
	RTS

; * reset initial positions *
; returns X=0, modifies A
positions:
	LDX #19					; 5 sprites x 4 coordinates/stati max index
ip_loop:
		LDA init_p, X		; get data from tables, note offsets
		STA sprite_x, X		; into ZP variables
		DEX
		BPL ip_loop
; I think this should reset counters and timers as well
; lastly, print 'Ready!' message
	LDY #<p_text			; initial patch is 'Ready!' message
	LDA #>p_text
	JMP l_text				; will return

; *****************************************************
; *****************************************************
; *** *** sprite moving routines, the actual AI *** *** supposedly the same between Durango-X and picoVDU
; *****************************************************
; *****************************************************
; X expected to have selected ghost (already stored in sel_gh)
; must change sprite_x[X], sprite_y[X] and/or sp_dir[X], perhaps other parameters too
move:
; note Pacman may reverse movement (left<->right or up<->down) at ANY time!
; check whether pacman or ghost
	TXA						; check sprite, note X is valid
	BNE is_ghost			; pacman only looks for joystick input and map entries... and can move anytime WITHIN THE CURRENT AXIS
; ** Pacman code **
		LDA sprite_x		; check pacman coordinates, as between tiles only reversing is allowed
		ORA sprite_y
		AND #3
		BEQ pac_cross
; between tiles, check joystick and only inversions are recognised
			LDX stick		; check desired movement
			LDA sp_dir		; check pacman axis
			AND #VNOTH
			BEQ pac_hor		; if moving vertically...
				LDY st_vert, X	; ... get possibly updated direction...
				BRA mv_all	; ...and execute it! ** CMOS **
pac_hor:
			LDY st_horz, X	; otherwise is moving horizontally
			BRA mv_all
pac_cross:
; the joystick indicates certain desire to move... will do if map allows it
; say d3=up, d2=left, d1=down and d0=right... at least at the logic level
; note this layout is incompatible with keyboard, even after reversing the patterns
; from the logic point of view, 1+8 feasible movements are...
; 0000=keep dir, 0001=try right, 0011=right or down, 0010=down, 0110=down or left, 0100=left, 1100=left or up, 1000=up, 1001=up or right
; both possible movements are in separate tables, with usual code 0/2/4/6, and 8 for no change/invalid!
; note that no-change means altering coordinates as per sp_dir[X]!
; if one of the directions is the current one, may discard it and take the other one if possible? ***
		LDX stick			; check desired movement
		LDY st_des, X		; first of two tables! highest bit is prioritary, like ghosts
		CPY sp_dir			; is it the current one?
			BEQ mv_alt		; if so, discard it and try alternative, just in case
; *** is it possible to replace the following block by just JSR mv_all? saves 7 bytes ***
;		CPY #KEEP			; no valid direction change?
;		BNE mv_do
;			LDY sp_dir		; keep previous
;mv_do:
;		TYA					; peek expects new direction in A
;		JSR peek			; check whether desired direction is feasible, move if so or return with C set otherwise
		JSR mv_all			; *** try to do movement as in Y, returns with C set if unfeasible ***
; *** end of supposedly replaceable block ***
		BCS p_try
			RTS				; moved successfully
p_try:
		LDX stick			; otherwise recheck desire *** MIGHT change, should read once and save... or not!
mv_alt:
		LDY st_alt, X		; check alternative movement, if possible
; this is where all inter-tile movements are executed, apart from alterantive direction change in crossings
mv_all:
		CPY #KEEP			; no valid direction change?
		BNE alt_do
			LDY sp_dir		; keep previous
alt_do:
		TYA					; as defined by interface
		JMP peek			; will return -- this will IGNORE if second movement is impossible, just leave coordinates as they were
; * ghost move management * the real AI (¡mis cojones!)
is_ghost:
; just for ghosts, if pX or pY MOD 4 (see dir) is zero, may check map and AI to change direction, otherwise continue as indicated by dir
	LDA sp_dir, X			; check direction, X is still valid
	AND #DOWN				; detect vertical movements (2 or 6) trying not to use indirect-indexed, as I prefer to keep X
	BNE m_vert
; some horizontal direction
		LDA sprite_x, X		; current X pos
		AND #3				; MOD 4
		BEQ decide			; may change direction at crossings
			LDA sp_dir, X	; left or right?
			AND #LEFT		; 4=LEFT, 0=RIGHT
			BNE m_left		; if right...
				INC sprite_x, X
				RTS
m_left:
			DEC sprite_x, X	; ...else go to the left
			RTS
m_vert:
; some vertical direction
	LDA sprite_y, X			; current Y pos, X was respected
	AND #3					; MOD 4
	BEQ decide				; may change direction at crossings
		LDA sp_dir, X		; left or right?
		AND #LEFT			; 6->4=UP, 2->0=DOWN
		BNE m_up			; if down...
			INC sprite_y, X
			RTS
m_up:
		DEC sprite_y, X	; ...else go up
		RTS
; if arrived here, X or Y MOD 4 is zero, thus check map and AI
decide:
	LDA sp_stat, X
;	ORA #FL_TOG				; will check for frightened ghosts, flashing or not (FL_TOG seems no longer necessary)
	CMP #FRIGHT				; is it FRIGHT and/or FLASH? (FLASH = FRIGHT | FL_TOG)
	BEQ yes_fr
		CMP #FLASH			; better separate comparisons so A is kept
	BNE not_fr
yes_fr:
		LDA sp_dir, X		; please note that ghosts cannot just turn 180 degrees
		EOR #REVERSE		; this is the opposite direction
		STA vh_mask			; store this forbidden direction
go_rnd:
			JSR rnd			; get random direction!
			AND #DIR_PT		; 0-2-4-6, as DIR_PT is 6
			CMP vh_mask		; not just 180 degree turn?
				BEQ go_rnd
			JSR peek		; check feasibility
				BCS go_rnd	; until a feasible address is decided
			RTS
not_fr:
	CMP #CHASE
	BNE not_ch
; TBD TBD TBD
not_ch:
	CMP #SCATTER
	BNE not_sct
; TBD TBD TBD
not_sct:
; **** TBD ****
	RTS

; *** movement feasibility routine ***
; if desired direction (in A) is feasible, change coordinates as appropriate and clear C, otherwise return with C set
peek:
	STA des_dir				; must save A, using tmp_arr is faster and makes it retrieveable
	LDX sel_gh				; will operate on coordinate arrays, affecting X (replace LDX stick above)
	LDY sprite_y, X			; coordinate Y is easy
	LDA sprite_x, X			; this is X
; original idea, depending on slowly emulated indirect-indexed jump but very fast otherwise!
; not including pointer table (same as both tables above) is 16+10b, 13-16t, or 9 if none! ~14t
; the ADC version, perhaps hard to convert to NMOS, was 13+10b, 27t
#ifndef	NMOS
	LDX des_dir				; (3)
	JMP (pk_mv, X)			; adjust coordinates (6...)
pk_rt:
		INC					; typical code (2+3)
		BNE dir_set
pk_dn:
		INY
		BNE dir_set
pk_lt:
		DEC
		BNE dir_set
pk_up:
		DEY					; no branch in this case (2)
; ...and fall into dir_set, does need TAX
dir_set:
#endif
	TAX						; it is AFTER the JMP version and BEFORE the CMP version, NOT needed in the ADC version (2)
; alternative version, certainly the best suited for NMOS
; this seems to be 27b WITHOUT the 10-byte table and 12/16/22/24/23t, 19.4t (RDLU-)
#ifdef	NMOS
; X has the coordinate already, needs to retrieve direction in A!
; assume RIGHT is zero, otherwise CMP #RIGHT
	LDA des_dir				; eeeeeeek (3)
;	CMP #RIGHT				; assume RIGHT is zero
	BNE pk_nr				; if right... (2/3)
		INX					; ...move... (2/0)
		BNE dir_sug			; ...and check (3/0)
pk_nr:
	CMP #DOWN				; if down... (0/2)
	BNE pk_nd				; (0/2/3)
		INY					; ...move and check (0/5/0)
		BNE dir_sug
pk_nd:
	CMP #LEFT				; if left... (0/0/2)
	BNE pk_nl				; (0/0/2/3)
		DEX					; ...move and check (0/0/5/0)
		BNE dir_sug
pk_nl:
	CMP #UP					; if up... (0/0/0/2)
	BNE dir_sug				; (0/0/0/2/3)
		DEY					; ...move and check (0/0/0/2/0)
dir_sug:
#endif
; *** in any case, X and Y are the coordinates, must check map in case is not feasible (set C) *** TBD
	JSR chk_map				; get A.MSB with tile flags
;	BIT #WALL				; CMOS, in case is needed could be AND plus some later LDA (chk_map)... perhaps best stored elsewhere or, even better, keep WALL at 128!
	BPL dir_ok				; no obstacle (assumes WALL = 128)
; note that ghosts, while in GROW or FL_GROW or FR_GROW can move with negative (d7) as long as they're inside the base (d4)
		AND #TU_BASE		; since D7 was set, this is base
	BNE dir_ok				; acceptable movement... if GROWing
; otherwise there is a wall, thus do not move
		SEC					; report inviable movement
		RTS
dir_ok:
	TXA						; hopefully X was kept as the updated coordinate
	LDX sel_gh				; sprite to be moved
	STA sprite_x, X
	STY sprite_y, X			; hopefully Y was respected too
	LDA des_dir				; stored desired direction
	STA sp_dir, X
	CLC						; update was successful
	RTS

; * compute map data from pixel coordinates * REDONE, yet to be used
chk_map:
; newest interface is X=x, Y=y, returns them unmodified! returns A.MSN
	TXA						; A=·xxxxxoo
	ASL						; forget unused bit A=xxxxxoo0
	STA map_pt				; will be into pointer LSB, M=xxxxxoo0
	TYA						; get Y coordinate A=·yyyyyrr
	LSR						; A=0·yyyyyr
	LSR						; discard raster for tile row  A=00·yyyyy, C=r
	LSR						; shift into X in RAM, A=000·yyyy C=y0
	ROR map_pt				; M=yxxxxxoo
	LSR						; A=0000·yyy, C=y1
	ROR map_pt				; M=yyxxxxxo
	LSR						; A=00000·yy, C=y2
	ROR map_pt				; M=yyyxxxxx
	LSR						; A=000000·y, C=y3
	ROR map_pt				; after this, C indicates left/right tile in byte M=yyyyxxxx, C=x0
	AND #1					; just save remaining MSB.Y, A=0000000y
	ORA #6					; ** valid as long as map is at $600 **, A=0000011y
	STA map_pt+1			; MSB (and whole pointer) is ready, P=0000011y yyyyxxxx, C=x0
	LDA (map_pt)			; *** CMOS *** gets two consecutive tiles, N=d7
	BCC mp_left				; is the right (odd) nibble?
		ASL					; rotate bits towards MSB
		ASL
		ASL
		ASL					; in this case, N=original d3, now d7
mp_left:
	RTS						; in any case, d7-d4 are the flags

; * pseudo-random number generator *
; * ahem, ahem, ahem, ahem ;-) ;-) *
; returns A, seed must be >= 2
; X and Y intact!
rnd:
	LDA seed
	AND #2
	STA temp				; hope this is OK
	LDA seed+1
	AND #2
	EOR temp
	CLC
	BEQ rg_z
		SEC
rg_z:
	ROR seed+1				; is this OK?
	ROR seed
	LDA seed				; returns MSB
	RTS

; ********************************
; ********************************
; *** *** graphic routines *** *** specially made for Durango-X *** TBD TBD
; ********************************
; ********************************

; * copy the intial screen to VRAM *and* the 'clean' buffer, now including dots *
screen:
	LDY #<maze				; pointer to fresh maze (NOT page aligned)
	LDA #>maze
	STY spr_pt				; load origin pointer (temporarily)
	STA spr_pt+1
	LDY #<org_b				; pointer to clean buffer
	LDA #>org_b
	STY org_pt				; load parallel destination
	STA org_pt+1
;	LDY #<vram				; pointer to VRAM (Y known to be zero, as both blocks are page-aligned)
	LDA #>vram
	STY dest_pt				; load destination pointer
	STA dest_pt+1
;	LDY #<d_map				; get map initial pointer, once again page-aligned
	LDA #>d_map
	STY map_pt
	STA map_pt+1
	STY cur_y				; save this index, as it isn't valid everywhere
; now using a compact-map format, two tiles per byte, w0d0p0b0w1d1p1b1, as it makes a lot of sense!
sc_loop:
; check line position within row
		LDA cur_y			; check coordinates
		AND #LWIDTH-1		; filter column (assuming LWIDTH is power of 2)
		TAY					; will be used for the mask array AND map index
		LDA cur_y			; now for the lowest Y-bits
		AND #%00110000		; we only need the lowest 2 bits, assuming LWIDTH = 16
; will place dots at every +2, instead of +3, makes pill placement MUCH easier as no page/tile crossing is done!
; thus, Y MOD 4 TIMES 16 could be 0 (no dots), 16 or 48 (pills only, same mask), or 32 (dots and/or pills)
		BEQ sc_ndot			; no dots on raster 0
; first raster (A=0) goes away
; otherwise put shifted mask for dots, perhaps extended if pills
			CMP #32			; is it the raster for dots?
			BNE sc_cpil		; no, check whether pill
; third raster (A=32) the only one where dots are feasible
sc_sdot:
				LDA (map_pt), Y	; get map data for both tiles!
				AND #%01000100	; filter dot bits
;				LSR				; comment this for dots centered with pills, less offset otherwise
				LSR				; shift them to the rightmost column
				ORA dmask, Y	; combine with possible pills, must be an array of them
; dot auto-count is no more...
				JMP sc_ndot		; in any case, place pattern on screen

sc_cpil:
; I don't think I need to check any other value, it MUST be a pill raster
; but 16 is the first one, thus SET appropriate dmask entry
			CMP #48			; second set of pill pixels?
			BEQ sc_spil		; yes, go set them
; second raster (A=16) may have pills
				LDA (map_pt), Y	; otherwise check whether pills have to be set
				AND #%00100010	; filter pill bits
				BEQ sc_npil	; worth skipping as most tiles will have no pills
					ASL		; eeeeeeek, but pills looked better without it...
					STA temp	; temporary use, better performance than using the mask array
					LSR
					ORA temp
					LSR
					ORA temp	; fill all three pixels
sc_npil:
				STA dmask, Y	; and store it into array
				JMP sc_ndot		; eeeeeeeek²
sc_spil:
; fourth raster (A=48)
; can only advance pointer ONCE per raster!!!!!!!!!!! eeeeeeek
			LDA cur_y		; beginning of line?
			AND #15			; eeeeeeeeek
			BNE sc_rowm		; if not, do NOT increment! eeeeeeeeek
				LDA map_pt	; this is the end of the tile raster, thus advance to next row
				CLC
				ADC #LWIDTH	; will advance map_pt, usually by 16
				STA map_pt
				BCC sc_rowm	; check possible carry
					INC map_pt+1
sc_rowm:
; take the same mask as created two rasters before
			LDA dmask, Y	; take previously created mask
sc_ndot:
; add mask data into screens, may retrieve Y index here
		LDY cur_y			; retrieve index!
		ORA (spr_pt), Y		; mix mask with original data... (5)
		STA (org_pt), Y		; ...into buffer... (6)
		STA (dest_pt), Y	; ...and into VRAM (6)
		INC cur_y			; (5, unfortunately)
		BNE sc_loop			; (usually 3 for 255 times, then 2)
			INC spr_pt+1	; page crossing (5+5+5)
			INC org_pt+1
			INC dest_pt+1	; VRAM is last, as will set N flag when finished!
		BPL sc_loop			; stop at $8000 (usually 3, just 8 times)
; conveniently display score and lives
	LDA #0
	TAX
	JSR add_sc
	LDA #0
	JMP up_lives			; will return

; ******************************
; *** *** sprite drawing *** ***
; ******************************
; note tile coordinates are (x/4,y/4) from sprite upper left, although each tile is positioned (+2,+2)

; * draw all sprites *
; this may be fine for game start, however during play each sprite will be triggered by its own timer
sprites:
	LDY #4					; sprite to be drawn
	STY sel_gh
das_l:
		JSR draw
		DEC sel_gh
		BPL das_l
	RTS

; *** draw one sprite... ***
; new interface, sel_gh selects sprite (0=pacman, 1...4=ghost)
; actually moving the coordinates doesn't belong here, but using the proper direction is essential
draw:
; make a local copy of parameters
	LDY sel_gh				; get selected sprite
	LDA sp_stat, Y			; copy from array to temporary var
	CMP #DISABLE			; is it disabled?
	BNE draw_ok
		RTS					; if so, just abort!
draw_ok:
	STA ds_stat
	LDX sprite_x, Y			; X will hold X coordinate, will be shifted in storage
	STX draw_x
	LDA sprite_y, Y			; A holds actual Y coordinate, will shift in register
	STA draw_y				; ***maybe worth unifying
; compute base addresses, specific code will change as appropriate anyway
; new inlined version based on animation, 2b more but somewhat faster
; X=x, A=y, returns address in org_pt AND dest_pt
	STA org_pt+1			; store base MSB
	TXA						; now A is X...
	ASL						; ...but discard unused MSB!
	LSR org_pt+1			; divide by 16, assuming this is LWIDTH
	ROR
	LSR org_pt+1
	ROR
	LSR org_pt+1
	ROR
	LSR org_pt+1
	ROR						; LSB is ready here, base MSB in org_+1
	STA org_pt				; store both LSBs (identical)
	STA dest_pt
	LDA org_pt+1			; retrieve base MSB
	ORA #>org_b				; convert in full buffer address, valid for page-aligned addresses!
	STA org_pt+1
;	AND #$07				; retrieve base MSB, now for VRAM
;	ORA #>vram
	ORA #$70				; * this is feasible as dest=$7800 and org=$0800!
	STA dest_pt+1			; screen pointer is ready
; select routine according to direction
	LDX sp_dir, Y			; this can be done directly in X as direction is to be checked right after
	JMP (spd_draw, X)		; *** CMOS only *** execute appropriate code

; *** routine for sprite drawing, towards left ***
s_left:
; must select sprite file first! I don't think this can be generic
	LDA sel_gh				; pacman or ghost?
	BEQ sl_pac
; if it's a ghost, must check status, as frightened (and eaten) are different
		LDX ds_stat			; current status
		LDY spt_l, X		; get pointer from table, one for each direction
		LDA spt_l+1, X
		BNE spl_set
sl_pac:
; it's pacman, no status check, just direction
	LDY #<s_pac_l
	LDA #>s_pac_l
spl_set:
	STY spr_pt				; select sprite file base address
	STA spr_pt+1
; org_pt and dest_pt are certainly OK, just get X mod 8 for sprite frame selection
	LDA draw_x				; check horizontal offset
	AND #7					; towards left there is no back off! eeeeeeeeek
	JMP sh_draw				; all set and A as requested by common code

; *** routine for sprite drawing, towards right ***
s_right:
; must select sprite file first! I don't think this can be generic
	LDA sel_gh				; pacman or ghost?
	BEQ sr_pac
; if it's a ghost, must check status, as frightened (and eaten) are different
		LDX ds_stat			; current status
		LDY spt_r, X		; get pointer from table, one for each direction
		LDA spt_r+1, X
		BNE spr_set
sr_pac:
; it's pacman, no status check, just direction
	LDY #<s_pac_r
	LDA #>s_pac_r
spr_set:
	STY spr_pt				; select sprite file base address
	STA spr_pt+1
; org_pt and dest_pt are basically OK, but will change when aligned
	LDA draw_x				; check horizontal offset
	AND #7
	BNE sr_nal				; not aligned, do not back off eeeeeeeeeek
		DEC org_pt
		DEC dest_pt			; otherwise, set both screen pointers one byte before, no page boundaries expected
sr_nal:
;	JMP sh_draw				; all set and A as requested by common code

; inside-out, assume dest_pt, org_pt and spr_pt already set
; will use Y as direct index for spr, and indirectly offset for the screen pointers
; ** this should be valid for both left and right facing sprites, as long as pointers are properly set **
sh_draw:
; must finish spr_pt for the correct frame (this is common for all horizontal sprites) as long as A holds [x MOD 8]
	ASL						; times 16 as index for sprite file
	ASL
	ASL
	ASL
	CLC
	ADC spr_pt				; add to selected sprite file base address ***
	STA spr_pt
	BCC sh_nsw				; check for wrapping in sprite file
		INC spr_pt+1
sh_nsw:
	LDY #0					; reset sprite-file cursor
sh_loop:
		LDA (spr_pt), Y		; take sprite data
		ORA (org_pt), Y		; combine with clean screen
		STA (dest_pt), Y	; regular screen
		INY					; ditto for next byte
		LDA (spr_pt), Y		; take sprite data
		ORA (org_pt), Y		; combine with clean screen
		STA (dest_pt), Y	; regular screen
		INY					; done
		LDA org_pt			; Y has advanced twice, pointers should advance 14 (LWIDTH-2)
		CLC
		ADC #LWIDTH-2
		STA org_pt
		STA dest_pt			; really the same MSB
		BCC sh_npb			; check possible carry
			INC org_pt+1
			INC dest_pt+1
sh_npb:
		CPY #16				; bytes per sprite frame
		BNE sh_loop
	RTS

; *** routine for sprite drawing, downwards -- needs a VERY different approach! ***
; just place appropriate sprite frame and an extra byte above
; perhaps two if between bytes
s_down:
; must select sprite file first! I don't think this can be generic
	LDA sel_gh				; pacman or ghost?
	BEQ sd_pac
; if it's a ghost, must check status, as frightened (and eaten) are different
		LDX ds_stat			; current status
		LDY spt_d, X		; get pointer from table, one for each direction
		LDA spt_d+1, X
		TAX					; eeeeeeeeeek
		BNE spd_set
sd_pac:
; it's pacman, no status check, just direction
	LDY #<s_pac_d
	LDX #>s_pac_d
spd_set:
; org_pt and dest_pt seem OK
; *** put extra byte(s) above ***
; *** this is VERY coarse, but works anyway ***
; first, save future address
	LDA org_pt				; LSB is common with dest_pt
	SEC
	SBC #LWIDTH				; back one raster
	STA pre_pt
	LDA org_pt+1
;	PHP						; borrow goes on two MSBs
	SBC #0
	STA pre_pt+1			; future dest_pt
;	LDA dest_pt+1			; this MSB is different
;	PLP						; retrieve possible borrow
;	SBC #0
;	STA alt_msb				; different storage
; with X & Y properly set, proceed to draw
	JSR sv_draw
; *** retrieve address to be cleared ***
	LDX pre_pt				; common LSB must be in X for IOSCREEN
	STX org_pt
	LDA pre_pt+1			; buffer MSB
	STA org_pt+1
	STX dest_pt
;	LDA alt_msb				; the other MSB
	ORA #$70				; * this is feasible as dest=$7800 and org=$0800!
	STA dest_pt+1
	LDY #0					; eeeeek
; *** *** once pointers are set, just call su_clr *** ***
	JMP su_clr				; will return

; *** routine for sprite drawing, upwards -- needs a VERY different approach! ***
; just place appropriate sprite frame and an extra byte below
; perhaps two if  between bytes
s_up:
; must select sprite file first! I don't think this can be generic
	LDA sel_gh				; pacman or ghost?
	BEQ su_pac
; if it's a ghost, must check status, as frightened (and eaten) are different
		LDX ds_stat			; current status
		LDY spt_u, X		; get pointer from table, one for each direction
		LDA spt_u+1, X
		TAX					; eeeeeeeeeek
		BNE spu_set
su_pac:
; it's pacman, no status check, just direction
	LDY #<s_pac_u
	LDX #>s_pac_u
spu_set:
; org_pt and dest_pt seem OK
; advancing sprite pointer for half-byte lanes should be common!
	JSR sv_draw				; all set, check new interface
; dest_pt and org_pt (AFTER adding Y) are just BELOW the sprite, where the clear line must be drawn
; * if pointers are adequately set, this will serve for down facing sprites as well (above) *
su_clr:
		LDA (org_pt), Y		; get clean buffer (needs Y as expected)
		STA (dest_pt), Y	; and store in screen
		INY					; in case a second byte is to be done
		DEC hb_flag			; was zero or one!
		BPL su_clr			; if a second byte was needed, put it too
	RTS

sv_draw:
; new common vertical sprite draw
; takes base sprite pointer in X.Y
	LDA draw_x				; check horizontal offset
	AND #4					; is it between bytes?
; *** what to do? just advance once the sprite pointer... but must signal somehow to draw two bytes per raster!
	BEQ sv_alig				; it is aligned, stay at base sprite address
		INY					; otherwise, advance pointer by one
		BNE sv_alig			; just in case...
			INX
sv_alig:
	LSR						; A was 4 or zero, but we prefer 1 or 0
	LSR
	STA hb_flag				; we DO need sel_gh, I must use somewhere in tmp_arr as well
	LDA draw_y				; must select appropriate frame
	AND #7					; Y MOD 8
; ...but this time is x24, not x16
	ASL						; times 2
	ASL						; times 4
	ASL						; times 8, must be temporarily saved
	STA mul_tmp
	ASL						; times 16, C guaranteed CLEAR
	ADC mul_tmp				; times 24! again C is clear
	STY mul_tmp				; this is LSB
	ADC mul_tmp				; rectified pointer, A=Y+disp
	BCC sv_npc				; carry is possible
		INX
sv_npc:
	STA spr_pt				; set sprite file rectified address
	STX spr_pt+1
; all pointers set, go for it... but doing one (Z) or two bytes per raster depends on the contents of temp!
; temporary copy***
	LDY #0					; reset sprite-file cursor
sv_loop:
		LDA (spr_pt), Y		; take sprite data
		ORA (org_pt), Y		; combine with clean screen
		STA (dest_pt), Y	; regular screen
		INY					; ditto for next byte... in case it is needed
		LDA hb_flag			; is it?
		BEQ sv_2nd			; no, just go for next raster
			LDA (spr_pt), Y	; otherwise, take sprite data
			ORA (org_pt), Y	; combine with clean screen
			STA (dest_pt), Y	; regular screen
sv_2nd:
		INY					; done
		INY					; in any case, there are three bytes per (vertical) sprite raster
		LDA org_pt			; Y has advanced thrice, pointers should advance 13 (LWIDTH-3)
		CLC
		ADC #LWIDTH-3		; wink-wink-wink
		STA org_pt
		STA dest_pt			; really the same MSB
		BCC sv_npb			; check possible carry
			INC org_pt+1
			INC dest_pt+1
sv_npb:
		CPY #24				; bytes per sprite frame, not 16!
		BNE sv_loop
	RTS

; ** alphanumeric routines ** TONS of repeated code
; * add points to score and display it *
; takes value (BCD) in A (low), X (high, only for 160 --fourth ghost eaten--)
add_sc:
; add X.A to current score
; unusually, non-IOSCREEN version uses org_pt as VRAM pointer
	STX temp				; store temporarily
	SED						; decimal mode!
	CLC
	ADC score				; add to current value
	STA score
	LDA score+1
	ADC temp				; possible carry plus any value over 99
	STA score+1
	CLD						; back to binary
; now display it, two ciphers at a time!
	LDX #5
	STX temp				; use this as a scanline counter
	LDY #<bcdt				; set BCD table pointer
	LDA #>bcdt
	STY spr_pt
	STA spr_pt+1
	LDX #<sc_da				; set screen address for score area
	LDA #>sc_da
	STX org_pt				; will be kept as low address
	STA org_pt+1
ds_sc:
; first two digits
		LDY score+1			; this is an index for most significant couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
		STA (org_pt)		; put on this scanline *** CMOS ***
; last two digits
		INC org_pt			; advance to next couple of figures
		LDY score			; this is an index for least significant couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
		STA (org_pt)		; put on this scanline *** CMOS ***
		LDA org_pt			; increase screen pointer
		CLC
		ADC #LWIDTH-1
		STA org_pt
;		BCC ds_nnw			; should NEVER wrap, at least within the original range ($7B1C-$7B6D)
;			INC org_pt+1
;ds_nnw:
		LDA spr_pt			; also increase table pointer
		CLC
		ADC #160			; BCD tables have 160 entries each
		STA spr_pt
		LDA spr_pt+1
		BCC ds_tnw			; this is more likely to wrap
			INC spr_pt+1
ds_tnw:
		DEC temp			; until 5 scanlines are done
		BNE ds_sc
; must check whether the score is over the goal for extra life
	LDA score+1				; check MSB
	CMP goal
	BCS ds_extra			; below goal, ignore (***should I use BPL instead?)
		RTS
ds_extra:
	SED						; will use BCD for both goal and lives, no need to go back to binary here
	LDA goal
	ADC #9					; advance 1000 points, C known to be SET here
	STA goal
	LDA #1					; extra life
;	JMP up_lives			; will return... or fall directly

; * update lives counter *
; now add A to lives and display it, two ciphers!
up_lives:
	SED						; BCD mode!
	CLC
	ADC lives				; add A to current lives
	STA lives
	CLD
	LDX #5
	STX temp				; use this as a scanline counter
	LDY #<bcdt				; set BCD table pointer
	LDA #>bcdt
	STY spr_pt
	STA spr_pt+1
	LDX #<lv_da				; set screen address for lives area
	LDA #>lv_da
	STX org_pt				; will be kept as low address
	STA org_pt+1
ds_lv:
; only two digits
		LDY lives			; this is an index for a couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
		STA (org_pt)		; put on this scanline *** CMOS, hard to emulate in NMOS ***
		LDA org_pt			; increase screen pointer
		CLC
		ADC #LWIDTH
		STA org_pt
; should NEVER wrap, at least within the original range ($7C9D-$7CDD)***
		LDA spr_pt			; also increase table pointer
		CLC
		ADC #160			; BCD tables have 160 entries each
		STA spr_pt
		LDA spr_pt+1
		BCC dl_tnw			; this is more likely to wrap
			INC spr_pt+1
dl_tnw:
		DEC temp			; until 5 scanlines are done
		BNE ds_lv
	RTS

; * text routine *
; 40x5 patch to be placed is pointed by A.Y (will use org_pt)
; will be placed at (40,70), which starts at $7C65 up to $7CA9 (no page crossing)
l_text:
	STY org_pt
	STA org_pt+1
	LDX #$65				; base screen offset
	LDY #0					; read index
l_loop:
		LDA (org_pt), Y		; get patch data
		STA $7C00, X		; put it on screen***
		INX
		INY
		CPY #5				; check all possible raster ends
		BNE l_n5
			LDX #$75
l_n5:
		CPY #10
		BNE l_n10
			LDX #$85
l_n10:
		CPY #15
		BNE l_n15
			LDX #$95
l_n15:
		CPY #20
		BNE l_n20
			LDX #$A5
l_n20:
		CPY #25
		BNE l_loop
	RTS

; * fixed sprite animation *
; support for pacman death sound
; X=frame number (0...31), 8x8 pixel images
; takes coordinates from sprite_x[0] and sprite_y[0]
anim:
	TXA						; frame number
	ASL
	ASL
	ASL						; times 8
	TAY						; is index for sprite file
	LDX #8					; number of bytes
	STX anim_pt				; as counter
; this works (27b, 50t), but might reuse sprite screen address computing ***
	LDA sprite_y			; must be kept! (3+3)
	STA ds_stat
	LDA sprite_x			; pacman coordinates ·yyyyyyy ·xxxxxxx (3)
	ASL						; bit 7 unused xxxxxxx0 (2)
	LSR ds_stat				; non-destructive computing (5)
	ROR						; 00yyyyyy yxxxxxxx (2+5)
	LSR ds_stat
	ROR						; 000yyyyy yyxxxxxx (2+5)
	LSR ds_stat
	ROR						; 0000yyyy yyyxxxxx (2+5)
	LSR ds_stat
	ROR						; 00000yyy yyyyxxxx (2)
	STA org_pt				; nicer
	STA dest_pt				; part of the pointer (3+3)
	LDA ds_stat
	ORA #>org_b				; page aligned 00001yyy yyyyxxxx (2)
	STA org_pt+1
	ORA #$70				; * this is feasible as dest=$7800 and org=$0800!***
	STA dest_pt+1			; pointer complete (3)
af_loop:
		LDA sprite_x		; retrieve lower coordinate
		AND #7				; pixel within sprite eeeeeek
		TAX
		LDA pac_dies, Y		; get sprite data
; X must have the offset from byte boundary
		CPX #0
		BEQ sh_end
			STZ s_rot+1		; eeeeek
sha_l:
			LSR
			ROR s_rot+1
			DEX
			BNE sha_l
; A holds first byte, s_rot+1 is second byte
		STA s_rot			; save for later
		LDA s_rot+1			; get shifted value
		INC org_pt			; nicer
		ORA (org_pt)
		INC dest_pt			; it's the second one
		STA (dest_pt)		; ** CMOS **
		DEC dest_pt			; back one byte
		LDA s_rot			; retrieve first byte
		DEC org_pt			; back one byte
		ORA (org_pt)
sh_end:
		STA (dest_pt)		; ** CMOS **
		LDA org_pt
		CLC
		ADC #LWIDTH		; next line
		STA org_pt		; eeeek
		STA dest_pt		; is this OK?
		BCC af_nw
			INC org_pt+1
			INC dest_pt+1
af_nw:
		INY				; next raster in animation
		DEC anim_pt		; one less to go
		BNE af_loop
	RTS

; *********************
; *********************
; *** sound effects ***
; *********************
; *********************

; * Pacman death, animation plus integrated sound *
death:
	LDA #50					; one second pause
	JSR ms20
; actual pacman arcade deletes all sprites during animation
	JSR screen
; prepare animation parameters
	LDX #0
	JSR anim				; draw first frame
; first sqweak
	LDA #99					; initial freq
	LDY #88					; top freq
	LDX #36					; length
	JSR squeak				; actual routine
	LDX #1
	JSR anim				; draw second frame
; second sqweak
	LDA #118
	LDY #105
	LDX #30
	JSR squeak
	LDX #2
	JSR anim				; draw third frame
; third sqweak
	LDA #132
	LDY #117
	LDX #27
	JSR squeak
	LDX #3
	JSR anim				; draw fourth frame
; fourth sqweak
	LDA #148
	LDY #132
	LDX #24
	JSR squeak
	LDX #4
	JSR anim				; draw fifth frame
; fifth sqweak
	LDA #176
	LDY #157
	LDX #20
	JSR squeak
	LDX #5
	JSR anim				; draw bubble frame
; last two sweeps
	LDA #2
d_rpt:
	PHA						; iteration
	LDA #255
	STA swp_ct
dth_sw:
		LDX #10
		JSR m_beep
		LDA swp_ct
		SEC
		SBC #24
		STA swp_ct
		CMP #15
		BCS dth_sw
	LDA #4
	JSR ms20				; ~80 ms delay, no longer 75
; should clear pacman space
	LDX #6
	JSR anim				; last frame is clear
; next iteration
	PLA
	DEC						; *** CMOS ***
	BNE d_rpt
; one second delay after death
	LDA #50
	JSR ms20
; subtract one life!
	LDA #$99				; in BCD, this is -1
	JMP up_lives			; will return

; *** ** beeping routine ** ***
; *** X = length, A = freq. ***
; *** X = 2*cycles          ***
; *** tcyc = 16 A + 20      ***
; ***     @1.536 MHz        ***
; modifies Y, returns X=0
m_beep:
	SEI						; eeeeeek
beep_l:
		TAY					; determines frequency (2)
		STX IOBeep			; send X's LSB to beeper (4)
rb_zi:
			STY bp_dly		; small delay for 1.536 MHz! (3)
			DEY				; count pulse length (y*2)
			BNE rb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE beep_l			; new half cycle (3)
	STX IOBeep				; turn off the beeper!
	CLI						; restore interrupts... if needed
	RTS

; *** ** rest routine ** ***
; ***     X = length     ***
; *** X 1.33 ms @ 1.536M ***
; modifies Y, returns X=0
m_rest:
		LDY #0				; this resets the counter
r_loop:
			STY bp_dly		; delay for 1.536 MHz
			INY
			BNE r_loop		; this will take ~ 1.33 ms
		DEX					; continue
		BNE m_rest
	RTS

; * click after pacman eats a dot *
munch:
	LDA #50
	LDX #2
	JMP m_beep				; ...and will return to caller

; * sound after pacman eats a ghost *
eat_gh:
	LDA #0
	STA swp_ct
sweep:
		LDX #8
		JSR m_beep
		LDA swp_ct
		SEC
		SBC #4
		STA swp_ct
		CMP #16
		BCS sweep
	RTS						; eeeeeeek

; * sound after pacman dies (must be combined with animation!) *
; squeak, get higher then lower
; A=initial period, Y=final period, X=length
; uses m_beep
squeak:
	STA sqk_par+1
	STA sqk_par				; and current
	STY sqk_par+2
	STX swp_ct
sw_up:
		LDX swp_ct
		JSR m_beep
		LDA sqk_par
		SEC
		SBC #3
		STA sqk_par
		CMP sqk_par+2
		BCS sw_up
sw_down:
		LDX swp_ct
		JSR m_beep
		LDA sqk_par
		CLC
		ADC #3
		STA sqk_par
		CMP sqk_par+1
		BCC sw_down
	RTS

; *********************************
; *********************************
; *** interrupt service routine ***
; *********************************
; *********************************
pm_isr:
	PHA						; (3)
	PHY						; (3)
	LDY IO9in				; get input port (4) *** this will change with matrix keyboard, see below ***
	LDA (stkb_tab), Y		; on keyboard, QAOP, ESDF, Spectrum and cursor keys supported! Otherwise get joystick pattern (5)
	STA stick				; store in variable (3)
	PLY						; (4) eeek
	PLA						; (4)
	INC jiffy				; count time (5)
		BNE i_end			; (3 in the fastest case)
	INC jiffy+1				; (or add 2+5)
		BNE i_end			; (perhaps 3)
	INC jiffy+2				; (or add 2+5)
i_end:
	RTI						; (6, fastest case is 40, plus 7 of IRQ ack, seems OK at 47...)

; ** if using matrix keyboard, insert this code somewhere **
;	LDA #$D0				; cursor keys column (2)
;	STA IO9kbd				; select column (4)
;	LDA IO9kbd				; get rows (inverted) (2)
;	AND #$F					; filter relevant bits (2)
;	EOR #$F					; invert bits (2)
;	TAY						; ...ready for LDA (stkb_tab), Y *** or some other indexed table! (2)

; ****************************
; ****************************
; *** *** diverse data *** ***
; ****************************
; ****************************

; initial sprite speeds *** placeholder
i_speed:
	.byt	8, 9, 9, 20, 20	; check tables for appropriate speeds, some will change!
; should add additional speeds for further stati
; ...and more entries for subsequent levels
; *** speed for ghosts in WAIT mode might be sort of a counter for the expected delay to enter in GROW mode (which should start at fixed speed)

; initial positions (note order is pac_x, pac_y, pac_dir and the respective arrays with ghost # as index
; ghost arrays (1...4) are blinky, pinky, inky and clyde, with pacman first (index 0)
; blinky is outside the base at startup
; note horizontal 2-px offset to make maze into 4-px boundaries at least
; vertical movements of ghosts inside the base should be ad hoc
init_p:
	.byt	54, 54, 54, 54, 54	; sprites initial X (2px offset, note "wrong" intial values for last ghosts, not 46-62)
	.byt	92, 44, 56, 56, 56	; sprites initial Y (new 2px offset, not much of a problem)
	.byt	 0,  4,  6,  6,  6	; sprites initial direction (RDLU times two)
; ghosts initial state (nonsense for pacman, see pacman.h)
	.byt	WAIT, FRIGHT, FRIGHT, FRIGHT, FRIGHT	; *** all frightened for testing

; valid X values in current system (+2 offset)
; 4, 12, 24, 36, 48, (54 for base), 60, 72, 84, 96, 104
; which fit into these (half)byte offsets
; 0.5, 1.5, 3, 4.5, 6, (6.75), 7.5, 9, 10.5, 12, 13
; since the base exit is for rising ghosts only, it might be an special case *** a 2px error seems acceptable
; but some ghosts inside the base jump at X=46 and X=62 (5.75 & 7.75) *** will not show

; ***************************************************
; ** table of pointers for sprite drawing routines **
spd_draw:
	.word	s_right
	.word	s_down
	.word	s_left
	.word	s_up

; ** pointer tables for status selection **
; status pointers order must match pacman.h
;			*WAIT	^GROW	SCATTER	CHASE	CLEAR	EATEN	FRIGHT	FLASH	*FR_W	*DISABL	^FR_G	^FL_G	(note FR_WAIT and DISABLE for padding)
spt_l:
	.word	s_clr,  s_clr,  s_gh_l, s_gh_l, s_clr, s_eat_l, s_fg_l, s_ff_l, s_clr,  s_clr,  s_clr,  s_clr
spt_r:
	.word	s_clr,  s_clr,  s_gh_r, s_gh_r, s_clr, s_eat_r, s_fg_r, s_ff_r, s_clr,  s_clr,  s_clr,  s_clr
spt_u:
	.word	s_clr,  s_gh_u, s_gh_u, s_gh_u, s_clr, s_eat_u, s_fg_u, s_ff_u, s_clr,  s_clr,  s_fg_u, s_ff_u	; GROW only makes sense here
spt_d:
	.word	s_clr,  s_clr,  s_gh_d, s_gh_d, s_clr, s_eat_d, s_fg_d, s_ff_d, s_clr,  s_clr,  s_clr,  s_clr

#ifndef	NMOS
pk_mv:
	.word	pk_rt, pk_dn, pk_lt, pk_up, dir_set	; *** table of pointers, may go elsewhere but only for CMOS ***
#endif

; ** pointer to stick index tables, depending on keyboard/joystick mode **
dir_tab:
	.word	asc2dir			; [0] for keyboard
	.word	stk2dir			; [2] for joystick

; ** ** ** end of pointer tables ** ** **
; ***************************************

; * IO9 keyboard to stick index conversion *
asc2dir:
	.byt	STK_K, STK_K, STK_L, STK_K, STK_K, STK_K, STK_R, STK_K, STK_K, STK_K, STK_D, STK_U, STK_K, STK_K, STK_K, STK_K	; arrow keys
	.dsb	16, STK_K																										; no valid values here (16...31)
	.dsb	16, STK_K																										; no valid values here (32...47)
	.byt	STK_K, STK_K, STK_K, STK_K, STK_K, STK_L, STK_D, STK_U, STK_R, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K	; Spectrum cursors 5...8
	.byt	STK_K, STK_D, STK_K, STK_K, STK_D, STK_U, STK_R, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_L	; A,D=down, E=up, F=right, O=left
	.byt	STK_R, STK_U, STK_K, STK_L, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K	; P=right, Q=up, S=left
	.byt	STK_K, STK_D, STK_K, STK_K, STK_D, STK_U, STK_R, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_L	; a,d=down, e=up, f=right, o=left
	.byt	STK_R, STK_U, STK_K, STK_L, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K, STK_K	; p=right, q=up, s=left
#ifdef	SAFE
	.dsb	128, STK_K		; non-standard ASCII values not recognised, seems important for º/ª in Spanish layout, maybe accents too!
#endif

; * direct joystick to index conversion *
; assume stick is wired d0=RIGHT, d1=DOWN, d2=LEFT, d3=UP
; actually sequential values 0...15, assuming STK_R/D/L/U are 1, 2, 4 and 8
stk2dir:
	.byt	0,	1,	2,	3,	4,	5,	6,	7,	8,	9,	10,	11,	12,	13,	14,	15

; * stick reaction tables *
; preferred movement
st_des:
; stick		0		1		2		3		4		5		6		7		8		9		A		B		C		D		E		F
;			=		r		d		rd		l		lr!		ld		lrd!	u		ur		ud!		urd!	ul		ulr!	uld!	ALL!
	.byt	KEEP,	RIGHT,	DOWN,	DOWN,	LEFT,	KEEP,	LEFT,	KEEP,	UP,		UP,		KEEP,	KEEP,	UP,		KEEP,	KEEP,	KEEP
; alternative movement
st_alt:
	.byt	KEEP,	RIGHT,	DOWN,	RIGHT,	LEFT,	KEEP,	DOWN,	KEEP,	UP,		RIGHT,	KEEP,	KEEP,	LEFT,	KEEP,	KEEP,	KEEP
; special case between tiles
st_horz:
	.byt	KEEP,	RIGHT,	KEEP,	RIGHT,	LEFT,	KEEP,	LEFT,	KEEP,	KEEP,	RIGHT,	KEEP,	KEEP,	LEFT,	KEEP,	KEEP,	KEEP
st_vert:
	.byt	KEEP,	KEEP,	DOWN,	DOWN,	KEEP,	KEEP,	DOWN,	KEEP,	UP,		UP,		KEEP,	KEEP,	UP,		KEEP,	KEEP,	KEEP

; initial map status
i_map:
#include "map.s"
	.dsb	16, 0			; mandatory padding?

; BCD glyph pair tables
; each scanline, then 100 values from $00 to $99
; could easily add some hex up to $9F
bcdt:
#include "bcdt.s"

; squares table for AI
; provides sq_lo and sq_ai labels
#include "squares.s"

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
; *** graphics *** TBD
; ****************

; original maze (full 128x128 screen)
maze:
	.bin	0, 8192, "../../other/data/maze4.sv"	; ***TBD

; text chunks
p_text:
	.bin	9, 75, "../../other/data/pacmantxt.pbm"	; *** now with three chunks ***

; *** sprites ***
; pacman towards right
s_pac_r:
	.bin	9, 128, "../../other/data/pac-right.pbm"
; pacman towards left
s_pac_l:
	.bin	9, 128, "../../other/data/pac-left.pbm"
; pacman downwards *** uses new 24x64 scheme for vertical!
s_pac_d:
	.bin	9, 192, "../../other/data/pac-down.pbm"
; pacman upwards
s_pac_u:
	.bin	9, 192, "../../other/data/pac-up.pbm"
; ghost towards right
s_gh_r:
	.bin	9, 128, "../../other/data/ghost-right.pbm"
; ghost towards left
s_gh_l:
	.bin	9, 128, "../../other/data/ghost-left.pbm"
; ghost downwards
s_gh_d:
	.bin	9, 192, "../../other/data/ghost-down.pbm"
; ghost upwards
s_gh_u:
	.bin	9, 192, "../../other/data/ghost-up.pbm"
; frightened ghost towards right
s_fg_r:
	.bin	9, 128, "../../other/data/fright-right.pbm"
; frightened ghost towards left
s_fg_l:
	.bin	9, 128, "../../other/data/fright-left.pbm"
; frightened ghost downwards
; frightened ghost upwards *** actually both using the same sprite
s_fg_d:
s_fg_u:
	.bin	9, 192, "../../other/data/fright-vert.pbm"
; flashing frightened ghost
s_ff_l:
	.bin	9, 128, "../../other/data/flash-left.pbm"
s_ff_r:
	.bin	9, 128, "../../other/data/flash-right.pbm"
s_ff_u:
s_ff_d:
	.bin	9, 192, "../../other/data/flash-vert.pbm"
; eaten ghosts (mostly identical frames, for the sake of code reuse)
s_eat_r:
	.bin	9, 128, "../../other/data/eyes-right.pbm"
s_eat_l:
	.bin	9, 128, "../../other/data/eyes-left.pbm"
s_eat_d:
	.bin	9, 192, "../../other/data/eyes-down.pbm"
s_eat_u:
	.bin	9, 192, "../../other/data/eyes-up.pbm"
; pacman dies! (animation)
pac_dies:
	.bin	8, 48, "../../other/data/palmatoria.pbm"
s_clr:
	.dsb	192, 0			; mandatory end padding (8), also for clear sprites

pm_end:						; for size computation

; NOTE, in scatter mode, targets are
; pinky = tile(2,-4) or is it -3???
; blinky = tile(25,-4) id
; clyde = tile(0,31) or is it 32???
; inky = tile(27,31) id

; in chase mode, targets are
; blinky = PACMAN
; pinky = L(-4,+0), D(+0,+4), R(+0,+4), U(-4,-4)!
; inky = pre L(-2,0), D(0,2), R(0,2), U(-2,-2), extended by blinky...
; clyde = PACMAN [d>8]; tile(0,31) [d<=8]
