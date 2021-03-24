; PacMan for Durango breadboard computer!
; hopefully adaptable to other 6502 devices
; (c) 2021 Carlos J. Santisteban
; last modified 20210324-1946

; can be assembled from this folder

; variables, esp. zeropage
#include "pacman.h"

; *** constants definition ***
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
	LDA #244				; number of dots (no longer automatic, not really worth it)
	STA dots

; initial screen setup, will be done every level as well
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots), may modify X
	JSR positions			; reset initial positions, X is zero but...
;	JSR sprites				; draw all ghosts and pacman on screen (uses draw, in development)

; *********************************************************
; *** test code, move pacman and ghosts right and left! ***
; *********************************************************
lda jiffy
clc
adc #1	; just start all quickly
sta sprite_t+1
sta sprite_t
sta sprite_t+2
sta IOAie	; eeeeek
CLI
; * try complete engine *
testing:
; try to move and draw pacman
lda jiffy
cmp sprite_t
bmi npac
	adc#11	; pacman speed (12, as C was set)
	sta sprite_t
;	lda sprite_x	; actual X
;	cmp sprite_x+2	; same as frightened?
;	bne pne
;		jsr sweep
;pne:
;	and#3
;	bne ndot
;		jsr munch
;ndot:
;	lda sprite_x	; eeeek
;	cmp#85
;	bcc npr
;		ldx#4	; turn left
;		stx sprite_d
;npr:
;	cmp#24
;	bcs npl
;		stz sprite_d	; turn right
;npl:
;	ldx sprite_d	; direction?
;	clc
;	adc delta,x		; add displacement
;	and#127
;	sta sprite_x	; update
; * update coordinates *
	ldy #0			; pacman index
	jsr destino		; check new destination, updating x/y and d
	stz sel_gh	; draw pacman
	jsr draw
npac:
; try to move and draw ghost
lda jiffy
cmp sprite_t+1
bmi ngh
	adc#6	; ghost speed (7, as C was set)
	sta sprite_t+1
;	lda sprite_x+1	; actual X
;	cmp sprite_x
;	bne gne
;		jsr death
;		lda sprite_x+1	; eeeek
;gne:
;	cmp#85
;	bcc ngr
;		ldx#4	; turn left
;		stx sprite_d+1
;ngr:
;	cmp#24
;	bcs ngl
;		stz sprite_d+1	; turn right
;ngl:
;	ldx sprite_d+1	; direction?
;	clc
;	adc delta,x		; add displacement
;	and#127
;	sta sprite_x+1	; update
	ldy#1		; ghost index
	sty sel_gh	; draw ghost
	jsr destino		; check new destination, updating x/y and d
	jsr draw
ngh:
; try to move and draw frightened ghost
lda jiffy
cmp sprite_t+2
bmi nfh
	adc#19	; frightened ghost speed (20, as C was set)
	sta sprite_t+2
;	lda sprite_x+2	; actual X
;	cmp#85
;	bcc nfr
;		ldx#4	; turn left
;		stx sprite_d+2
;nfr:
;	cmp#24
;	bcs nfl
;		stz sprite_d+2	; turn right
;nfl:
;	ldx sprite_d+2	; direction?
;	clc
;	adc delta,x		; add displacement
;	and#127
;	sta sprite_x+2	; update
	ldy #2
	sty sel_gh	; draw frightened ghost
	jsr destino
	jsr draw
nfh:
; try to move and draw fast ghost
lda jiffy
cmp sprite_t+3
bmi nxh
	adc#0	; fast ghost speed (1, as C was set)
	sta sprite_t+3
	ldy #3
	sty sel_gh	; draw fast ghost
	jsr destino
	jsr draw
nxh:
jmp testing
delta:
.byt	1,0,0,0,$ff,0,0; ***check
destino:
; *** update path, Y = sprite index ***
ldx sprite_d,y	; current direction
recheck:
jmp(direc,x)
direc:
.word go_r, go_d, go_l, go_u
go_r:;check righmost coordinate
lda sprite_x,y	; current x
cmp#85	; right x limit
bcc d_nr
	ldx#2;now facing down
	stx sprite_d,y
	jmp recheck
d_nr:
tya
tax
inc sprite_x,x
rts

