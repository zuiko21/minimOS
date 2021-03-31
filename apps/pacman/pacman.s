; PacMan for Durango breadboard computer!
; hopefully adaptable to other 6502 devices
; (c) 2021 Carlos J. Santisteban
; last modified 20210331-1252

; can be assembled from this folder

; variables, esp. zeropage
#include "pacman.h"

; *** addresses definition ***
	fw_isr	= $200			; standard minimOS firmware address
	vram	= $7800			; suitable for Durango
	sc_da	= vram + $31C	; address for score display, usually $7B1C
	lv_da	= vram + $49D	; address for lives display, usually $7C9D
	lwidth	= 16			; formerly bytlin, bytes per line, being a power of two makes things MUCH simpler!
; I/O addresses
	IO8lh	= $8000			; screen latch high
	IO8ll	= $8001			; screen latch low
	IO8wr	= $8003			; screen write data
	IOAie	= $A001			; enable hardware interrupt, LSB must be $01!
	IOAid	= $A000			; disable hardware interrupt
	IOBeep	= $BFF0			; beeper address (latches D0 value)
	LTCdo	= $FFF0			; LTC display port

; uncomment this if non-direct, IO-based display interface is used
#define	IOSCREEN	_IOSCREEN

; *** actual code starts here ***
	.text

	* = $4000				; standard system download address, hopefully will be enough!

; basic 6502 init, as this is a stand-alone game
start:
	SEI
	CLD
	LDX #$FF
	TXS

	STX LTCdo				; turn off Durango display *** might use upper bits for keyboard read

	LDY #<pm_isr			; set interrupt vector
	LDA #>pm_isr
	STY fw_isr				; standard minimOS address
	STA fw_isr+1

; perhaps is time to init data...
	INX						; gets a zero (X known to be zero)
	STX score				; reset score
	STX score+1
	LDA #5					; initial lives
	STA lives
	LDA #$10				; needs to be 10 in BCD eeeeeeek
	STA goal				; next extra life at 1000 points

; initial screen setup, will be done every level as well
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots), may modify X
	JSR positions			; reset initial positions (and show 'Ready!' message)
	JSR sprites				; draw all ghosts and pacman on screen

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
	CLI						; make sure interrupts are enabled as will be needed for timing
	LDA IOAie				; ...and enable in hardware too! eeeeek

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
			PHX				; ** CMOS ** easily changed to TXA:PHA
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
				JSR draw
g_next:
			PLX				; ** CMOS ** easily changed to PLA:TAX
			INX				; next sprite
			CPX #5			; all sprites done?
			BNE g_loop
		LDA dots			; all dots done?
		BNE g_start			; repeat loop

g_end:
; *************************************************
; *** if arrived here, level ended successfully ***
; *************************************************
	LDA #80					; two-second delay
	JSR ms25
; worth showing a flashing map (4 times) for a couple of seconds?

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
	LDA #80					; 2-second delay
	JSR ms25
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
	LDY #<(p_text+25)		; second chunk is the 'Game Over' message
	LDA #>(p_text+25)
	JSR l_text
; shall I wait for some key to start a new game? exit option?
	JMP *					; placeholder

; ***************************
; ***************************
; *** supporting routines ***
; ***************************
; ***************************

