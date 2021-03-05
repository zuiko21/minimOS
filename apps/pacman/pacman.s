; PacMan for Tommy2 breadboard computer!
; hopefully adaptable to other 6502 devices
; (c) 2021 Carlos J. Santisteban
; last modified 20210305-1300

; can be assembled from this folder

; variables, esp. zeropage
#include "pacman.h"

; *** constants definitions ***
	fw_isr	= $200			; standard minimOS address
	vram	= $7800			; suitable for Tommy2
	sc_da	= vram + $31C	; address for score display, usually $7B1C
	lv_da	= vram + $49D	; address for lives display, usually $7C9D
	bytlin	= 16			; bytes per line, being a power of two makes things MUCH simpler!
	IO8lh	= $8000			; I/O addresses
	IO8ll	= $8001
	IO8wr	= $8003

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

	LDY #<pm_isr			; set interrupt vector
	LDA #>pm_isr
	STY fw_isr				; standard minimOS address
	STA fw_isr+1

; perhaps is time to init data...
	INX						; gets a zero (X known to be zero)
	STX score				; reset score
	STX score+1
	STX score+2
	LDA #5					; initial lives
	STA lives

; initial screen setup, will be done every level as well
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots), may modify X
	JSR positions			; reset initial positions, X is zero but...
	JSR sprites				; draw all ghosts and pacman on screen (uses draw, in development)

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
level:
	CLI						; enable interrupts as will be needed for timing

; ***************************************
; *** *** restart another 'level' *** ***
; ***************************************
	JSR newmap				; reset initial map
	JSR screen				; draw initial field (and current dots)
	JSR positions			; reset initial positions
	JSR sprites				; draw all ghosts and pacman on screen (uses draw, in development)
; some delay is in order
	JMP level				; and begin new level (without music)

; ***************************
; ***************************
; *** supporting routines ***
; ***************************
; ***************************

; * preload map with initial state *
; will just copy 1Kbyte, don't bother with individual coordinates (10.5 ms)
; returns X=0, modifies A
newmap:
	LDX #0
nm_loop:
		LDA i_map, X		; get initial data
		STA d_map, X		; copy into RAM
		LDA i_map+256, X	; ditto for remaining pages
		STA d_map+256, X
		LDA i_map+512, X
		STA d_map+512, X
		LDA i_map+768, X
		STA d_map+768, X	; eeeeeek
		INX
		BNE nm_loop
	RTS

; * copy the intial screen to VRAM *and* the 'clean' buffer (w/o dots, about 62 ms @ 1 MHz w/IO, or 45 ms direct) *
; first part ends with Y=0, A modified
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
	STA IO8lh				; preload page into high-address latch
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
		STY IO8ll			; low-address latch (4)
		STA IO8wr			; actual data transfer (4)
#endif
		INY					; (2)
		BNE sc_loop			; (usually 3 for 255 times, then 2)
			INC spr_pt+1	; page crossing (5+5+5)
			INC org_pt+1
			INC dest_pt+1	; VRAM is last, as will set N flag when finished!
#ifdef	IOSCREEN
			LDA dest_pt+1	; new page value... (3)
			STA IO8lh		; ...gets into high-address latch (4)
#endif
		BPL sc_loop			; (usually 3, just 8 times)
; now place dots according to current map (not yet timed, but around 80-100ms)
; placing the pills offset to the left will be @d654 and @d210...
; ...no byte boundaries crossed, and doesn't look THAT bad!
; as for the pill's 3 bytes, there cannot be page crossing backwards, but it's likely to happen otherwise!
; must store into buffer too! eeeeeeek!
; modifies A & Y (and X if IOSCREEN)
placedots:
	LDY #<d_map				; get initial pointer
	LDA #>d_map
	STY map_pt
	STA map_pt+1
;	LDY #<org_b				; pointer to buffer (Y known to be zero, as both blocks are page-aligned)
	LDA #>org_b
	STY org_pt				; load parallel destination
	STA org_pt+1