go_d:;check bottom limit
lda sprite_y,y
cmp #92;bottom y limit
bcc d_nd
	ldx#4;now facing left
	stx sprite_d,y
	jmp recheck
d_nd:
tya
tax
inc sprite_y,x
rts

go_l:;check left limit
lda sprite_x,y
cmp #26;left x limit
bcs d_nl
	ldx#6;now facing up
	stx sprite_d,y
	jmp recheck
d_nl:
tya
tax
dec sprite_x,x
rts

go_u:;check top limit
lda sprite_y,y
cmp #21;top y limit
bcs d_nu
	ldx#0;now facing right
	stx sprite_d,y
	jmp recheck
d_nu:
tya
tax
dec sprite_y,x
rts
; *** end of test code ***
; ************************

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
	CLI						; enable interrupts as will be needed for timing
	LDA IOAie				; ...and enable in hardware too! eeeeek

; *** test code follows ***
jsr death
loop:
lda jiffy
cmp lives
bne loop
pha
ldx #0
lda #1
jsr add_sc
/*ldy#5
wait:inx
bne wait
dey:bne wait
*/pla
clc
adc#244
sta lives
jmp loop
; *** end of test code ***
; ************************


; ***************************************
; *** *** restart another 'level' *** ***
; ***************************************
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots)
	JSR positions			; reset initial positions
;	JSR sprites				; draw all ghosts and pacman on screen (uses draw, in development)
; some delay is in order
	JMP play				; and begin new level (without music)

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
	RTS

; * copy the intial screen to VRAM *and* the 'clean' buffer, now including dots *
screen:
	LDY #<maze				; pointer to fresh maze (NOT page aligned)
	LDA #>maze
	STY spr_pt				; load origin pointer (temporarily)
	STA spr_pt+1
	LDY #<vram				; pointer to VRAM (page-aligned)
	LDA #>vram
	STY dest_pt				; load destination pointer
	STA dest_pt+1
#ifdef	IOSCREEN
	STA IO8lh				; preload page into high-address latch
#endif
;	LDY #<org_b				; pointer to clean buffer (Y known to be zero, as both blocks are page-aligned)
	LDA #>org_b
	STY org_pt				; load parallel destination
	STA org_pt+1
;	LDY #<d_map				; get map initial pointer, once again page-aligned
	LDA #>d_map
	STY map_pt
	STA map_pt+1
	STY cur					; save this index, as isn't valid everywhere
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
			INC dest_pt+1	; VRAM is last, as will set N flag when finished!
#ifdef	IOSCREEN
			LDA dest_pt+1	; new page value... (3)
			STA IO8lh		; ...gets into high-address latch (4)
#endif
		BPL sc_loop			; stop at $8000 (usually 3, just 8 times)
	RTS						; that's all? nice!

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
	RTS

; *** *** sprite drawing, the thing becomes interesting *** ***
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
	LDA sprite_s, Y			; copy from array to temporary var
	STA draw_s
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
	STA dest_pt
	LDA org_pt+1			; retrieve base MSB
	ORA #>vram
	STA dest_pt+1			; screen pointer is ready
	LDA org_pt+1			; retrieve base MSB, now for buffer pointer
	ORA #>org_b				; convert in full buffer address, valid for page-aligned addresses!
	STA org_pt+1
; select routine according to direction
	LDX sprite_d, Y			; this can be done directly in X as direction is to be checked right after
;	STX draw_d				; lastly, set direction (is storage actually needed?)
	JMP (sp_dir, X)			; *** CMOS only *** execute appropriate code

; ** table of pointers for sprite drawing routines **
sp_dir:
	.word	s_right
	.word	s_down
	.word	s_left
	.word	s_up

; *** routine for sprite drawing, towards left ***
s_left:
; must select sprite file first! I don't think this can be generic
	LDA sel_gh				; pacman or ghost?
	BEQ sl_pac
; if it's a ghost, must check status, as frightened (and eaten) are different
		LDA draw_s			; status of chost
		CMP #2				; 0,1=normal, 2=fright, 3=eaten
		BCS sr_frg			; normal ghost
			LDY #<s_gh_l	; facing left
			LDA #>s_gh_l
			BNE spl_set		; set this pointer