; * preload map with initial state *
; will just copy 0.5 Kbyte, don't bother with individual coordinates (5.9 ms)
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
#ifdef	IOSCREEN
	STA IO8lh				; preload page into high-address latch (IOSCREEN doesn't care about highest bits)
; IOSCREEN doesn't need dest_pt at all!
#else
;	LDY #<vram				; pointer to VRAM (Y known to be zero, as both blocks are page-aligned)
	LDA #>vram
	STY dest_pt				; load destination pointer
	STA dest_pt+1
#endif
;	LDY #<d_map				; get map initial pointer, once again page-aligned
	LDA #>d_map
	STY map_pt
	STA map_pt+1
	STY cur					; save this index, as it isn't valid everywhere
; now using a compact-map format, two tiles per byte, w0d0p0b0w1d1p1b1, as it makes a lot of sense!
sc_loop:
; check line position within row
		LDA cur				; check coordinates
		AND #lwidth-1		; filter column (assuming lwidth is power of 2)
		TAY					; will be used for the mask array AND map index
		LDA cur				; now for the lowest Y-bits
		AND #%00110000		; we only need the lowest 2 bits, assuming lwidth = 16
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
			LDA cur			; beginning of line?
			AND #15			; eeeeeeeeek
			BNE sc_rowm		; if not, do NOT increment! eeeeeeeeek
				LDA map_pt	; this is the end of the tile raster, thus advance to next row
				CLC
				ADC #lwidth	; will advance map_pt, usually by 16
				STA map_pt
				BCC sc_rowm	; check possible carry
					INC map_pt+1
sc_rowm:
; take the same mask as created two rasters before
			LDA dmask, Y	; take previously created mask
sc_ndot:
; add mask data into screens, may retrieve Y index here
		LDY cur				; retrieve index!
		ORA (spr_pt), Y		; mix mask with original data... (5)
		STA (org_pt), Y		; ...into buffer... (6)
#ifdef	IOSCREEN
		STY IO8ll			; low-address latch (4)
		STA IO8wr			; actual data transfer (4)
#else
		STA (dest_pt), Y	; ...and into VRAM (6)
#endif
		INC cur				; (5, unfortunately)
		BNE sc_loop			; (usually 3 for 255 times, then 2)
			INC spr_pt+1	; page crossing (5+5+5)
			INC org_pt+1
#ifdef	IOSCREEN
			LDA org_pt+1	; new page value... (3)
			STA IO8lh		; ...gets into high-address latch (4)
			CLC				; this IS needed, indeed
			ADC #$70		; dirty hack for the BPL below to work!
#else
			INC dest_pt+1	; VRAM is last, as will set N flag when finished!
#endif
		BPL sc_loop			; stop at $8000 (usually 3, just 8 times)
; conveniently display score and lives
	LDA #0
	TAX
	JSR add_sc
	LDA #0
	JMP up_lives			; will return

; * reset initial positions *
; returns X=0, modifies A
positions:
	LDX #20					; 5 sprites x 4 coordinates/stati
ip_loop:
		LDA init_p-1, X		; get data from tables, note offsets
		STA sprite_x-1, X	; into ZP variables
		DEX
		BNE ip_loop
; I think this should reset counters and timers as well
; lastly, print 'Ready!' message
	LDY #<p_text			; initial patch is 'Ready!' message
	LDA #>p_text
	JMP l_text				; will return

; *** *** sprite moving routines, the actual AI *** ***
; X expected to have selected ghost (already stored in sel_gh)
; must change sprite_x[X], sprite_y[X] and/or sp_dir[X], perhaps other paremeters too
move:
	TXA						; check sprite
	BNE is_ghost			; pacman only looks for joystick input and map entries
		INC sprite_x		; *** PLACEHOLDER
		RTS
is_ghost:
		CPX #1				; *** PLACEHOLDER...
		BNE growing
			DEC sprite_x+1
			RTS
growing:
			DEC sprite_y, X
	RTS

; *** *** sprite drawing *** ***
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
	LSR org_pt+1			; divide by 16, assuming this is lwidth
	ROR
	LSR org_pt+1
	ROR
	LSR org_pt+1
	ROR
	LSR org_pt+1
	ROR						; LSB is ready here, base MSB in org_+1
	STA org_pt				; store both LSBs (identical)
#ifndef	IOSCREEN
	STA dest_pt
#endif
	LDA org_pt+1			; retrieve base MSB
	ORA #>org_b				; convert in full buffer address, valid for page-aligned addresses!
	STA org_pt+1
#ifndef	IOSCREEN
;	AND #$07				; retrieve base MSB, now for VRAM
;	ORA #>vram
	ORA #$70				; * this is feasible as dest=$7800 and org=$0800!
	STA dest_pt+1			; screen pointer is ready
#endif
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
#ifndef	IOSCREEN
		DEC dest_pt			; otherwise, set both screen pointers one byte before, no page boundaries expected
#endif
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
#ifdef	IOSCREEN
	LDA org_pt+1			; eeeeeek, but doesn0¡'t matter if org_pt or dest_pt
	STA IO8lh
	LDX org_pt				; keep this updated, ditto
#endif
sh_loop:
		LDA (spr_pt), Y		; take sprite data
		ORA (org_pt), Y		; combine with clean screen
#ifdef	IOSCREEN
		STX IO8ll			; alternate index, copying dest_pt LSB
		STA IO8wr			; place data
#else
		STA (dest_pt), Y	; regular screen
#endif
		INY					; ditto for next byte
		LDA (spr_pt), Y		; take sprite data
		ORA (org_pt), Y		; combine with clean screen
#ifdef	IOSCREEN
		INX					; eeeeeeek
		STX IO8ll			; alternate index, copying dest_pt LSB
		STA IO8wr			; place data
#else
		STA (dest_pt), Y	; regular screen
#endif
		INY					; done
		LDA org_pt			; Y has advanced twice, pointers should advance 14 (lwidth-2)
		CLC
		ADC #lwidth-2
		STA org_pt
#ifndef	IOSCREEN
		STA dest_pt			; really the same MSB
#endif
		BCC sh_npb			; check possible carry
			INC org_pt+1
#ifdef	IOSCREEN
			LDA org_pt+1
			STA IO8lh
#else
			INC dest_pt+1
#endif
sh_npb:
#ifdef	IOSCREEN
			TYA
			CLC
			ADC org_pt
			BCC sh_npw
				LDX org_pt+1	; note as above
				INX
				STX IO8lh
sh_npw:
			TAX				; keep this index updated
#endif
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
	SBC #lwidth				; back one raster
	STA tmp_arr+2
	LDA org_pt+1
;	PHP						; borrow goes on two MSBs
	SBC #0
	STA tmp_arr+3			; tmp_arr+2 is future dest_pt
;	LDA dest_pt+1			; this MSB is different
;	PLP						; retrieve possible borrow
;	SBC #0
;	STA tmp_arr+15			; different storage
; with X & Y properly set, proceed to draw
	JSR sv_draw
; *** retrieve address to be cleared ***
	LDX tmp_arr+2			; common LSB must be in X for IOSCREEN
	STX org_pt
	LDA tmp_arr+3			; buffer MSB
	STA org_pt+1
#ifdef	IOSCREEN
	STA IO8lh				; eeeeeeeek
#else
	STX dest_pt
;	LDA tmp_arr+15			; the other MSB
	ORA #$70				; * this is feasible as dest=$7800 and org=$0800!
	STA dest_pt+1
#endif
	LDY #0					; eeeeek
; *** *** once pointers are set, just call su_clr *** ***
	JMP su_clr				; will return

; *** routine for sprite drawing, upwards -- needs a VERY different approach! ***
; just place appropriate sprite frame and an extra byte below
; perhaps two if between bytes
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
#ifndef	IOSCREEN
		STA (dest_pt), Y	; and store in screen
#else
		STX IO8ll			; alternate index, copying dest_pt LSB+Y
		STA IO8wr			; place data
		INX					; otherwise won't be indexed!
#endif
		INY					; in case a second byte is to be done
		DEC tmp_arr+1		; was zero or one!
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
	STA tmp_arr+1			; we DO need sel_gh, I must use somewhere in tmp_arr as well
	LDA draw_y				; must select appropriate frame
	AND #7					; Y MOD 8
; ...but this time is x24, not x16
	ASL						; times 2
	ASL						; times 4
	ASL						; times 8, must be temporarily saved
	STA tmp_arr
	ASL						; times 16, C guaranteed CLEAR
	ADC tmp_arr				; times 24! again C is clear
	STY tmp_arr				; this is LSB
	ADC tmp_arr				; rectified pointer, A=Y+disp
	BCC sv_npc				; carry is possible
		INX
sv_npc:
	STA spr_pt				; set sprite file rectified address
	STX spr_pt+1
; all pointers set, go for it... but doing one (Z) or two bytes per raster depends on the contents of temp!
; temporary copy***
	LDY #0					; reset sprite-file cursor
#ifdef	IOSCREEN
	LDA org_pt+1			; eeeeeek
	STA IO8lh
	LDX org_pt				; keep this updated
#endif
sv_loop:
		LDA (spr_pt), Y		; take sprite data
		ORA (org_pt), Y		; combine with clean screen
#ifdef	IOSCREEN
		STX IO8ll			; alternate index, copying dest_pt LSB
		STA IO8wr			; place data
#else
		STA (dest_pt), Y	; regular screen
#endif
		INY					; ditto for next byte... in case it is needed
		LDA tmp_arr+1		; is it?
		BEQ sv_2nd			; no, just go for next raster
			LDA (spr_pt), Y	; otherwise, take sprite data
			ORA (org_pt), Y	; combine with clean screen
#ifdef	IOSCREEN
			INX				; eeeeeeek
			STX IO8ll		; alternate index, copying dest_pt LSB
			STA IO8wr		; place data
#else
			STA (dest_pt), Y	; regular screen
#endif
sv_2nd:
		INY					; done
		INY					; in any case, there are three bytes per (vertical) sprite raster
		LDA org_pt			; Y has advanced thrice, pointers should advance 13 (lwidth-3)
		CLC
		ADC #lwidth-3		; wink-wink-wink
		STA org_pt
#ifndef	IOSCREEN
		STA dest_pt			; really the same MSB
#endif
		BCC sv_npb			; check possible carry
			INC org_pt+1
#ifdef	IOSCREEN
			LDA org_pt+1
			STA IO8lh
#else
			INC dest_pt+1
#endif
sv_npb:
#ifdef	IOSCREEN
			TYA
			CLC
			ADC org_pt
			BCC sv_npw
				LDX org_pt+1
				INX
				STX IO8lh
sv_npw:
			TAX				; keep this index updated
#endif
		CPY #24				; bytes per sprite frame, not 16!
		BNE sv_loop
	RTS

; * compute map data from pixel coordinates * REDONE, yet to be used
chk_map:
; newest interface is X=x, Y=y, returns them unmodified! returns A.MSN
	TXA
	ASL						; forget unused MSB.X
	STA map_pt				; will be into pointer LSB
	TYA						; get Y coordinate
	LSR
	LSR						; discard raster for tile row
	LSR						; shift into X in RAM
	ROR map_pt
	LSR
	ROR map_pt
	LSR
	ROR map_pt
	LSR
	ROR map_pt				; after this, C indicates left/right tile in byte
	AND #1					; just save remaining MSB.Y
	ORA #6					; ** valid as long as map is at $600 **
	STA map_pt+1			; MSB (and whole pointer) is ready
	LDA (map_pt)			; *** CMOS *** gets two consecutive tiles
	BCC mp_left				; is the right (odd) nibble?
		ASL					; rotate bits towards MSB
		ASL
		ASL
		ASL
mp_left:
	RTS						; in any case, d7-d4 are the flags

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
#ifdef	IOSCREEN
	STA IO8lh				; latch high address, fortunately won't change ($7B10...$7B61)
	STX IO8ll
#endif
ds_sc:
; first two digits
		LDY score+1			; this is an index for most significant couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
#ifdef	IOSCREEN
		STA IO8wr
#else
		STA (org_pt)		; put on this scanline *** CMOS ***
#endif
; last two digits
#ifndef	IOSCREEN
		INC org_pt			; advance to next couple of figures
#else
		INX
		STX org_pt
		STX IO8ll
#endif
		LDY score			; this is an index for least significant couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
#ifdef	IOSCREEN
		STA IO8wr
#else
		STA (org_pt)		; put on this scanline *** CMOS ***
#endif
		LDA org_pt			; increase screen pointer
		CLC
		ADC #lwidth-1
		STA org_pt
#ifdef	IOSCREEN
		TAX					; keep low order address updated
		STX IO8ll			; eeeeeeeeeeek
#endif
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
#ifdef	IOSCREEN
	STA IO8lh				; latch high address, fortunately won't change ($7B1C...$7B5D)
	STX IO8ll
#endif
ds_lv:
; only two digits
		LDY lives			; this is an index for a couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
#ifdef	IOSCREEN
		STA IO8wr
#else
		STA (org_pt)		; put on this scanline *** CMOS, hard to emulate in NMOS ***
#endif
		LDA org_pt			; increase screen pointer
		CLC
		ADC #lwidth
		STA org_pt
#ifdef	IOSCREEN
		TAX					; keep low order address updated
		STX IO8ll			; eeeeeeeek
#endif
; should NEVER wrap, at least within the original range ($7C9D-$7CDD)
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
#ifdef	IOSCREEN
	LDA #$7C				; VRAM MSB
	STA IO8lh				; no need to store this as will not change ever
#endif
	LDX #$65				; base screen offset
	LDY #0					; read index
l_loop:
		LDA (org_pt), Y		; get patch data
#ifdef IOSCREEN
		STX IO8ll			; send data to IO screen
		STA IO8wr
#else
		STA $7C00, X		; put it on screen
#endif
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

; ** timing and animations **
; * 25ms generic delay *
; delay ~25A ms
ms25:
	LDX #20					; computed iterations for a 25ms delay (note below, total 9t overhead, 0.036%)
	LDY #$78				; first iteration takes ~half the time, will run 138 cycles, actually ~19.5 iterations
m25d:
			DEY				; inner loop (2y)x
			BNE m25d		; (3y-1)x, total 1279t if in full, ~689 otherwise
		DEX					; outer loop (2x)
		BNE m25d			; (3x-1)
	DEC						; ** CMOS **
		BNE ms25
	RTS						; add 12t from call overhead

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
	STX temp				; as counter
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
#ifndef	IOSCREEN
	STA dest_pt				; part of the pointer (3+3)
#endif
	LDA ds_stat
	ORA #>org_b				; page aligned 00001yyy yyyyxxxx (2)
	STA org_pt+1
#ifndef	IOSCREEN
	ORA #$70				; * this is feasible as dest=$7800 and org=$0800!
	STA dest_pt+1			; pointer complete (3)
#endif
af_loop:
		LDA sprite_x		; retrieve lower coordinate
		AND #7				; pixel within sprite eeeeeek
		TAX
		LDA pac_dies, Y		; get sprite data
; X must have the offset from byte boundary
		CPX #0
		BEQ sh_end
			STZ cur+1		; eeeeek
sha_l:
			LSR
			ROR cur+1
			DEX
			BNE sha_l
; A holds first byte, cur+1 is second byte
		STA cur			; save for later
		LDA cur+1		; get shifted value
		INC org_pt		; nicer
		ORA (org_pt)
#ifdef	IOSCREEN
		LDX org_pt+1	; MSB actually
		STX IO8lh
		LDX org_pt		; this is LSB
		STX IO8ll
		STA IO8wr		; store this
#else
		INC dest_pt		; it's the second one
		STA (dest_pt)	; ** CMOS **
		DEC dest_pt		; back one byte
#endif
		LDA cur			; retrieve first byte
		DEC org_pt		; back one byte
		ORA (org_pt)
sh_end:
#ifdef	IOSCREEN
		LDX org_pt+1	; MSB actually
		STX IO8lh
		LDX org_pt		; this is LSB
		STX IO8ll
		STA IO8wr		; store this
#else
		STA (dest_pt)	; ** CMOS **
#endif
		LDA org_pt
		CLC
		ADC #lwidth		; next line
		STA org_pt		; eeeek
#ifndef	IOSCREEN
		STA dest_pt		; is this OK?
#endif
		BCC af_nw
			INC org_pt+1
#ifdef	IOSCREEN
			LDA org_pt+1
			STA IO8lh
#else
			INC dest_pt+1
#endif
af_nw:
		INY				; next raster in animation
		DEC temp		; one less to go
		BNE af_loop
	RTS

; *********************
; *** sound effects ***
; *********************

; * Pacman death, animation plus integrated sound *
death:
	LDA #40					; one second pause
	JSR ms25
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
	STA temp
dth_sw:
		LDX #10
		JSR m_beep
		LDA temp
		SEC
		SBC #24
		STA temp
		CMP #15
		BCS dth_sw
	LDA #3
	JSR ms25				; ~75 ms delay
; should clear pacman space
	LDX #6
	JSR anim				; last frame is clear
; next iteration
	PLA
	DEC						; *** CMOS ***
	BNE d_rpt
; one second delay after death
	LDA #40
	JSR ms25
; subtract one life!
	LDA #$99				; in BCD, this is -1
	JMP up_lives			; will return

; *** ** beeping routine ** ***
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
; modifies Y, returns X=0
m_beep:
	SEI						; eeeeeek
beep_l:
		TAY					; determines frequency (2)
		STX IOBeep			; send X's LSB to beeper (4)
rb_zi:
			DEY				; count pulse length (y*2)
			BNE rb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE beep_l			; new half cycle (3)
	STX IOBeep				; turn off the beeper!
	CLI						; restore interrupts... if needed
	RTS

; *** ** rest routine ** ***
; ***     X = length     ***
; ***    t = X 1.28 ms   ***
; modifies Y, returns X=0
m_rest:
		LDY #0				; this resets the counter
r_loop:
			INY
			BNE r_loop		; this will take ~ 1.28 ms
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
	STA temp
sweep:
		LDX #8
		JSR m_beep
		LDA temp
		SEC
		SBC #4
		STA temp
		CMP #16
		BCS sweep
	RTS						; eeeeeeek

; * sound after pacman dies (must be combined with animation!) *
; squeak, get higher then lower
; A=initial period, Y=final period, X=length
; uses m_beep
squeak:
	STA cur+1
	STA cur		; and current
	STY cur+2
	STX temp
sw_up:
		LDX temp
		JSR m_beep
		LDA cur
		SEC
		SBC #3
		STA cur
		CMP cur+2
		BCS sw_up
sw_down:
		LDX temp
		JSR m_beep
		LDA cur
		CLC
		ADC #3
		STA cur
		CMP cur+1
		BCC sw_down
	RTS

; *********************************
; *** interrupt service routine ***
; *********************************
pm_isr:
	PHA						; (3)
; *** I'm a bit paranoid about the interrupt being somewhat irregular, thus I'll waste some time ***
	LDA #%00010000			; enable column 1 from keyboard/keypad
	STA LTCdo				; display remains shut down, as all anodes are low
; *** end of paranoid code ***
	LDA $9FF0				; get input port (4)
	STA stick				; store in variable (3)
	PLA						; (4)
	INC jiffy				; count time (5)
		BNE i_end			; (3 in the fastest case)
	INC jiffy+1				; (or add 2+5)
		BNE i_end			; (perhaps 3)
	INC jiffy+2				; (or add 2+5)
i_end:
	RTI						; (6, fastest case is 27, plus 7 of IRQ ack, seems OK at 34...)
							; *** in case of paranoid code, add 6 cycles, for a safer 33t without ack ***
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
	.byt	 0,  4,  2,  0,  0	; ghosts initial state (nonsense for pacman, see pacman.h)

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
;			WAIT	GROW	SCATTER	CHASE	FRIGHT	FLASH	EATEN	CLEAR	(no need for DISABLE as does nothing)
spt_l:
	.word	s_clr,  s_clr,  s_gh_l, s_gh_l, s_fg_l, s_ff_l, s_eat_l, s_clr	; note new special sprites
spt_r:
	.word	s_clr,  s_clr,  s_gh_r, s_gh_r, s_fg_r, s_ff_r, s_eat_r, s_clr	; note new special sprites
spt_u:
	.word	s_clr,  s_gh_u, s_gh_u, s_gh_u, s_fg_u, s_ff_u, s_eat_u, s_clr	; note new special sprites, GROW only makes sense here
spt_d:
	.word	s_clr,  s_clr,  s_gh_d, s_gh_d, s_fg_d, s_ff_d, s_eat_d, s_clr	; note new special sprites

; ** ** ** end of pointer tables ** ** **
; ***************************************

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
; *** graphics ***
; ****************

; original maze (full 128x128 screen)
maze:
	.bin	11, 2048, "../../other/data/maze2.pbm"

; text chunks
p_text:
	.bin	9, 50, "../../other/data/pacmantxt.pbm"

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