;	LDY #<vram				; pointer to VRAM (LSB known to be zero)
	LDA #>vram
	STY dest_pt				; load destination pointer
	STA dest_pt+1
#ifdef	IOSCREEN
	STA IO8lh				; preload page into high-address latch
#endif
dp_loop:
		LDA map_pt			; tile offset from lowest bits of pointer
		AND #31
		TAY
		LDA (map_pt), Y		; get info for current tile
		ASL					; check d7 (wall)
		BCC dp_dot
			JMP dp_next		; wall, nothing to be added
dp_dot:
		ASL					; check d6 (standard dot)
		BCC dp_pill			; no? try some pill
; add a regular dot
			TYA				; check X-coord
			LSR				; is it even or odd tile? 
			TAY				; also now proper byte index! eeeeek
			LDA #1			; mask originally with d0 set (odd)
			BCS dp_set		; if was even...
				LDA #16		; ...set d4 instead
dp_set:
			ORA (dest_pt), Y	; mix with original data
			STA (dest_pt), Y	; update screen
			STA (org_pt), Y	; and buffer too! eeeeeeek
#ifdef	IOSCREEN
; worth inlining as dots are frequently put
			TAX				; keep this value
			TYA				; get screen offset
			CLC
			ADC dest_pt		; compute final address -- no way any offset could cross page boundaries, IF page-aligned
			STA IO8ll		; latch low address...
			STX IO8wr		; ...and transfer data
#endif
			JMP dp_next
dp_pill:
		ASL					; check d5 (pill)
		BCC dp_next			; just an empty tile
; add a pill
; first get screen pointer back (no wrapping ever!), then will advance one raster (w/o wrap) and lastly the third advance which may cross page
			LDA dest_pt
			SEC
			SBC #bytlin		; get one raster up (can't wrap!)
			STA dest_pt
			STA org_pt		; buffer too! eeeeeek
; continue with screen insertion, but thrice
; since the only difference between odd and even tiles is the bit positions, let's make a mask for them
			TYA				; check X
			LSR				; is it even or odd tile? 
			TAY				; also now proper byte index! eeeeek
			LDA #7			; original mask sets d0-2
			BCS dp_pset		; if was even...
				LDA #$70	; ...set d4-6 instead
dp_pset:
			STA temp		; store mask temporarily
; now it's time to modify the three bytes in sequence, checking for wrap in the last one
; first one, mask already in A
			ORA (dest_pt), Y	; mix with original data in the upper raster
			STA (dest_pt), Y
			STA (org_pt), Y	; and buffer too! eeeeeeek
#ifdef	IOSCREEN
			JSR io_off		; not worth inlining, as is much less frequently called
#endif
			LDA dest_pt
			CLC
			ADC #bytlin		; get back to original raster (can't wrap either!)
			STA dest_pt
			STA org_pt		; same with buffer! eeeeeek
; second one
			LDA temp		; retrieve mask
			ORA (dest_pt), Y	; mix with original data in the upper raster
			STA (dest_pt), Y
			STA (org_pt), Y	; and buffer too! eeeeeeek
#ifdef	IOSCREEN
			JSR io_off		; not worth inlining, as is much less frequently called
#endif
			LDA dest_pt
			CLC
			ADC #bytlin		; get one raster down (but check for wrap!)
			STA dest_pt
			STA org_pt		; eeeeek
			BCC pd_nw		; worth checking wrap this way, as two MSBs are to be updated!
				INC dest_pt+1
				INC org_pt+1	; eeeeeek
pd_nw:
#ifdef	IOSCREEN
			LDA dest_pt+1	; worth it
			STA IO8lh		; MSB was updated
#endif
; last one
			LDA temp		; retrieve mask
			ORA (dest_pt), Y	; mix with original data in the upper raster
			STA (dest_pt), Y
			STA (org_pt), Y	; and buffer too! eeeeeeek
#ifdef	IOSCREEN
			JSR io_off		; not worth inlining, as is much less frequently called