sl_frg:
; might include a FIFTH state (clear), not sure if suitable for pacman too...
;		CMP #3				; should differentiate eaten ghost
;		BEQ sl_eat
			LDY #<s_fg_l	; frightened, facing left
			LDA #>s_fg_l
			BNE spl_set
sl_eat:
;		LDY #<s_eat_l		; eaten, facing left?
;		LDA #>s_eat_l
;		BNE spl_set
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
		LDA draw_s			; status of chost
		CMP #2				; 0,1=normal, 2=fright, 3=eaten
		BCS sr_frg			; normal ghost
			LDY #<s_gh_r	; facing right
			LDA #>s_gh_r
			BNE spr_set		; set this pointer
sr_frg:
;		CMP #3				; should differentiate eaten ghost
;		BEQ sr_eat
			LDY #<s_fg_r	; frightened, facing right
			LDA #>s_fg_r
			BNE spr_set
sr_eat:
;		LDY #<s_eat_r		; eaten, facing right?
;		LDA #>s_eat_r
;		BNE spr_set
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
		DEC dest_pt			; otherwise, set both screen pointers one byte before, no page boundaries expected
		DEC org_pt
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
	LDA dest_pt+1			; eeeeeek
	STA IO8lh
	LDX dest_pt				; keep this updated
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
		STA dest_pt			; really the same MSB
		BCC sh_npb			; check possible carry
			INC org_pt+1
			INC dest_pt+1
#ifdef	IOSCREEN
			LDA dest_pt+1
			STA IO8lh
#endif
sh_npb:
#ifdef	IOSCREEN
			TYA
			CLC
			ADC dest_pt
			BCC sh_npw
				LDX dest_pt+1
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
		LDA draw_s			; status of chost
		CMP #2				; 0,1=normal, 2=fright, 3=eaten
		BCS sd_frg			; normal ghost
			LDY #<s_gh_d	; facing right
			LDX #>s_gh_d
			BNE spd_set		; set this pointer
sd_frg:
;		CMP #3				; should differentiate eaten ghost
;		BEQ sd_eat
			LDY #<s_fg_d	; frightened, facing right
			LDX #>s_fg_d
			BNE spd_set
sd_eat:
;		LDY #<s_eat_d		; eaten, facing down?
;		LDX #>s_eat_d
;		BNE spd_set
sd_pac:
; it's pacman, no status check, just direction
	LDY #<s_pac_d
	LDX #>s_pac_d
spd_set:
; org_pt and dest_pt seem OK
; *** put extra byte(s) above ***
; *** this is VERY coarse, but works anyway ***
; first, save future address
	LDA dest_pt				; LSB is common with org_pt
	SEC
	SBC #lwidth				; back one raster
	STA map_pt
	LDA dest_pt+1
	PHP						; borrow goes on two MSBs
	SBC #0
	STA map_pt+1			; map_pt is future dest_pt
	LDA org_pt+1			; this MSB is different
	PLP						; retrieve possible borrow
	SBC #0
	STA tmp_arr+15			; different storage
; with X & Y properly set, proceed to draw
	JSR sv_draw
; *** retrieve address to be cleared ***
	LDX map_pt				; common LSB must be in X for IOSCREEN
	STX org_pt
	STX dest_pt
	LDA map_pt+1			; screen MSB
	STA dest_pt+1
#ifdef	IOSCREEN
	STA IO8lh				; eeeeeeeek
#endif
	LDA tmp_arr+15			; the other MSB
	STA org_pt+1
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
		LDA draw_s			; status of chost
		CMP #2				; 0,1=normal, 2=fright, 3=eaten
		BCS su_frg			; normal ghost
			LDY #<s_gh_u	; facing right
			LDX #>s_gh_u
			BNE spu_set		; set this pointer
su_frg:
;		CMP #3				; should differentiate eaten ghost
;		BEQ su_eat
			LDY #<s_fg_u	; frightened, facing right
			LDX #>s_fg_u
			BNE spu_set
su_eat:
;		LDY #<s_eat_u		; eaten, facing up?
;		LDX #>s_eat_u
;		BNE spu_set
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
		DEC temp			; was zero or one!
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
	STA temp				; we no longer need sel_gh, I think, may use somewhere in tmp_arr as well
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
	LDA dest_pt+1			; eeeeeek
	STA IO8lh
	LDX dest_pt				; keep this updated
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
		LDA temp			; is it?
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
		STA dest_pt			; really the same MSB
		BCC sv_npb			; check possible carry
			INC org_pt+1
			INC dest_pt+1