#endif
; worth computing back the standard address, faster than using the stack!
			LDA dest_pt
			SEC
			SBC #bytlin		; get one raster up (but check for wrap!)
			STA dest_pt
			BCS pb_nw
				DEC dest_pt+1
				DEC org_pt+1	; eeeeek
pb_nw:
#ifdef	IOSCREEN
			LDA dest_pt+1	; worth it
			STA IO8lh		; MSB was updated
#endif
dp_next:
; advance screen address, pretty much the same but four rasters
			LDA dest_pt
			CLC
			ADC #bytlin*4		; get four rasters down (but check for wrap!)
			STA dest_pt
			BCC pd_adv		; better this way
				INC dest_pt+1
				INC org_pt+1	; eeeeeek
pd_adv:
#ifdef	IOSCREEN
			LDA dest_pt+1	; worth it
			STA IO8lh		; MSB was updated
#endif
; update tile coordinates
		INC map_pt			; next tile coordinate
		LDA map_pt
		AND #31				; check lowest bits, which are offset
		CMP #28				; check X offset is valid
		BEQ dp_tnw			; it is, do not advance line
dp_rpt:
			JMP dp_loop		; continue if so
dp_tnw:
		LDA map_pt			; or advance tile row otherwise
		ADC #3				; next row, C known to be SET because of BEQ!
		STA map_pt
		LDA map_pt+1
		ADC #0				; propagate carry (better this way, not INC)
		STA map_pt+1
		CMP #>(d_map+992)	; within range?
			BNE dp_rpt
		LDA map_pt
		CMP #<(d_map+992)	; really within range?
			BNE dp_rpt
	RTS						; otherwise we're done!

; * store A thru IO8 with offset Y *
#ifdef	IOSCREEN
io_off:
; not worth inlining for pills
	TAX						; keep this value
	TYA						; get screen offset
	CLC
	ADC dest_pt				; compute final address -- no way any offset could cross page boundaries, IF page-aligned
	STA IO8ll				; latch low address...
	STX IO8wr				; ...and transfer data
	RTS
#endif

; * reset initial positions *
; returns X=0, modifies A
positions:
	LDX #20					; 5 sprites x 4 coordinates/stati
ip_loop:
		LDA init_p-1, X		; get data from tables, note offsets
		STA sprite_x-1, X	; into ZP variables
		DEX
		BNE ip_loop
	RTS

; * draw all sprites *
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
draw:
	LDY sel_gh				; get selected sprite
	LDA sprite_x, Y			; copy from array to temporary var
	STA draw_x
	LDA sprite_y, Y
	STA draw_y
	LDA sprite_s, Y
	STA draw_s
	LDX sprite_d, Y			; this can be done directly in X as direction is to be checked right after
;	STX draw_d				; lastly, set direction (is storage actually needed?)
	JMP (sp_dir, X)			; *** CMOS only *** execute appropriate code
sp_dir:
	.word	sd_right		; table of pointers for sprite drawing routines
	.word	sd_down
	.word	sd_left
	.word	sd_up

; * routine for sprite drawing, towards right * MUST CHANGE
sd_right:
	JSR comp_y				; compute base screen pointer from draw_y! eeeeek
	LDY draw_x				; get parameters for chk_map
	INY						; try one pixel to the right
	TYA
	LDX draw_y
	JSR chk_map				; check status of suggested tile
	BMI sr_abort			; do nothing if wall *** might check for ghost base
		;***check dot/pill (perhaps in chk_map)
		INC draw_x			; one pixel to the right
		LDA draw_x
		AND #7				; bit within byte
		CMP #1				; if it's 1, it just advanced a byte
		BNE sr_nb
			LDY org_pt		; if wrapped, advance one byte
			INY
			STY org_pt
			STY dest_pt
			BNE sr_nb		; page boundary crossing, really needed?
				INC org_pt+1
				INC dest_pt+1
sr_nb:
#ifdef	IOSCREEN
		LDY dest_pt+1		; this needs to be ready always
		STY IO8lh
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
			STX IO8ll			; latch low address, high byte was already done
			STA IO8wr			; copy data on screen!
#endif
			INY					; advance to adjacent byte in both sprite and screen
			LDA (org_pt), Y		; ditto with this second byte, get clean data
			ORA (spr_pt), Y		; put sprite data on it
			STA (dest_pt), Y	; and place it on screen
#ifdef	IOSCREEN
			LDX dest_pt			; eeeeeeeek must get this pointer
			STX IO8ll			; latch low address, high byte was already done
			STA IO8wr			; copy data on screen!
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
				STX IO8lh
#endif
sr_nw:
			CPY #16				; until sprite file is done
			BNE sr_loop
sr_abort:
	RTS

; * routine for sprite drawing, downwards -- needs a VERY different approach! *
sd_down:
	LDA draw_x				; get parameters for chk_map
	LDX draw_y
	INX						; try one pixel down
	JSR chk_map				; check status of suggested tile
	BMI sd_abort

sd_abort:
	RTS

; * routine for sprite drawing, towards left * ADAPT FROM RIGHT ONCE FINISHED
sd_left:
	LDY draw_x				; get parameters for chk_map
	DEY						; try one pixel to the left
	TYA
	LDX draw_y
	JSR chk_map				; check status of suggested tile
	BMI sl_abort
		;***check dot/pill (perhaps in chk_map)
		DEC draw_x			; one pixel to the right
		LDA draw_x
		AND #7				; bit within byte
		CMP #7				; check reverse wrap
		BNE sl_nb
			LDY org_pt		; if wrapped, back one byte
			DEY
			STY org_pt
			STY dest_pt
			CPY #$FF
			BNE sl_nb		; page boundary crossing
				DEC org_pt+1
				DEC dest_pt+1
sl_nb:
#ifdef	IOSCREEN
		LDY dest_pt+1		; this needs to be ready always
		STY IO8lh
#endif
		ASL					; each pixel displacement takes 16 bytes of sprite file
		ASL
		ASL
		ASL
		CLC
		ADC spr_pt			; add to selected sprite file base address
		STA spr_pt
		BCC sl_now			; check for wrapping in sprite file
			INC spr_pt+1
sl_now:
		LDY #0				; reset sprite byte counter
sl_loop:
			LDA (org_pt), Y		; get clean data
			ORA (spr_pt), Y		; put sprite data on it
			STA (dest_pt), Y	; and place it on screen
#ifdef	IOSCREEN
			LDX dest_pt			; eeeeeeeek must get this pointer
			STX IO8ll			; latch low address, high byte was already done
			STA IO8wr			; copy data on screen!
#endif
			INY					; advance to adjacent byte in both sprite and screen
			LDA (org_pt), Y		; ditto with this second byte, get clean data
			ORA (spr_pt), Y		; put sprite data on it
			STA (dest_pt), Y	; and place it on screen
#ifdef	IOSCREEN
			LDX dest_pt			; eeeeeeeek must get this pointer
			STX IO8ll			; latch low address, high byte was already done
			STA IO8wr			; copy data on screen!
#endif
			INY					; prepare for next entry
			LDA org_pt			; advance screen pointers... backing off a bit as the index increases!
			CLC
			ADC #14				; must subtract the two processed entries on sprite file
			STA org_pt
			STA dest_pt			; VRAM pointer too
			BCC sl_nw
				INC org_pt+1	; page wrapping
				INC dest_pt+1
#ifdef	IOSCREEN
				LDX dest_pt+1
				STX IO8lh
#endif
sl_nw:
			CPY #16				; until sprite file is done
			BNE sl_loop
sl_abort:
	RTS

; * routine for sprite drawing, upwards -- needs a VERY different approach! *
sd_up:
	LDA draw_x				; get parameters for chk_map
	LDX draw_y
	DEX						; try one pixel up
	JSR chk_map				; check status of suggested tile
	BMI su_abort

su_abort:
	RTS