#ifdef	IOSCREEN
			LDA dest_pt+1
			STA IO8lh
#endif
sv_npb:
#ifdef	IOSCREEN
			TYA
			CLC
			ADC dest_pt
			BCC sv_npw
				LDX dest_pt+1
				INX
				STX IO8lh
sv_npw:
			TAX				; keep this index updated
#endif
		CPY #24				; bytes per sprite frame, not 16!
		BNE sv_loop
	RTS

; * compute map data from pixel coordinates * MUST CHECK ****** TBD * TBD
chk_map:
; new interface is X=x, A=y
; input is A=suggested draw_x, X=suggested draw_y
	LSR
	LSR
	TAY						; Y=map column (one each 4 pixels)
	TXA						; this gets suggesteddraw_y
	LSR						; will get map row from A (one each 4 pixels)
	LSR
	STZ map_pt				; clear temporary variable *** CMOS ***
	LSR						; each y advances 16 bytes in table, thus divide MSB by 16
	ROR map_pt
	LSR
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

; ** alphanumeric routines ** TONS of repeated code
; * add points to score and display it *
; takes value (BCD) in A (low), X (high, only for 160 --fourth ghost eaten--)
add_sc:
; add X.A to current score
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
	STX dest_pt				; will be kept as low address
	STA dest_pt+1
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
		STA (dest_pt)		; put on this scanline *** CMOS ***
#endif
; last two digits
#ifndef	IOSCREEN
		INC dest_pt			; advance to next couple of figures
#else
		INX
		STX dest_pt
		STX IO8ll
#endif
		LDY score			; this is an index for least significant couple of figures!
		LDA (spr_pt), Y		; using this pointer to a BCD-glyph table
#ifdef	IOSCREEN
		STA IO8wr
#else
		STA (dest_pt)		; put on this scanline *** CMOS ***
#endif
		LDA dest_pt			; increase screen pointer
		CLC
		ADC #lwidth-1
		STA dest_pt
#ifdef	IOSCREEN
		TAX					; keep low order address updated
		STX IO8ll			; eeeeeeeeeeek
#endif
;		BCC ds_nnw			; should NEVER wrap, at least within the original range ($7B1C-$7B6D)
;			INC dest_pt+1
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
	RTS

; * update lives counter *
; now display it, two ciphers at a time!
up_lives:
	LDX #5
	STX temp				; use this as a scanline counter
	LDY #<bcdt				; set BCD table pointer
	LDA #>bcdt
	STY spr_pt
	STA spr_pt+1
	LDX #<lv_da				; set screen address for lives area
	LDA #>lv_da
	STX dest_pt				; will be kept as low address
	STA dest_pt+1
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
		STA (dest_pt)		; put on this scanline *** CMOS, hard to emulate in NMOS ***
#endif
		LDA dest_pt			; increase screen pointer
		CLC
		ADC #lwidth
		STA dest_pt
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
	STA draw_s
	LDA sprite_x			; pacman coordinates ·yyyyyyy ·xxxxxxx (3)
	ASL						; bit 7 unused xxxxxxx0 (2)
	LSR draw_s				; non-destructive computing (5)
	ROR						; 00yyyyyy yxxxxxxx (2+5)
	LSR draw_s
	ROR						; 000yyyyy yyxxxxxx (2+5)
	LSR draw_s
	ROR						; 0000yyyy yyyxxxxx (2+5)
	LSR draw_s
	ROR						; 00000yyy yyyyxxxx (2)
	STA dest_pt				; part of the pointer (3+3)
	STA org_pt				; nicer
	LDA draw_s
	ORA #>vram				; page aligned 01111yyy yyyyxxxx (2)
	STA dest_pt+1			; pointer complete (3)
	LDA draw_s
	ORA #>org_b
	STA org_pt+1
; must compute dest_pt accordingly
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
		INC dest_pt		; it's the second one
		INC org_pt		; nicer
		ORA (org_pt)
#ifdef	IOSCREEN
		LDX dest_pt+1	; MSB actually
		STX IO8lh
		LDX dest_pt		; this is LSB
		STX IO8ll
		STA IO8wr		; store this
#else
		STA (dest_pt)	; ** CMOS **
#endif
		LDA cur			; retrieve first byte
		DEC dest_pt		; back one byte
		DEC org_pt
		ORA (org_pt)
sh_end:
#ifdef	IOSCREEN
		LDX dest_pt+1	; MSB actually
		STX IO8lh
		LDX dest_pt		; this is LSB
		STX IO8ll
		STA IO8wr		; store this
#else
		STA (dest_pt)	; ** CMOS **
#endif
		LDA dest_pt
		CLC
		ADC #lwidth		; next line
		STA dest_pt		; eeeek
		STA org_pt		; is this OK?
		BCC af_nw
			INC dest_pt+1
			INC org_pt+1
#ifdef	IOSCREEN
			LDA dest_pt+1
			STA IO8lh
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
	SEI						; interrupts disabled for sound
	LDA #40					; one second pause
	JSR ms25
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
	LDA #$FF				; "add" -1 lives...
	TAX
	JSR up_lives
; check for gameover
	LDA lives
	BNE nx_liv
; *** game is over *** TBD
nx_liv:
	LDA #60
	JSR ms25				; one-and-a-half seconds delay before next live
	CLI
	RTS

; *** ** beeping routine ** ***
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
; modifies Y, returns X=0
m_beep:
	SEI						; eeeeeek
beep_l:
		TAY					; determines frequency (2)
		STX $BFF0			; send X's LSB to beeper (4)
rb_zi:
			DEY				; count pulse length (y*2)
			BNE rb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE beep_l			; new half cycle (3)
	STX $BFF0				; turn off the beeper!
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
	LDA #179
	LDX #4
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

; initial positions (note order is pac_x, pac_y, pac_dir and the respective arrays with ghost # as index
; ghost arrays (1...4) are blinky, pinky, inky and clyde, with pacman first (index 0)
; blinky is outside the base at startup
; note horizontal 2-px offset to make maze into 4-px boundaries at least
; vertical movements of ghosts inside the base should be ad hoc
init_p:
	.byt	54, 54, 54, 46, 62	; sprites initial X (2px offset, note "wrong" intial values)
	.byt	92, 92, 92, 92, 56	; sprites initial Y (new 2px offset, not much of a problem)****
;	.byt	92, 44, 56, 56, 56	; sprites initial Y (new 2px offset, not much of a problem)
	.byt	 4,  4,  4,  4,  4	; ***sprites initial direction (times two)
;	.byt	 0,  4,  6,  6,  6	; sprites initial direction (times two)
	.byt	 0,  0,  1,  0,  0	; ghosts initial state (nonsense for pacman)***testing 

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
	.dsb	16, 0			; mandatory padding

; BCD glyph pair tables
; each scanline, then 100 values from $00 to $99
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
	.bin	57, 2048, "../../other/data/maze2.pbm"	; *** check new offset or resave file!

; *** sprites ***
; pacman towards right
s_pac_r:
	.bin	9, 128, "../../other/data/pac-right.pbm"
; pacman downwards *** uses new scheme for vertical!
s_pac_d:
	.bin	9, 192, "../../other/data/pac-down.pbm"
; pacman towards left
s_pac_l:
	.bin	55, 128, "../../other/data/pac-left.pbm"
; pacman upwards
s_pac_u:
	.bin	9, 192, "../../other/data/pac-up.pbm"
; pacman dies! (animation)
pac_dies:
	.bin	53, 48, "../../other/data/palmatoria.pbm"
	.dsb	8, 0			; mandatory end padding
; ghost towards right
s_gh_r:
	.bin	9, 128, "../../other/data/ghost-right.pbm"
; ghost downwards
s_gh_d:
	.bin	9, 192, "../../other/data/ghost-down.pbm"
; ghost towards left
s_gh_l:
	.bin	55, 128, "../../other/data/ghost-left.pbm"
; ghost upwards
s_gh_u:
	.bin	9, 192, "../../other/data/ghost-up.pbm"
; frightened ghost towards right
s_fg_r:
	.bin	9, 128, "../../other/data/fright-right.pbm"
; frightened ghost downwards ***
s_fg_d:
; frightened ghost towards left
s_fg_l:
	.bin	9, 128, "../../other/data/fright-left.pbm"
; frightened ghost upwards ***
s_fg_u:

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