; * compute base screen pointer from draw_y *
; returns MSB in A
comp_y:
	LDA draw_y				; original row
	STA dest_pt				; will be shifted
	LDA #0					; clear MSB
	ASL dest_pt				; this screen is 16 bytes/line
	ROL						; MSB gets loaded...
	ASL dest_pt
	ROL
	ASL dest_pt
	ROL
	ASL dest_pt
	ROL						; ...after four shifts
	CLC
	ADC #>vram				; add base address
	STA dest_pt+1
	RTS

; * compute offset from draw_x (after calling comp_y, I presume) *
; returns full LSB in A
comp_x:
	LDA draw_x				; original column
	LSR						; will shift 4 times...
	LSR
	LSR
	LSR						; ...as this screen is 16 bytes/line
	ORA dest_pt				; MSN is expected to be set!
	STA dest_pt
	RTS

; * compute map data from pixel coordinates *
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
		STA (dest_pt)		; put on this scanline *** CMOS ***
#ifdef	IOSCREEN
		STA IO8wr
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
		STA (dest_pt)		; put on this scanline *** CMOS ***
#ifdef	IOSCREEN
		STA IO8wr
#endif
		LDA dest_pt			; increase screen pointer
		CLC
		ADC #bytlin-1
		STA dest_pt
#ifdef	IOSCREEN
		TAX					; keep low order address updated
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
		STA (dest_pt)		; put on this scanline *** CMOS, hard to emulate in NMOS ***
#ifdef	IOSCREEN
		STA IO8wr
#endif
		LDA dest_pt			; increase screen pointer
		CLC
		ADC #bytlin
		STA dest_pt
#ifdef	IOSCREEN
		TAX					; keep low order address updated
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

; *** sound effects ***

; *** ** beeping routine ** ***
; *** X = length, A = freq. ***
; *** tcyc = 10 A + 20      ***
; modifies Y, returns X=0
m_beep:
		TAY					; determines frequency (2)
		STX $BFF0			; send X's LSB to beeper (4)
rb_zi:
			DEY				; count pulse length (y*2)
			BNE rb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE m_beep			; new half cycle (3)
	STX $BFF0				; turn off the beeper!
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

; **************************************************************
; * sound after pacman dies (must be combined with animation!) *
death:
; these are the parts to be called
	LDA #99		; initial freq
	LDY #88		; top freq
	LDX #36		; length
	JSR squeak	; actual routine
	LDA #118
	LDY #105
	LDX #30
	JSR squeak
	LDA #132
	LDY #117
	LDX #27
	JSR squeak
	LDA #148
	LDY #132
	LDX #24
	JSR squeak
	LDA #176
	LDY #157
	LDX #20
	JSR squeak
; last two sweeps
	LDA #2
	PHA						; iteration
d_rpt:
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
	JSR ms74
; next iteration
	PLA
	DEC						; *** CMOS ***
	BNE d_rpt
; **************************************************************

; ~74 ms delay
; expects X=0, returns X=Y=0
ms74:
;	LDX #0					; not needed if called after m_beep
	LDY #198
dly74:
			INX
			BNE dly74
		INY
		BNE dly74
	RTS

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
	PHA
	LDA $9FF0				; get input port
	STA stick				; store in variable
	PLA
	INC jiffy				; count time
		BNE i_end
	INC jiffy+1
		BNE i_end
	INC jiffy+2
i_end:
	RTI

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
	.bin	11, 2048, "../../other/data/maze.pbm"

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

; NOTE, in scatter mode, targets are
; pinky = tile(2,-4)
; blinky = tile(25,-4)
; clyde = tile(0,31)
; inky = tile(27,31)

; in chase mode, targets are
; blinky = PACMAN
; pinky = L(-4,+0), D(+0,+4), R(+0,+4), U(-4,-4)!
; inky = pre L(-2,0), D(0,2), R(0,2), U(-2,-2), extended by blinky...
; clyde = PACMAN [d>8]; tile(0,31) [d<=8]
