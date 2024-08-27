; COLUMNS for Durango-X
; original idea by SEGA
; (c) 2022-2024 Carlos J. Santisteban
; last modified 20240827-1511

; add -DMAGIC to increase magic jewel chances

; ****************************
; *** hardware definitions ***
; ****************************

screen3	= $6000
IO8attr	= $DF80
IO8blk	= $DF88
IO9kbd	= $DF9B
IO9nes0	= $DF9C
IO9nlat	= IO9nes0
IO9nes1	= $DF9D
IO9nclk	= IO9nes1
IOAie	= $DFA0
IOBeep	= $DFB0
IO_PSG	= $DFDB				; PSG for optional effects and background music

; ****************************
; *** constant definitions ***
; ****************************
; * controls *
#define	PAD_BUTTONS
#define	PAD_FIRE	%10000000
#define	PAD_STRT	%01000000

#define	PAD_B		%00100000
#define	PAD_SEL		%00010000
#define	PAD_UP		%00001000
#define	PAD_LEFT	%00000100
#define	PAD_DOWN	%00000010
#define	PAD_RGHT	%00000001

; * direction flag *
#define	MOV_LEFT	2
#define	MOV_RGHT	0
#define	MOV_DOWN	1
#define	MOV_ROT		3
#define	MOV_NONE	3

; * screen addresses *
#define	FIELD_PG	$63
#define	BANNER_PG	$6C

#define	RST_BYT		64

; * score display type *
#define	DISP_LVL	0
#define	DISP_JWL	1
#define	DISP_SCO	2

; * compressed pictures indices (always even) *
#define	SC_INTRO	0
#define	SC_FIELD	2

; * renumbered status indices (best if even) *
#define	STAT_OVER	0
#define	STAT_LVL	2
#define	STAT_PLAY	4
#define	STAT_CRSH	6
#define	STAT_CHK	8
#define	STAT_HCHK	10
#define	STAT_VCHK	12
#define	STAT_SLCK	14
#define	STAT_BSCK	16
#define	STAT_BLNK	18
#define	STAT_EXPL	20
#define	STAT_DROP	22
#define	STAT_PAUS	24
#define	STAT_DIE	26

; * some game constants *
#define	NUM_LVLS	3

#define	JWL_COL		3

#define	NUM_JWLS	10

#define	MAGIC_JWL	7

; number of jewels for next level (1-byte BCD)
#define	GOAL		$50

; player array offset
#define	PLYR_OFF	128

; * tile/column size *
; tile height in pixels
#define	TIL_HGT		8
; column height in pixels (actually JWL_COL*TIL_HGT)
#define	COL_HGT		24
; tile width in bytes
#define	TIL_WDT		4

; banner width in bytes (actually TIL_WDT*ROW_WDT)
#define	BAN_WDT		24
; banner height in pixels
#define	BAN_HGT		22

; * notable positions on matrix *
; last visible cell
#define	LAST_V		118
; bottom left cell (actually LAST_V-5)
#define	BOTT_L		113
; first visible row
#define	VTOP_L		16
; bottom sentinel row
#define	LASTROW		120

; starting column for new pieces
#define	INIT_COL	4
; offset between rows
#define	ROW_OFF		8
; visible cells in row
#define	ROW_WDT		6

; * animation parameters *
; magic jewel animation speed (MUST be one less a power of two!)
#define	MJ_UPD		31
; cycles for blink animation and spacing between them
#define	BLINKS		8
#define	BL_SPC		12
; explosion rate
#define	EXP_SPD		16
; column drop rate
#define	CDROP_T		2
; die animation period
#define	DIE_PER		10

; * other timings *
; mask for down key repeat rate (MUST be one less a power of two!)
#define	DMASK		7
; peñonazo cycles and time between pulses
#define	P_CYC		5
#define	P_PER		4

; *************************
; *** memory allocation ***
; *************************
; player-1 data (player 2 has 128-byte offset)
status	= 64				; player status
speed	= status+1			; 7-bit value between events (127 at level 0, halving after that, but never under 5?)
ev_dly	= speed+1			; 8-bit counter for next event (ditto)
s_level	= ev_dly+1			; selected difficulty
pad0mask= s_level+1			; gamepad masking values
pad0val	= pad0mask+1		; gamepad current status
padlast	= pad0val+1			; last pad status
column	= padlast+1			; current column
next_c	= column+3			; next piece
posit	= next_c+3			; position in 8x16 matrix
oldposit= posit+1			; old position
bcd_arr	= oldposit+1		; level/jewels/score arrays [LJJSSS] in BCD, big endian
anim	= bcd_arr+6			; base row for death and other animations
phase	= anim+1			; current animation coordinate (formerly Y and die_y)
mag_col	= phase+1			; specific magic jewel colour animation
dr_mj	= mag_col+1			; flag (d7) if magic jewel is dropped / show or hide tile during blink
match_c	= dr_mj+1			; match counter
cycle	= match_c+1			; check round
goal	= cycle+1			; jewel count for next level, big-endian BCD (JJ)
delta	= goal+2			; temporary score (binary)
; common data (non-duplicated)
tempx	= delta+2			; now another temporary
temp	= tempx+1
select	= temp+1			; player index for main loop
bcd_lim	= select+1
colour	= bcd_lim+1
seed	= colour+1			; PRNG seed
; * these NEED to be on zeropage *
src		= seed+2
ptr		= src+2
; these save a few bytes and cycles in ZP
; irq_ptr and ticks(h) no longer here
kbd_ok	= ptr+2				; if non-zero, supported keyboard has been detected
col_sel	= kbd_ok+1			; keyboard column counter
; * these probably common, but will need indexing if multi-threaded *
htd_out	= col_sel+1			; 3-byte output
mult	= htd_out+3			; 16-bit temporary multiply
mul8	= mult+2			; 8-bit factor
; player 2 data for convenience
status2	= status+PLYR_OFF	; player status (this is usually 192)
speed2	= status2+1			; 7-bit value between events (127 at level 0, halving after that, but never under 5?)
ev_dly2	= speed2+1			; 8-bit counter for next event (ditto)
s_level2= ev_dly2+1			; selected difficulty
pad1mask= s_level2+1		; gamepad masking values
pad1val	= pad1mask+1		; gamepad current status
padlast2= pad1val+1			; last pad status
column2	= padlast2+1		; current column
next_c2	= column2+3			; next piece
posit2	= next_c2+3			; position in 8x16 matrix
oldpos2 = posit2+1			; old position in 8x16 matrix
bcd_arr2= oldpos2+1			; level/jewels/score arrays [LJJSSS] in BCD, big endian
anim2	= bcd_arr2+6		; base row for death animation
phase2	= anim2+1			; current death animation index (formerly Y)
mag_col2= phase2+1			; specific magic jewel colour animation
dr_mj2	= mag_col2+1		; flag (d7) if magic jewel is dropped
match_c2= dr_mj2+1			; match counter
cycle2	= match_c2+1		; check round
goal2	= cycle2+1			; jewel count for next level, big-endian BCD (JJ)
delta2	= goal2+2			; temporary score (binary)

_end_zp	= delta2+2

; these MUST be outside ZP, change start address accordingly
irq_ptr	= $0200				; for Pocket compatibility
nmi_ptr	= $0202
ticks	= $0206				; standard address, although 8-bit only
ticks_l	= $0207				; older timer for compatibility
field	= $0400				; 8x16 (6x13 visible) game status arrays (player2 = +128)
field2	= $0480
mark	= $0500				; tile match register, mimics the game arrays (player2 = +128)
mark2	= $0580

; *****************
; *** main code ***
; *****************

#ifdef	POCKET
* = $0800					; standard pocket address
#else
* = $C000					; will 16K suffice?
#endif

rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
#ifdef	POCKET
	.asc	"pX"			; pocket executable
	.word	rom_start		; load address
	.word	reset			; execution address
#else
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
#endif
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Columns", 0	; C-string with filename @ [8], max 238 chars
	.asc	"Original idea by SEGA", 0	; comment with IMPORTANT attribution

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1046			; 1.0b6		%vvvvrrrr sshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$4A00			; time, 09.16		0100 1-010 000-0 0000
	.word	$591B			; date, 2024/8/27	0101 100-1 000-1 1011
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	file_end-rom_start			; actual executable size
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

reset:
	SEI						; usual 6502 init
	CLD
	LDX #$FF
	TXS
; Durango-X specifics
	STX IOAie				; enable interrupts, as X is an odd value
	LDA #$38				; colour mode, screen 3, RGB
	STA IO8attr				; set video mode
; show splash screen
;	LDX #SC_INTRO			; actually 0
	INX						; was $FF, now 0 is the index of compressed file entry
	JSR dispic				; decompress!
; * init game stuff * actually whole ZP
	LDX #0					; reset index, as dispic affects all
rst_loop:
		STZ 0, X			; was status, X [CMOS only, use TXA/STA otherwise]
		INX
		BNE rst_loop
; setup controllers etc (assume minstrel-type kbd)
	JSR read_pad			; get initial values (mask variables already reset)
	LDX pad0val
	LDY pad1val
	STX pad0mask			; ...and store them
	STY pad1mask
	JSR read_pad			; just for clearing the values
; check here for supported keyboard presence (col 6 = $2C)
	LDA #%00100000			; sixth column (set PD5)
	STA IO9kbd
	LDA IO9kbd				; check ID value
	CMP #$2C				; standard 5x8 kbd
	BNE no_kbd				; if present...
		STA kbd_ok			; ...enable for ISR (otherwise was zero)
no_kbd:
; setup interrupt system
	LDY #<isr
	LDX #>isr				; ISR address
	STY irq_ptr				; standard FW adress
	STX irq_ptr+1
	LDY #<reset
	LDX #>reset				; warm start address
	STY nmi_ptr
	STX nmi_ptr+1			; set standard pointer
	CLI						; enable interrupts!
; let at least one player start the game
	JSR continue			; wait for user action
	LDA ticks
	STA seed
	STY seed+1				; quite random seed
	STX select				; save selected player
; display game field
	LDX #SC_FIELD			; set compressed file index
	JSR dispic				; decompress!
; then level selection according to player
	LDX select				; retrieve selected player
	LDA #STAT_LVL
	STA status, X			; set new status
	JSR sel_ban

; *******************************
; *** *** main event loop *** ***
; *******************************
loop:
	LDX select				; check player...
	LDY pad0val, X			; ...and its controller status
	BNE chk_stat			; some buttons were pressed
		STZ padlast, X		; otherwise clear that
chk_stat:
	LDA status, X			; check status of current player
; * * STATUS 0, game over * *
;	CMP #STAT_OVER			; not needed if STAT_OVER is zero
	BNE not_over
		TYA					; get this player controller status
		BIT #PAD_FIRE|PAD_B|PAD_SEL|PAD_STRT	; start new game
			BEQ not_over	; not if not pressed...
		CMP padlast, X
			BEQ not_over	; ...or not just released
		STA padlast, X		; anyway, register this press
		LDA #STAT_LVL
		STA status, X		; go into selection status
		JSR sel_ban			; after drawing level selection menu
not_over:
	LDA status, X			; check status of current player EEEEK
; * * LVL STATUS, level selection * *
	CMP #STAT_LVL			; selecting level?
		BEQ do_lvl
	JMP not_lvl
do_lvl:
; selecting level, check up/down and fire/select/start
		LDA pad0val, X		; ...and its controller status for proper operation
		BIT #PAD_DOWN		; increment level
		BEQ not_s1d			; not if not pressed
			CMP padlast, X	; still pressing?
		BEQ not_lvl			; ignore either!
			STA padlast, X	; anyway, register this press
			JSR inv_row		; deselect current
			INC s_level, X	; increment level
			LDY s_level, X
			CPY #NUM_LVLS	; three levels only, wrap otherwise
			BNE s1_nw
				STZ s_level, X
				BRA s1_nw	; common ending
not_s1d:
		BIT #PAD_UP			; decrement level
		BEQ not_s1u
			CMP padlast, X	; still pressing?
		BEQ not_lvl			; ignore!
			STA padlast, X	; anyway, register this press
			JSR inv_row		; deselect current
			DEC s_level, X	; decrement level
			BPL s1_nw		; wrap if negative
				LDA #NUM_LVLS-1					; max level index
				STA s_level, X
				BRA s1_nw	; common ending
not_s1u:
		BIT #PAD_FIRE|PAD_B|PAD_SEL|PAD_STRT	; select current level
		BEQ not_lvl
; level is selected, set initial score and display
			CMP padlast, X	; still pressing?
		BEQ not_lvl			; ignore!
			STA padlast, X	; anyway, register this press
; set initial parameters
			LDY s_level, X	; selected difficulty
			LDA ini_lbin, Y	; get level accordingly
			TAY				; level index 0, 5 or 10
			LDA ini_spd, Y	; proper speed for this level
			STA speed, X	; eeeeek
			LDY s_level, X	; selected difficulty again
			LDA ini_lev, Y	; level BCD as index for initial value
			PHA				; later...
			LDA ini_score, Y
			STA bcd_arr+3, X			; score counter eeeeek
			LDA ini_sc_l, Y
			STA bcd_arr+4, X
			STZ bcd_arr+5, X			; clear this one too!
			PLA
			STA bcd_arr, X				; place initial values in adequate array indices
			STZ bcd_arr+1, X
			STZ bcd_arr+2, X			; reset jewel counter as well
			LDA #GOAL
			STA goal+1, X	; set jewel goal for next level
			STZ goal, X
			LDY #DISP_LVL
			JSR numdisp
			LDY #DISP_JWL
			JSR numdisp
			LDY #DISP_SCO
			JSR numdisp		; display all values
; and go into playing mode
			JSR clearfield	; init game matrix and all gameplay status
			LDA speed, X	; eeeeek
			CLC
			ADC ticks
			STA ev_dly, X	; compute delay until next event
			LDA #STAT_PLAY
			STA status, X
; TODO * I believe some screen init is needed here * TODO
			BRA not_lvl
s1_nw:
		JSR inv_row			; mark new value
not_lvl:
	LDA status, X
; * * PLAY STATUS * *
	CMP #STAT_PLAY			; playing?
		BEQ is_play 
	JMP not_play
is_play:
		LDA pad0val, X		; restore and continue evaluation * must be here
		BIT #PAD_STRT		; START will make pause
		BEQ not_pstart
; ** ** TO DO * PAUSE * TO DO ** **

			LDA #STAT_PAUS
			STA status, X
			JMP not_play
not_pstart:
		BIT #PAD_LEFT		; move to the left?
		BEQ not_pleft		; not if not pressed
			CMP padlast, X	; still pressing?
			BNE is_pleft 
		JMP not_pfire		; ignore either, but keep going down!
is_pleft:
			STA padlast, X	; anyway, register this press
			LDY #MOV_LEFT	; otherwise, x is one less
			BRA p_end
not_pleft:
		BIT #PAD_RGHT		; move to the right?
		BEQ not_pright		; not if not pressed
			CMP padlast, X	; still pressing?
			BNE is_pright
		JMP not_pfire		; ignore either, but keep going down!
is_pright:
			STA padlast, X	; anyway, register this press
			LDY #MOV_RGHT	; otherwise, x is one more
			BRA p_end
not_pright:
		BIT #PAD_DOWN		; let it drop?
		BEQ not_pdown		; not if not pressed
			LDY #MOV_NONE	; default action in most cases
			LDA ticks
			AND #DMASK		; will drop quickly...
			BNE p_end		; ...only every 8 ticks (16 interrupts)
				LDY #MOV_DOWN			; otherwise, Y is one more
				INC delta, X			; extra score!
			BRA p_end
not_pdown:
		BIT #PAD_FIRE|PAD_B	; flip?
		BEQ not_pfire		; not if not pressed
			CMP padlast, X	; still pressing?
			BNE do_pfire
		JMP not_pfire		; ignore either, but keep going down!
do_pfire:
			STA padlast, X	; anyway, register this press
; piece rotation
; * might launch PSG effect here *
			LDA #1
			STA IOBeep		; activate sound...
			LDA column+2, X
			PHA				; save last piece
			LDA column+1, X
			STA column+2, X
			LDA column, X
			STA column+1, X	; rotate the rest
			PLA
			STA column, X	; and wrap the last one
			LDY posit, X	; display recently rotated column!
			JSR col_upd
			STZ IOBeep		; ...and finish audio pulse
			LDY #MOV_ROT	; this was a rotation, thus no change
			BRA p_end
not_pfire:
		LDY #MOV_NONE		; eeek
do_advance:
; in case of timeout, put piece down... or take another
		LDA ticks_l
		CMP ev_dly, X
		BMI p_end			; if timeout expired... not BCC eeeeeek
			CLC
			ADC speed, X
			STA ev_dly, X	; update time for next event
; will check if possible to move down
			LDY #MOV_DOWN
p_end:
; move according to Y-direction, if possible
; should actually update offset, check availability and, if so, update screen, otherwise revert offset (easily done)
		CPY #MOV_NONE		; any move?
		BNE do_move
			JMP not_move
do_move:
		LDA posit, X
		CLC
		ADC ix_dir, Y		; add combined offset
		STA posit, X
		JSR chkroom			; returns zero if available space
		CMP #0
		BEQ is_room			; movement is feasible, do not revert
			LDA posit, X
			SEC
			SBC ix_dir, Y	; otherwise revert move
			STA posit, X
			CPY #MOV_DOWN	; tried to go down and failed?
		BNE not_move		; do not update screen... but check if at bottom
; cannot go down any more, update field
; maybe here's the place to check for matches...
; but first check peñonazo's height, must be second row or below
			BIT #%01110000	; at least 16, no matter the player, the row is visible
			BNE have_col	; any bit on is OK
; this is done when no room for the new column
				LDA #STAT_DIE			; will trigger palmatoria
				STA status, X			; eeeeeeeeeeeeeeeeeeeeek
; prepare loops for the new status
				TXA						; get player index
				ORA #BOTT_L				; 14*8+1 is first column in new coordinates, plus player offset
				STA phase, X			; eeeek
				LDY #15					; needs 16 iterations non-visible rows
				STY anim, X
; start this animation immediatly, then once every 5 ticks (10 interrupts ~ 2 fields)
				LDA ticks
				STA ev_dly, X
; now will display the gameover animation concurrently!
				BRA not_play
have_col:
			PHY				; just in case
			LDY posit, X	; final position of first tile (both players)
			LDA column, X	; first jewel
			STA field, Y
; update magic flag!
			CMP #MAGIC_JWL	; was it the magic jewel?
			BNE mj_not		; no, leave flag alone
				LDA #0
				STA field, Y			; otherwise, do NOT store magic jewel
				TYA						; get actual position for magic flag
				STA dr_mj, X			; store flag
				BRA mj_done				; do not bother with the remaining tiles
mj_not:
; continue storing column
			LDA column+1, X				; second jewel
			STA field+ROW_OFF, Y		; into next row
			LDA column+2, X				; last jewel
			STA field+ROW_OFF*2, Y
mj_done:
			JSR gen_col		; another piece
			LDA delta, X	; any drop points?
			BEQ no_droppt
				JSR addscore			; add possible drop points
				LDY #DISP_SCO
				JSR numdisp				; display updated score
no_droppt:
			PLY
; new piece is stored, let's check for matches!
			LDA #STAT_CRSH	; ...but let's go for peñonazo first!
			STA status, X	; change status
			LDA #P_CYC		; number of peñonazo cliks
			STA anim, X		; preload counter
			LDA ticks
			ADC #P_PER		; time between pulses
			STA ev_dly, X	; and also next click
; * might prepare here the PSG initial effect *
is_room:
		JSR col_upd			; ...as screen must be updated
not_move:
not_play:
; * * CRSH STATUS, play peñonazo sound * *
	LDA status, X
	CMP #STAT_CRSH
	BNE not_crash
; base sound effect starts here
		LDA ticks			; check current time
		CMP ev_dly, X		; alternative, safer way
		BMI not_crash		; if timeout expired... but not BCC eeeeeek
			DEC anim, X		; check sound effect progress
		BEQ crash_end		; all done!
			ADC #P_PER		; otherwise, add another delay
			STA ev_dly, X
			JSR pulse		; make brief tick
			BRA not_crash	; continue with next thread
crash_end:
; * might alter peñonazo PSG effect from here *
;		JSR cl_mark			; before anything else, clear marked tiles matrix
		STZ cycle, X		; reset hojalete counter (magic jewel does not count, nor multiplies by level)
		LDA #STAT_CHK
		STA status, X		; after peñonazo, check for matches
not_crash:

; * * CHK STATUS, check for matching tiles (magic jewel only) * *
	LDA status, X
	CMP #STAT_CHK
	BNE not_check
		JSR cl_mark			; before anything else, clear marked tiles matrix
; * check whether magic tile has dropped *
		LDY dr_mj, X		; get magic flag
		BEQ no_mjwl			; nope, proceed with standard check
; if so, look for whatever tile is under the fallen one and make all of their type disappear
; but first mark it as deletion-pending for the flashing
			TYA				; recover index value
			STA mark, Y		; only as pending deletion, value is irrelevant
			STA mark+ROW_OFF, Y
			STA mark+ROW_OFF*2, Y
			CLC
			ADC #COL_HGT	; go three rows below from first tile
			TAY				; index within field
			LDX field, Y	; check what was under the magic column
		BMI no_mjwl2		; if sentinel, we are at the very bottom, do nothing... just flashing
; special case, mark every tile of the same type of that just below the magic jewel
			LDA select		; player as last position
			ORA #LAST_V		; start from last useable cell, backwards
			TAY				; index ready
			TXA				; pivot element ready
			LDX select		; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
mjml:
				CMP field, Y			; does it match?
				BNE no_mjmt
					STA mark, Y			; if so, mark it for deletion
					INC match_c, X		; count it as well EEEEEEEEEEK
no_mjmt:
				DEY			; one less
				CPY select	; already done all of this player's field?
				BNE mjml	; if not, continue scanning
; anything else?
no_mjwl2:
			LDX select		; needed only when is at the bottom
; *** COMMON entry point to shift from CHK (or BSCK) to BLNK status ***
do_match:
			LDA #BLINKS		; usually 8 cycles
			STA anim, X		; set counter
			LDA ticks		; best update this too
			INC
			STA ev_dly, X	; will start very soon
			LDA #STAT_BLNK
			BRA chk_switch	; switch to blink
no_mjwl:
; * magic jewel is handled, now check for any 3 or more matched tiles *
;		JSR cl_mark			; should be here eeeek
		INC cycle, X		; every cycle multiplies score
		LDA #STAT_HCHK		; horizontal check
		BRA chk_switch		; will eventually switch thread
; *** common exit from any kind of unsuccessful check ***
not_match:
;	JSR gen_col				; is this the correct place?
;	JSR col_upd				; might look nicer
	LDA ticks_l
	CLC
	ADC speed, X
	STA ev_dly, X			; update time for next event
	LDA #STAT_PLAY			; no success, back to play
	LDX select				; needed, I'm afraid
; common exit from CHK, switching status
chk_switch:
	STA status, X			; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK

not_check:
; * * HCHK STATUS, check for matching tiles (horizontal) * *
	LDA status, X
	CMP #STAT_HCHK
	BNE not_hchk
;		JSR hchkmatch		; check for horizontal matches (eventually switching to VCHK)
; scan for horizontal matches (now inlined)
		STZ temp			; temporary storage for mathch_c
		LDA select			; player index
		ORA #LAST_V			; last used cell (will add one later)
		TAY					; read index
hch_try:
			INY				; eeek
			LDX #255		; -1, will be preincremented
hch_skip:
				DEY			; scan for blanks
				CPY select	; eeek
			BEQ hch_fin
				INX						; count blanks
				LDA field, Y			; get tile in field
				BEQ hch_skip			; if blank, keep skipping
			CPX #ROW_WDT	; did six consecutive blanks? ** CHECK **
		BEQ hch_fin			; all done, then
			LDX #0			; reset match counter
hch_rpt:
				INX
				DEY						; advance backwards
				CPY select				; eeeek
			BEQ hch_fin					; eeeeeeeeeeeeek
				CMP field, Y			; same as pivot?
				BEQ hch_rpt				; keep counting matches
			CPX #JWL_COL				; at least 3-in-a-row? ** CHECK **
		BCC hch_try						; not enough, try again
; compute score from number of matched tiles, X is run length
			PHY				; eeeek
			LDY select		; eeeeek
			LDA delta, Y	; get accumulated score eeeeeek
			CLC
			ADC base_sc, X	; add base points for this match
			STA delta, Y
			LDA delta+1, Y	; propagate carry
			ADC #0
			STA delta+1, Y
			PLY				; eeek
; update match counter as well
			LDA temp
			CLC				; eeeek
			ADC id_table, X	; actually A=A+X
			STA temp		; update temporary counter
			TYA				; non-zero value, also saves current position
hch_detect:
				STA mark+1, Y			; mark them, one 'before' the first mismatch
				INY
				DEX
				BNE hch_detect
			TAY				; restore index
			BNE hch_try		; and keep trying
hch_fin:
		LDX select
		LDA temp			; return Z if no matches
		STA match_c, X		; set counter (this is the first one, no need to add)
;		SEC					; this is run to completion, thus switch thread ASAP
;	BCC not_hchk
; prepare things for switching into VCHK status 
		LDA #BOTT_L			; first column on last visible row
		ORA select			; eeeeeeeeeeeeeeeeeeeeeeeeek
		STA anim, X			; store as initial position
; switch thread!
		LDA #STAT_VCHK
		BRA chk_switch
not_hchk:

; * * VCHK STATUS, check for matching tiles (vertical) * *
	LDA status, X
	CMP #STAT_VCHK
	BNE not_vchk
		JSR vchkmatch		; check for vertical matches (eventually switching to SLCK)
	BCC not_vchk
		LDA #LAST_V-2		; first sensible diagonal, bottom right
		ORA select			; eeeeeeeeeeeeeeeeeeeeeeeeek
		STA anim, X			; store as initial position
		LDA #STAT_SLCK
		BRA chk_switch
not_vchk:

; * * SLCK STATUS, check for matching tiles (slash diagonal) * *
	LDA status, X
	CMP #STAT_SLCK
	BNE not_slck
		JSR slckmatch		; check for horizontal matches (eventually switching to VCHK)
	BCC not_slck
		LDA #VTOP_L+ROW_WDT+2*ROW_OFF	; $26 is first sensible diagonal, top-ish right
		ORA select			; eeeeeeeeeeeeeeeeeeeeeeeeek
		STA anim, X			; store as initial position
		LDA #STAT_BSCK
		JMP chk_switch
not_slck:

; * * BSCK STATUS, check for matching tiles (backslash diagonal) * *
	LDA status, X
	CMP #STAT_BSCK
	BNE not_bsck
		JSR bsckmatch		; check for horizontal matches (eventually switching to BLINK or PLAY)
	BCC not_bsck
; all checks are finished, check for any detected matches
		LDA match_c, X		; match counter
	BNE bs_do_mt
		JMP not_match		; no, back to play
bs_do_mt:
	JMP do_match			; yes, proceed to blink, explode and drop
not_bsck:

; * * BLNK STATUS, blink matched pieces * *
	LDA status, X
	CMP #STAT_BLNK
		BEQ do_blink
	JMP not_blink
do_blink:
		LDA ticks			; check current time
		CMP ev_dly, X		; alternative, safer way
		BMI not_blink		; if timeout expired... but not BCC eeeeeek
			ADC #BL_SPC		; ...add another delay for next iteration
			STA ev_dly, X
; proceed to hide or show marked tiles
			LDA anim, X		; check frame
			LSR				; C set means visible
			ROR dr_mj, X	; insert C into d7 as flag
; scan all marked tiles, show or hide depending on dr_mj.D7 flag!
			TXA				; player index
			ORA #LAST_V		; last position
			TAY				; index ready (as array index)
mk_cl:
				LDA mark, Y	; marked for deletion?
				BEQ not_mark
					LDA #0				; hidden by default
					BIT dr_mj, X		; time to display or hide?
					BPL bl_hide
						LDA field, Y	; if display, get tile index
					BNE bl_hide			; if marked, but field is zero, it's magic jewel
						LDA #MAGIC_JWL	; magic jewel is not stored, thus provide constant index
bl_hide:
					PHY
					JSR tiledis			; update tile on screen
					PLY
					LDX select			; eeeeeek * worth doing on tiledis?
not_mark:
				DEY
				CPY select	; all done?
				BNE mk_cl
; anything else?
			DEC anim, X		; one less step
		BPL not_blink		; still to do, keep this status
; after animation, update jewel counter
			LDA #LAST_V		; last visible tile
			ORA select		; plus player index
			TAX				; use as scanning index
			LDY #0			; reset jewel counter
jwl_ct:
				LDA mark, X	; check whether tile was deleted eeeek
				BEQ no_jct
					INY		; if so, count it!
no_jct:
				DEX			; previous tile
				CPX select	; discarding player bit
				BNE jwl_ct
; in case of magic jewel, this counts is three more, subtract if needed
			LDA cycle, X	; this is zero when doing magic jewel
			BNE no_3mj
				TYA						; temporary count storage
				SEC
				SBC #JWL_COL			; subtract magic jewel tiles
				TAY
no_3mj:
; Y has updated jewel count, convert to BCD
			SED				; eeeeek
			LDA bcd_id, Y	; jewel count in BCD
			CLC
			ADC bcd_arr+2, X			; add jewel LSB eeeeek
			STA bcd_arr+2, X
			LDA bcd_arr+1, X			; MSB
			ADC #0						; propagate carry
			STA bcd_arr+1, X
			BCC jw_bcd_cc
				LDA #$99				; special overflow case
				STA bcd_arr+1, X
				STA bcd_arr+2, X		; keep at '9999'
jw_bcd_cc:
			CLD
; print updated jewel count
			LDY #DISP_JWL	; selects jewel display
			JSR numdisp		; update display (reloads X as select)
; finally, turn into EXPLode status
			LDA #MAGIC_JWL	; index before first explosion tile
			STA anim, X		; store for next thread
			LDA ticks
			INC
			STA ev_dly, X	; execute on next interrupt
			STZ dr_mj, X	; eeeek
			LDA #STAT_EXPL
			STA status, X

not_blink:
; * * EXPLode STATUS * *
	LDA status, X
	CMP #STAT_EXPL
	BEQ do_explode
		JMP not_explode
do_explode:
		LDA ticks
		CMP ev_dly, X		; is it time?
		BPL upd_explode
	JMP not_explode
upd_explode:
		CLC
		ADC #EXP_SPD		; frame rate
		STA ev_dly, X		; ready for next time
; could do brief tone here IF goal has been reached
		LDA bcd_arr+1, X	; jewel count MSB
		CMP goal, X			; reached goal?
		BCC no_warn
			LDA bcd_arr+2, X			; if so, check LSB afterwards
			CMP goal+1, X
		BCC no_warn			; nope, stay in current level
; sound effect for level change
			LDA #88
			JSR tone
			LDX select		; eeek
no_warn:
; check above could be unified, using a flag
		INC anim, X			; preincrement step
		LDA anim, X			; which step?
		CMP #NUM_JWLS+2		; over last of explosion
		BEQ end_expl		; it's over
; do explode animation
			TAX				; keep current frame
			LDA select		; get player index
			ORA #LAST_V		; last visible tile
			TAY				; use as index
			TXA				; frame to be saved
ex_loop:
				LDX mark, Y	; was this one marked?
				BEQ tile_noexp
					PHA
					PHY
					JSR tiledis			; display frame
					PLY
					PLA
tile_noexp:
				DEY
				CPY select	; until topmost tile
				BNE ex_loop
			LDX select		; restore this!
			JMP not_explode	; leave thread for now
; delete marked pieces
end_expl:
		TXA					; get player index
		ORA #LAST_V			; last visible piece
		TAX					; use as index, STZ-savvy
exp_cl:
			LDA mark, X		; is this marked?
			BEQ not_fd		; nope, leave it
				STZ field, X			; otherwise, clear it
not_fd:
			DEX				; next cell
			CPX select		; until the top
			BNE exp_cl
; * after animation is ended, may display updated score ** perhaps after drop **
; should apply factors here
		LDY bcd_arr, X		; this is current level in BCD
		LDA bcd2bin, Y		; binary equivalent
		INC					; zero-based!
		JSR multiply		; level applied
		LDA cycle, X		; check hojalete's shot
		JSR multiply		; applied as well
; might also check magic jewel score (no factors)
		LDA delta, X
		ORA delta+1, X		; any non-magic points?
		BNE do_score		; if so, proceed directly
			LDA match_c, X	; otherwise, score is number of tiles, times 15
			STZ delta+1, X	; clear MSB
			ASL
;			ROL delta+1, X	; max. match_c is 78, thus delta < 156
			ASL
			ROL delta+1, X
			ASL
			ROL delta+1, X
			ASL
			ROL delta+1, X	; times 16
			SEC
			SBC match_c, X	; minus one, is times 15
			STA delta, X
; more efficient code to check borrow
			BCS do_score	; no borrow is OK
				DEC delta+1, X
;			LDA delta+1, X	; propagate borrow
;			SBC #0
;			STA delta+1, X
do_score:
		JSR addscore		; get BCD string from delta and add it to global score
		LDY #DISP_SCO
		JSR numdisp			; display updated score

;		LDX select			; make sure
; check here if goal is achived for next level
		LDA bcd_arr+1, X	; jewel count MSB
		CMP goal, X			; reached goal?
		BCC no_goal
			LDA bcd_arr+2, X			; if so, check LSB afterwards
			CMP goal+1, X
		BCC no_goal			; nope, stay in current level
			SED				; otherwise, let's operate in BCD
			LDA bcd_arr, X	; current level
			CLC
			ADC #1
			STA bcd_arr, X	; update level
		BCC no_clock		; if below 100, new level is OK
			LDA #$99		; otherwise is overflow!
			STA bcd_arr, X	; update level
		BRA upd_lvl			; and display it
no_clock:
			LDA goal+1, X	; target must be updated as well
			CLC
			ADC #GOAL		; increase goal threshold
			STA goal+1, X
			LDA goal, X
			ADC #0			; propagate carry
			STA goal, X
upd_lvl:
		CLD					; back to binary mode!
		LDY bcd_arr, X		; recheck current level (BCD)
		CPY #$10			; already over max speed?
		BMI max_spd
			LDY #10			; top speed index
max_spd:
		LDA ini_spd, Y		; get rate from table
		STA speed, X		; update speed
		LDY #DISP_LVL
		JSR numdisp			; display updated level on screen
no_goal:
; finally turn into DROP status
		LDA ticks
		INC					; almost immediately
		STA ev_dly, X
		LDA #BOTT_L			; first column on last visible row
		ORA select			; eeeeeeeeeeeeeeeeeeeeeeeeek
		STA phase, X		; store as external counter...
		STA anim, X			; ...and as current position
		LDA #STAT_DROP
		STA status, X

not_explode:
; * * DROP STATUS, remove matched tiles and reposition whatever is on top * *
	LDA status, X
	CMP #STAT_DROP
	BNE not_drop
		LDA ticks
		CMP ev_dly, X		; is it time?
	BMI not_drop
		ADC #CDROP_T		; add some delay for next
		STA ev_dly, X		; perhaps do this at the end?
; scanning routine starts here
		LDA #VTOP_L			; just before first visible cell
		ORA select			; add player
		STA temp			; new custom limit
dr_rpt:
		LDY anim, X			; get bottom coordinate
dr_l0:
			LDA field, Y	; check if there's a tile there
				BEQ dr_1	; if not, scan that void
			TYA				; check index
			SEC
			SBC #ROW_OFF	; up one row
			TAY				; update index
			CPY temp		; until the top
			BPL dr_l0		; no longer signed comparison
		BMI dr_yield		; otherwise we are done with this column
dr_1:
		STY tempx			; store position of void bottom
dr_l1:
			LDA field, Y	; check if there's a void there
				BNE dr_2	; if not, we found something to drop
			TYA				; check index
			SEC
			SBC #ROW_OFF	; up one row
			TAY				; update index
			CPY temp		; until the top
			BPL dr_l1		; no longer signed comparison
		BMI dr_yield		; otherwise nothing was suspended
dr_2:
; actual drop, Y has coordinates of first tile above the void
		TYA
		TAX					; put Y on X
		LDY tempx			; now Y is destination, X is source
		PHY					; I need this for later and will lose tempx eeeeek^2
		LDA #VTOP_L
		ORA select			; regenerate custom limit
		STA temp			; as tempx will be affected
dr_l2:
			PHX
			PHY
			LDA #0			; default is clear
			CPX temp		; is source above visible area?
			BMI dr_top		; yes, just clear tile
				LDA field, X			; otherwise get floating tile
				STZ field, X			; delete dropped tile
dr_top:
			STA field, Y	; store below
			JSR tiledis		; and remove deleted one from screen!
			PLA				; actually stored Y
			SEC
			SBC #ROW_OFF	; one row up (dest)
			TAY				; restore register
			PLA				; actually stored X
			SEC
			SBC #ROW_OFF	; one row up (src)
			TAX				; finally restore register
			CPY temp		; until DESTINATION is at the top
			BPL dr_l2		; no longer signed comparison
		LDX select
		PLA					; eeeek^3
		STA anim, X			; store PREVIOUS destination for multithreading
		BRA not_drop		; this looks nice
dr_yield:
		INC phase, X		; advance column
		LDA phase, X
		STA anim, X			; update counter, just in case
		AND #PLYR_OFF-1		; actually 127, remove D7 (player bit)
		CMP #LAST_V+1		; all columns were done?
	BNE not_drop			; not yet, yield execution to next player
; after finishing DROP, will ALWAYS turn into CHK again, until it resumes back to PLAY
exit_drop:
;		JSR cl_mark			; before anything else, clear marked tiles matrix
		LDA #STAT_CHK
		STA status, X

not_drop:
; * * DIE STATUS * *
	LDA status, X			; just in case...
	CMP #STAT_DIE			; just died?
	BNE not_die
		LDA ticks
		CMP ev_dly, X
		BMI not_die			; if timeout expired... but not BCC
			CLC
			ADC #DIE_PER	; next in 5 ticks
			STA ev_dly, X	; update time for next event
			JSR palmatoria	; will switch to STAT_OVER when finished * might be inlined
		LDX select
not_die:
; * * PAUSe STATUS * * TO DO
	LDA status, X			; ...just in case
	CMP #STAT_PAUS			; in pause
	BNE not_pause
		LDA pad0val, X
		BIT #PAD_STRT
		BEQ st5_rls			; just released, check previous
			STA padlast, X	; otherwise register press
			BRA not_pause
st5_rls:
		LDA padlast, X		; check previous
		BIT #PAD_STRT		; just released START?
		BNE not_pause		; nope, just continue
; ** ** TO DO * otherwise, get screen back * TO DO ** **
			LDA #STAT_PLAY
			STA status, X	; restore play mode
not_pause:
; * * * all feasible stati checked, switch player thread * * *
next_player:
; check possible colour animation on magic jewel...
	LDA ticks				; check timing!
	AND #MJ_UPD				; about every 1/15 s
		BNE cl_nonmagic		; skip if not the time
; ...if it's the time to do so
	LDA next_c, X
	CMP #MAGIC_JWL			; is the magic jewel next?
	BNE nx_nonmagic
		JSR magic_jewel		; pick one random colour
		JSR nextcol			; and redisplay it
nx_nonmagic:
	LDA status, X			; same for the jewel in the field...
	CMP #STAT_PLAY
		BCC cl_nonmagic		; ...but only while playing or higher
	LDA column, X
	CMP #MAGIC_JWL			; is the magic jewel on the field?
	BNE cl_nonmagic
		JSR magic_jewel		; pick one random colour
		JSR coldisp			; and redisplay it eeek
cl_nonmagic:
	TXA						; instead of LDA select
	EOR #PLYR_OFF			; toggle player in event manager
	STA select
#ifdef	DEBUG
	LDA IO8attr				; get current video mode
	AND #%11110000			; filter readable bits
	ORA #%00001000			; force RGB
	EOR #%01000000			; toggle inverse video
	STA IO8attr				; switch mode
#endif
	JMP loop

; ***********************
; *** useful routines ***
; ***********************

; ** display one compressed full screen **
; input
;	X	index for addresses list (always even)
; affects all registers
dispic:
	LDY cmpr_pics, X
	LDA cmpr_pics+1, X
	STY src
	STA src+1				; set source pointer
	LDY #<screen3
	LDA #>screen3			; screen 3 start address
	STY ptr
	STA ptr+1				; set destination pointer
;	JMP rle_loop			; decompress and return!

; ** RLE decompressor **
rle_loop:
		LDY #0				; always needed as part of the loop
		LDA (src), Y		; get command
		INC src				; advance read pointer
		BNE rle_0
			INC src+1
rle_0:
		TAX					; command is just a counter
			BMI rle_u		; negative count means uncompressed string
; * compressed string decoding ahead *
		BEQ rle_exit		; 0 repetitions means end of 'file'
; multiply next byte according to count
		LDA (src), Y		; read immediate value to be repeated
rc_loop:
			STA (ptr), Y	; store one copy
			INY				; next copy, will never wrap as <= 127
			DEX				; one less to go
			BNE rc_loop
; burst generated, must advance to next command!
		INC src
		BNE rle_next		; usually will skip to common code
			INC src+1
			BNE rle_next	; no need for BRA
; alternate code, more compact but a bit slower
;		LDA #1
;		BNE rle_adv			; just advance source by 1 byte
; * uncompressed string decoding ahead *
rle_u:
			LDA (src), Y	; read immediate value to be sent, just once
			STA (ptr), Y	; store it just once
			INY				; next byte in chunk, will never wrap as <= 127
			INX				; one less to go
			BNE rle_u
		TYA					; how many were read?
rle_adv:
		CLC
		ADC src				; advance source pointer accordingly (will do the same with destination)
		STA src
		BCC rle_next		; check possible carry
			INC src+1
; * common code for destination advence, either from compressed or un compressed
rle_next:
		TYA					; once again, these were the transferred/repeated bytes
		CLC
		ADC ptr				; advance desetination pointer accordingly
		STA ptr
		BCC rle_loop		; check possible carry
			INC ptr+1
		BNE rle_loop		; no need for BRA
rle_exit:					; exit decompressor
	RTS						; EEEEEEEK

; ** display falling column ** ** temporary hack
; input
;	X		player [0-128]
; affects A, Y and some vars from tiledis
col_upd:
; new * inlined clear column from previous position
	LDY oldposit, X			; get OLD position
	PHY						; eeeeeek
	LDA #0					; only difference from col_upd
	JSR tiledis				; show top tile
	PLA
	CLC
	ADC #ROW_OFF
	PHA
	TAY
	LDX select
	LDA #0					; *
	JSR tiledis				; middle one
	PLA
	CLC
	ADC #ROW_OFF
	TAY						; last one does not need to be saved
	LDX select
	LDA #0					; *
	JSR tiledis				; and bottom one
	LDX select
	LDA posit, X			; update old position
	STA oldposit, X
; this displays falling column at index Y
coldisp:
	LDY posit, X			; get current position
	PHY						; eeeeeek
	LDA column, X
	JSR tiledis				; show top tile
	PLA
	CLC
	ADC #ROW_OFF
	PHA
	TAY
	LDX select
	LDA column+1, X
	JSR tiledis				; middle one
	PLA
	CLC
	ADC #ROW_OFF
	TAY						; last one does not need to be saved
	LDX select
	LDA column+2, X
	JSR tiledis				; and bottom one
	LDX select
	RTS

; ** display tile **
; input
;	Y = position index
;	A = tile to print!
; affects tempx and all registers (not worth saving here as two entry points)
tiledis:
;	LDX select				; eeeeek
	STA tempx				; eeeeek
	DEY						; let's be consistent...
	TYA						; will be MSB...
	AND #%01111000			; filter row
	CMP #LASTROW
		BCS td_exit			; last row (15) is not-visible
	CMP #VTOP_L
		BCC td_exit			; first two rows aren't either
	SBC #VTOP_L					; first visible row is 2 (C known set)
	LSR
	LSR						; ...two pages per row
	ADC #FIELD_PG			; place into screen 3, 12 rasters below
	STA ptr+1				; first address is ready!
;	TYA
;	AND #PLYR_OFF
;	TAX						; just sign as player index
	LDX select				; seems simpler ***
	TYA
	AND #%00000111			; filter column
	ASL
	ASL						; times four bytes per column
	ADC psum36, X			; first pixel in line is 4, perhaps with 36-byte offset, C known clear
	STA ptr					; LSB is ready
	LDA tempx				; eeeeek
; * external interface for next piece *
; input
;	A		tile index
;	ptr		screen position
;	colour*	mask for magic jewel
; affects all registers
tileprn:
	LDY #$FF
	CMP #MAGIC_JWL			; is it the magic jewel?
	BNE tp_nm
		LDX select
		LDY mag_col, X
tp_nm:
	STY colour
	STA src+1				; temporary MSB
	LDA #0					; will be LSB
	LSR src+1
	ROR
	LSR src+1
	ROR
	LSR src+1
	ROR						; MSB/8 is A times 32
	ADC #<sprites			; C was clear, add base address
	STA src
	LDA src+1
	ADC #>sprites			; ditto for MSB
	STA src+1				; pointer complete!
	LDX #TIL_HGT			; number of rasters
s_rloop:
		LDY #TIL_WDT-1		; max index per raster
s_bloop:
			LDA (src), Y	; get sprite data...
			AND colour
			STA (ptr), Y	; ...and place on screen
			DEY
			BPL s_bloop		; for all 4 bytes in raster
		LDA src
		CLC
		ADC #TIL_WDT		; next raster in sprite file
		STA src
		BCC s_rnw
			INC src+1		; in case of page crossing
s_rnw:
		LDA ptr
		CLC
		ADC #RST_BYT		; next raster in screen
		STA ptr
		BCC s_wnw
			INC ptr+1		; in case of page crossing
s_wnw:
		DEX
		BNE s_rloop			; until all rasters done
td_exit:
	RTS

; ** number display **
; input
;	Y		type of display (0=level, 1=jewels, 2=score)
;	bcd_arr	scores array
;	select	player [0-128]
; affects colour, bcd_lim and all registers (X reloaded as select)

; score=6 digits, level=2 digits, jewels=4 digits
; BCD data array [LJJSSS], big endian
; player 1 base addresses; score $6007 (14,0), level $6C5C (56,49), jewels $7E4A (20,121)
; player 2 level adds 52 Y-offset! (64,101)
; player 2 offset; score $26 (90-14), level 4 (actually $D04) (64-56), jewels $24 (92-20)
numdisp:
	LDX select
	LDA play_col, X			; get colour according to player
	STA colour				; set colour
	TXA						; player offset
	ORA id_table, Y			; select type of display, easier as separate bit d7
	TAY						; offset to base address
	LDA num_bl, Y
	STA ptr
	LDA num_bh, Y
	STA ptr+1				; screen pointer is ready
	TAX						; page number must be restored after each digit!
	LDA disp_top, Y
	STA bcd_lim				; keep offset limit! eeeeeeek
	LDA disp_id, Y
	TAY						; reindex
bcd_loop:
		LDA bcd_arr, Y		; get one BCD byte
		PHA					; save for LSB
		LSR
		LSR
		LSR
		LSR					; keep MSN
		JSR bcd_disp		; show it
		STX ptr+1			; restore page
		PLA					; retrieve full value
		AND #15				; just LSN
		JSR bcd_disp		; and show it too
		STX ptr+1			; restore page again
		INY					; next two digits!
		CPY bcd_lim 		; is it the last one?
		BNE bcd_loop
	LDX select				; for good measure
	RTS

; * single number printing *
; input
;	A		BCD nibble
;	colour	II format
; affects A
bcd_disp:
	PHX
	PHY
	ASL						; two bytes per raster
	TAX						; first raster address
	LDY #0
n_rast:
		LDA numbers, X
		AND colour
		STA (ptr), Y		; copy glyph raster into screen
		INX
		INY
		LDA numbers, X
		AND colour
		STA (ptr), Y		; copy glyph raster into screen
		TYA
		CLC
		ADC #RST_BYT-1		; one raster minus 2? bytes of a number
		TAY
		BCC ras_nw
			INC ptr+1
ras_nw:
		TXA
		CLC
		ADC #19				; advance to next raster in font (31 for hex)
		TAX
		CPX #140			; within valid raster? (10 numbers * 2 bytes * 7 rasters) (224 for hex)
		BCC n_rast
	INC ptr					; advance digit position
	INC ptr
	PLY
	PLX
	RTS

; ** binary to BCD conversion **
; now adds to BCD score too
; based on Garth Wilson's work at http://6502.org/source/integers/hex2dec.htm
; input
;	delta, X		binary
;	X				player (untouched)
; output
;	bcd_arr+3, X	3-byte BCD, big endian!
; affects Y & A, plus local htd_out
addscore:
	STZ htd_out				; clear result
	STZ htd_out+1
	STZ htd_out+2
	SED						; decimal mode!
	LDY #15					; will convert 16 bits (0...15)
b2b_l:
		ASL delta, X
		ROL delta+1, X		; if next highest bit was 0
		BCC b2b_s			; then skip to next bit
			LDA htd_out+2	; this is actually LSB
			CLC
			ADC bcd_p_l, Y	; add bit value, LSB first
			STA htd_out+2
			LDA htd_out+1	; then middle byte
			ADC bcd_p_m, Y
			STA htd_out+1
			LDA htd_out		; then high byte
			ADC bcd_p_h, Y	; summed output
			STA htd_out		; store result
b2b_s:
		DEY
		BPL b2b_l			; repeat for every source bit
; now add the temporary result in htd_out to global BCD score
	CLC
	LDA bcd_arr+5, X		; total score low byte eeeeek
	ADC htd_out+2			; add output
	STA bcd_arr+5, X		; update
	LDA bcd_arr+4, X		; same with mid byte
	ADC htd_out+1
	STA bcd_arr+4, X
	LDA bcd_arr+3, X		; same with high byte
	ADC htd_out
	STA bcd_arr+3, X
	BCC sc_notc				; already clocked?
		LDA #$99			; special overflow case
		STA bcd_arr+3, X
		STA bcd_arr+4, X
		STA bcd_arr+5, X
sc_notc:
	CLD						; back to binary mode!
	RTS

; ** multiply routine 8x16=16-bit **
; input
;	A			8-bit factor
;	delta, X	16-bit factor
;	X			player (preserved)
; output
;	delta, X
; affects A, plus temporary mult/mul8
multiply:
	STA mul8				; copy 8-bit factor
	LDA delta, X
	STA mult
	LDA delta+1, X
	STA mult+1				; copy 16-bit factor
	STZ delta, X
	STZ delta+1, X			; clear result
mu_loop:
		LSR mul8			; half 8-bit factor
		BCC mu_skip			; go for next bit
			LDA delta, X
			CLC
			ADC mult		; add this partial result
			STA delta, X
			LDA delta+1, X	; same for MSB
			ADC mult+1
			STA delta+1, X
mu_skip:
		ASL mult
		ROL mult+1			; 16-bit factor times two
		LDA mul8			; are we done?
		BNE mu_loop
	RTS

; ** death animation **
; input
;	select	player [0,128]
; affects status, s_level, anim, phase, temp and all registers
palmatoria:
; these will go after the last one
; id while changing status WTF
		LDX select			; eeeeeeeeeek
		LDA #MAGIC_JWL		; initial explosion tile - 1
		LDY phase, X
dz_tile:
			INC				; next tile
			CMP #NUM_JWLS+1
			BNE dz_nw
				LDA #0		; 0, then exit
dz_nw:
			STA temp		; will hold current tile
			LDX #ROW_OFF-2	; six columns
dz_col:
				PHX
				PHY
				LDA temp	; get tile from here
				JSR tiledis
				PLY
				PLX
				INY			; next column
				DEX			; check limit
				BNE dz_col
dz_show:
			TYA
			CLC
			ADC #2			; skip 2 sentinels
			TAY				; next row index
			LDA temp
			BNE dz_tile		; did tile type 0, thus last one
		TYA
		SEC
		SBC #ROW_OFF*5		; 5 rows back
		LDX select
		STA phase, X		; store for next call!
; no wait here, will be called every 10 interrupts
		LDA #30
		JSR tone			; brief beep!
		LDX select
		DEC anim, X			; one less row
		BPL go_exit			; not the last, give CPU back
; all finished, change status to definitive
	LDX select
;	LDA STAT_OVER			; conveniently zero, and X is proper player offset
	STZ status, X			; back to gameover status
	STZ s_level, X			; reset this too! eeeeeeeek
; now print the game over banner
	LDY #<gameover
	LDA #>gameover			; no longer X
	STY src
	STA src+1				; set origin pointer
	LDA temp				; get X for player field
	LDY #10					; raster counter
; * alternate entry to print a 24*x banner *
;	Y		rasters - 1
;	select	player [0-128]
;	src		points to .sv24
; affects temp and all registers
banner:
	LDX select				; needed b/c alternate entry
	STY temp				; counter in memory
	LDA psum36, X
	STA ptr
	LDA #BANNER_PG			; two rows above centre
	STA ptr+1
go_vloop:
		LDY #BAN_WDT-1		; max horizontal offset
go_hloop:
			LDA (src), Y
			STA (ptr), Y
			DEY
			BPL go_hloop
		DEC	temp			; one raster is ready
	BMI go_exit
		LDA src
		CLC
		ADC #BAN_WDT		; next raster in image
		STA src
		BCC go_nw
			INC src+1
go_nw:
		LDA ptr
		CLC
		ADC #RST_BYT		; next raster in screen
		STA ptr
		BCC go_vloop
			INC ptr+1		; there was page crossing
		BRA go_vloop
go_exit:
	RTS

; ** clear match detection matrix **
; affects A, restores player at X
cl_mark:
	PHY						; needed somewhere
	LDA #LAST_V				; number of entries to be cleared
	TAY						; use as counter
	ORA select				; use player as base
	TAX						; index ready
cfcl:
		STZ mark, X			; clear entry for current player
		DEX					; eeek
		DEY
		BPL cfcl			; 119*11 ~ 1300t, 850 µs or less
	LDX select				; reload player index for good measure
	STZ match_c, X			; reset match detection
	STZ delta, X
	STZ delta+1, X			; and temporary score, as well
	PLY						; and this
	RTS

; ** check for available movements **
chkroom:
;	LDX select				; depending on player
	PHY						; keep desired movement
	LDY posit, X			; desired position of topmost tile, note already contains player offset
	LDA field, Y			; is it clear?
	ORA field+ROW_OFF, Y	; what about second tile?
	ORA field+ROW_OFF*2, Y	; and bottom one?
	PLY
	RTS

; ** check for matches **
vchkmatch:
; scan for vertical matches
	LDY anim, X				; get bottom coordinate
	LDA match_c, X
	STA tempx				; temporary match counter
vc_l1:
		LDX #0				; reset run counter (will be preincremented)
		LDA field, Y		; load pivot, is it a void?
		STY temp			; store pivot position
	BEQ vc_end				; if so, we're done with this column
vc_l2:
			PHA				; must keep pivot
			TYA				; check index
			SEC
			SBC #ROW_OFF	; up one row
			TAY				; eeeeeeeeeeeeeeeeeeeeeeeeeeek
			PLA				; recover pivot
			INX				; run counter
			CMP field, Y	; compare against tile above
			BEQ vc_l2		; until end of run
		CPX #JWL_COL		; three at least? CHECK
		BCC vc_l1			; nope, keep trying
; compute score from number of matched tiles, X is run length * could be routine
			PHY				; eeeek
			LDY select		; eeeeek
			LDA delta, Y	; get accumulated score eeeeeek
			CLC
			ADC base_sc, X	; add base points for this match
			STA delta, Y
			LDA delta+1, Y	; propagate carry
			ADC #0
			STA delta+1, Y
			PLY
; match found, must mark those tiles
			LDA tempx		; this thread's current matches
			CLC
			ADC id_table, X	; A=A+X
			STA tempx		; update count
			TYA				; first non-matching position should be kept
;			TAX				; will use X as marking index
vc_l3:
;				TXA
				CLC
				ADC #ROW_OFF; this goes downwards eeeeeek
				TAX
				STA mark, X	; any non-zero value will do
				CPX temp	; beyond pivot position?
				BCC vc_l3	; no, keep marking eeeek
		BRA vc_l1			; continue until the topmost void
vc_end:
	LDX select
	LDA tempx				; total matched tiles
	STA match_c, X			; update global counter
	INC anim, X				; advance column
	LDA anim, X
	AND #PLYR_OFF-1			; actually 127, remove D7 (player bit)
	CMP #LAST_V+1			; all columns were done?
	RTS						; will set C only when all columns are done!

slckmatch:
; scan for slash diagonal matches
	LDY anim, X				; get bottom coordinate
	LDA match_c, X
	STA tempx				; temporary match counter
slc_l1:
		TYA
		AND #PLYR_OFF-1		; actually 127, remove D7 (player bit)
		CMP #VTOP_L			; is it above visible area?
	BCC slc_end				; if so, we're done with this diagonal
		AND #ROW_OFF-1		; check column bits
		CMP #ROW_OFF-1		; is it at the very right?
	BEQ slc_end				; if so, we're done with this diagonal
		LDX #0				; reset run counter (will be preincremented)
		LDA field, Y		; load pivot, is it a void, a sentinel?
		BNE do_slc			; no blank to be skipped
			TYA
			SEC
			SBC #ROW_OFF-1	; up one row... and one to the right
			TAY
			BRA slc_l1		; keep skipping or get another run
do_slc:
		STY temp			; store pivot position
slc_l2:
			PHA				; must keep pivot
			TYA				; check index
			SEC
			SBC #ROW_OFF-1	; up one row... and one to the right
			TAY				; eeeeeeeeeeeeeeeeeeeeeeeeeeek
			PLA				; recover pivot
			INX				; run counter
			CMP field, Y	; compare against tile above
			BEQ slc_l2		; until end of run
		CPX #JWL_COL		; three at least? CHECK
		BCC slc_l1			; nope, keep trying
; compute score from number of matched tiles, X is run length * could be routine
			PHY				; eeeek
			LDY select		; eeeeek
			LDA delta, Y	; get accumulated score eeeeeek
			CLC
			ADC base_sc, X	; add base points for this match
			STA delta, Y
			LDA delta+1, Y	; propagate carry
			ADC #0
			STA delta+1, Y
			PLY
; match found, must mark those tiles
			LDA tempx		; this thread's current matches
			CLC
			ADC id_table, X	; A=A+X
			STA tempx		; update count
			TYA				; first non-matching position should be kept
;			TAX				; will use X as marking index
slc_l3:
;				TXA
				CLC
				ADC #ROW_OFF-1			; this goes downwards, note offset
				TAX
				STA mark, X				; any non-zero value will do
				CPX temp				; beyond pivot position?
				BCC slc_l3				; no, keep marking eeeek
		BRA slc_l1			; continue until the topmost void
slc_end:
	LDX select
	LDA tempx				; total matched tiles
	STA match_c, X			; update global counter
; switch to next diagonal
	LDA anim, X				; base tile
	AND #PLYR_OFF-1			; actually 127, remove D7 (player bit)
	CMP #BOTT_L+1			; are we doing horizontal?
	BCC slc_hup
		DEC					; yes, simply one backwards
		BRA nx_slc
slc_hup:
		SEC
		SBC #ROW_OFF		; nope, go one up
nx_slc:
	ORA select				; include player index
	STA anim, X				; next diagonal is set
	LDA #$20				; starting above this tile is nonsense
	ORA select				; need player index to be compared
	CMP anim, X				; all diagonals were done? returns C if so
	RTS

bsckmatch:
; scan for backslash diagonal matches
	LDY anim, X				; get bottom coordinate
	LDA match_c, X
	STA tempx				; temporary match counter
bsc_l1:
		TYA
		AND #PLYR_OFF-1		; actually 127, remove D7 (player bit)
		CMP #VTOP_L			; is it above visible area?
	BCC bsc_end				; if so, we're done with this diagonal
		AND #ROW_OFF-1		; check column bits
	BEQ bsc_end				; if at the very LEFT, we're done with this diagonal
		LDX #0				; reset run counter (will be preincremented)
		LDA field, Y		; load pivot, is it a void, a sentinel?
		BNE do_bsc			; no blank to be skipped
			TYA
			SEC
			SBC #ROW_OFF+1	; up one row... and one to the LEFT
			TAY
			BRA bsc_l1		; keep skipping or get another run
do_bsc:
		STY temp			; store pivot position
bsc_l2:
			PHA				; must keep pivot
			TYA				; check index
			SEC
			SBC #ROW_OFF+1	; up one row... and one to the LEFT
			TAY				; eeeeeeeeeeeeeeeeeeeeeeeeeeek
			PLA				; recover pivot
			INX				; run counter
			CMP field, Y	; compare against tile above
			BEQ bsc_l2		; until end of run
		CPX #JWL_COL		; three at least? CHECK
		BCC bsc_l1			; nope, keep trying
; compute score from number of matched tiles, X is run length * could be routine
			PHY				; eeeek
			LDY select		; eeeeek
			LDA delta, Y	; get accumulated score eeeeeek
			CLC
			ADC base_sc, X	; add base points for this match
			STA delta, Y
			LDA delta+1, Y	; propagate carry
			ADC #0
			STA delta+1, Y
			PLY
; match found, must mark those tiles
			LDA tempx		; this thread's current matches
			CLC
			ADC id_table, X	; A=A+X
			STA tempx		; update count
			TYA				; first non-matching position should be kept
;			TAX				; will use X as marking index
bsc_l3:
;				TXA
				CLC
				ADC #ROW_OFF+1			; this goes downwards, note offset
				TAX
				STA mark, X				; any non-zero value will do
				CPX temp				; beyond pivot position?
				BCC bsc_l3				; no, keep marking eeeek
		BRA bsc_l1			; continue until the topmost void
bsc_end:
	LDX select
	LDA tempx				; total matched tiles
	STA match_c, X			; update global counter
; switch to next diagonal
	LDA anim, X				; base tile
	AND #PLYR_OFF-1			; actually 127, remove D7 (player bit)
	CMP #BOTT_L				; are we doing horizontal?
	BCC bsc_hup
		DEC					; yes, simply one to the left
		BRA nx_bsc
bsc_hup:
		CLC
		ADC #ROW_OFF		; nope, go one DOWN
nx_bsc:
	ORA select				; include player index
	STA anim, X				; next diagonal is set
	AND #PLYR_OFF-1			; actually 127, remove D7 (player bit)
	CMP #BOTT_L+1			; all diagonals were done?
	BEQ end_bsc				; yes, exit with C set
		CLC					; otherwise, make C clear
end_bsc:
	RTS

; ** gamepad read **
; input
;	padXmask	previously set inverting mask (0 for positive logic)
; output
;	padXval	button pattern
; affects A
read_pad:
	LDA #8
	STA IO9nlat				; latch controller status
pad_rdl:
		STA IO9nclk			; send clock pulse
		DEC					; CMOS only but interesting...
		BNE pad_rdl
	LDA IO9nes0				; controller 1
	EOR pad0mask			; compare with base status
	STA pad0val
	LDA IO9nes1				; controller 2
	EOR pad1mask			; compare with base status
	STA pad1val
	RTS

; ** (busy) wait for action ** might be inlined
; output
;	X	selected player [0,128]
;	Y	randomish number
; affects all registers
continue:
	LDX #0					; default player number 1
	LDA #PAD_STRT|PAD_SEL|PAD_FIRE|PAD_B		; look for start, select or fire
wait_s:
		INY					; just for random seed setting
		BIT pad0val
	BNE release
		BIT pad1val
		BEQ wait_s
	LDX #PLYR_OFF			; if arrived here, was player 2
release:
; must wait for release also
		BIT pad0val
	BNE release
		BIT pad1val
	BNE release
	RTS

; ** VSYNC ** not currently used
vsync:
		BIT IO8blk
		BVS vsync			; if already in VBlank
wait_v:
		BIT IO8blk
		BVC wait_v			; wait for VBlank
	RTS

; ** PRNG **
; based on code from https://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
; input
;	seed
; output
;	A	random value
; affects seed and A
rnd:
	LDA seed
		BEQ lo_z
	ASL seed
	LDA seed+1
	ROL
	BCC no_eor
do_eor:
		STA seed+1
do_eor2:
		LDA seed
		EOR #$2D
		STA seed
	RTS
lo_z:
	LDA seed+1
		BEQ do_eor2
	ASL
	BEQ no_eor
	BCS do_eor
no_eor:
	STA seed+1
	RTS

; ** draw select level menu **
; input
;	select	player position [0,128] (actually for banner)
; affects all registers (plus whatever banner does, temp)
sel_ban:
; brief EG arpeggio
	LDA #228				; brief E5
	JSR tone
	LDA #192				; longer G5
	LDX #0
	JSR tone
; display banner
	LDY #<levelsel
	LDX #>levelsel
	STY src
	STX src+1				; set origin pointer
	LDY #BAN_HGT			; raster counter
	JMP banner				; display and return

; ** mark one row as inverted **
; input
;	select	player [0,128]
;	s_level	currently selected
; affects all registers
inv_row:
;	LDX select
	LDA psum36, X			; horizontal position in raster
	STA ptr
	LDA s_level, X			; current level determines row
	ASL						; times two
	ADC #BANNER_PG			; into banners area
	STA ptr+1
	LDX #7					; number of rasters
ir_rloop:
		LDY #BAN_WDT-1		; max. horiz offset 
ir_bloop:
			LDA (ptr), Y
			EOR #$FF		; invert this byte
			STA (ptr), Y
			DEY
			BPL ir_bloop
		LDA ptr
		CLC
		ADC #RST_BYT		; next raster in screen
		STA ptr
		BCC ir_nw
			INC ptr+1
ir_nw:
		DEX					; one less raster
		BNE ir_rloop
	LDX select				; retrieve and return
	RTS

; ** clear playfield structure **
; input
;	select	player [0,128]
; affects all registers plus whatever gen_col does
clearfield:
; should clear mode selection banner as well, pretty much like 'banner'
	LDX select
	LDA psum36, X			; check player (make sure X is preserved)
	STA ptr
	LDA #BANNER_PG			; two rows above centre
	STA ptr+1
	LDY #BAN_HGT			; banner rasters - 1?
	STY temp
clp_vloop:
		LDY #BAN_WDT-1		; max horizontal offset
		LDA #0				; will clear area
clp_hloop:
			STA (ptr), Y
			DEY
			BPL clp_hloop
		DEC temp			; one raster is ready
	BMI clp_end				; no more rasters
		LDA ptr
		CLC
		ADC #RST_BYT		; next raster in screen
		STA ptr
		BCC clp_vloop
			INC ptr+1		; there was page crossing
		BRA clp_vloop
clp_end:
	JSR gen_col				; create new column, display it and init coordinates
	JSR gen_col				; needs another one for the current jewel!
; init matrix
	LDY #LAST_V				; eeeeeeek
	TYA						; last visible tile index * new way
	ORA select				; include player bit d7
	TAX						; use as index, should be recovered later
cl_loop:
		STZ field, X		; until all visible tiles are clear
		DEX
		DEY					; one less
		BPL cl_loop
; sentinels won't ever change, can be always set for both players!
	LDY #VTOP_L				; first visible row index
cl_sent:
		LDA #$FF						; invalid tile
		STA field, Y					; left sentinel
		STA field+ROW_WDT+1, Y			; right sentinel
		STA field2, Y					; sentinels (2nd player)
		STA field2+ROW_WDT+1, Y
		TYA
		CLC
		ADC #ROW_OFF		; next row
		TAY
		BPL cl_sent
; bottom row of sentinels
	LDY #LASTROW+1
	LDA #$FF				; invalid tile
sfh_loop:
		STA field, Y
		STA field2, Y
		INY					; EEEEEEEEEEEEEEEEEEEEK
		BPL sfh_loop		; last one gets repeated, but no worries
	LDX select				; for uniformity
	STZ delta, X			; clear for drop counter
;	STZ delta+1, X
	RTS

; ** generate new column with 3 jewels ** should check here for room, actually
; input
;	select	player [0-128]
;	s_level	to allow magic jewels
; affects column, next_c, posit, colour* and all registers
gen_col:
	LDX select
; transfer new column into current
	LDY #JWL_COL			; jewels per column
gc_copy:
		LDA next_c, X
		STA column, X		; copy next column into actual one
		INX
		DEY
		BNE gc_copy
	LDX select				; restore player index
	LDA s_level, X			; check difficulty
	STA tempx				; must store somewhere eeeek
	LDY #JWL_COL			; now I need 3 jewels
; generate new jewel
gc_jwl:
		PHY
		JSR rnd
		TAY
		LDA jwl_ix, Y		; make it valid tile index
		PLY
		CMP #MAGIC_JWL		; is the magic jewel
		BNE gc_nomagic
			LDA tempx		; check stored difficulty
		BEQ gc_jwl			; not accepted in easy mode
; otherwise the magic jewel fills the whole column
			LDX select		; retrieve player index HERE eeek
			LDA #MAGIC_JWL	; magic tile index
			STA next_c, X
			STA next_c+1, X
			STA next_c+2, X	; store three jewels
			JSR magic_jewel	; adjust colour
			BRA was_magic
gc_nomagic:
		STA next_c, X		; set next jewel for this player
		INX
		DEY					; one jewel less
		BNE gc_jwl			; until the array is done
was_magic:
	LDX select				; get player eeeek
	TXA						; I need BOTH registers eeeeek
	ORA #INIT_COL			; first row (not visible), fourth column of every player
	STA posit, X			; position set as matrix index
	STA oldposit, X			; eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
;	JMP nextcol				; show new column and return

; ** show next column **
; input
;	select	player [0-128], displayed at (54,12) & (66,12), a 6-byte offset
;	select	player [0-128], displayed at (54,12) & (66,12), a 6-byte offset
; affects colour (via tileprn) and all registers
nextcol:
	LDA psum6, X			; check player for offset
	STA ptr
	LDA #FIELD_PG
	STA ptr+1				; pointer complete
	LDY #JWL_COL			; number of tiles per column
nc_loop:
		PHX
		PHY
		LDA next_c, X		; get jewel to be displayed
		JSR tileprn			; just show this tile
		PLY
		PLX
		INX					; next tile in column
		DEY
		BNE nc_loop			; all tiles in column done?
	LDX select				; eeeeeeeek
	RTS

; ** magic jewel colour animation **
; affects colour and all registers
magic_jewel:
	JSR rnd
	TAX
	LDY jwl_ix, X			; get some valid colour index
	LDX magic_colour, Y		; get some valid colour mask
	LDY select
	STX mag_col, Y			; set colour mask for magic jewel only
	LDX select				; restore as usual
	RTS

; **********************
; *** sound routines ***
; **********************
match_snd:
; ** sound after matching, depending on number of them **
; input Y=0...12 for number of achieved group (plays higher)
; affects all registers!
	PHY
	LDA m_tone+2, Y			; initial value
	JSR tone				; play
	PLY
	PHY
	LDA m_tone+1, Y			; ditto for second one, a semitone lower
	JSR tone
	PLY
	LDA m_tone, Y			; last tone
;	JMP tone				; will fall and return

tone:
; ** play tone for 50 cycles **
; input A	= period (10+5y)
	LDX #99					; 100 semicycles
; * might call x_tone with X	= number of semicycles *
x_tone:
	SEI						; disable interrupts!
s_tone:
		STX IOBeep
		TAY					; reload frecuency
s_cyc:
			DEY
			BNE s_cyc		; delay for tone
		DEX					; next semicycle
		BPL s_tone			; will end at zero, thus buzzer off
	CLI						; reenable interrupts!
	RTS

pulse:
; ** play short single pulse **
	LDX #43					; will do ~200 µs
	STX IOBeep				; enable...
ps_loop:
		DEX
		BNE ps_loop			; ends with buzzer off
	STX IOBeep
	LDX select				; restore for convenience
	RTS

; *********************************
; *** interrupt service routine ***
; *********************************
isr:
	PHA
	PHX						; eeeeek best ASAP
	PHY
	INC ticks
	LDA ticks
	AND #1					; check even/odd
	BNE tk_nw
		INC ticks_l			; will increment every each other
tk_nw:
	JSR read_pad
; read keyboard as emulated gamepads (assume standard 5x8 keyboard is used)
	LDA kbd_ok				; is keyboard enabled?
	BEQ isr_fin
; check for suitable keys and emulate gamepad input
; player 1 -- W=up, ASD>ldr, XC=fire, ShiftZ=start
; player 2 -- I=up, JKL>ldr, AltSpace=fire,  NM=start
;	col1 > Sp Cr Sh P  0  A  Q  1	> f2· s1· · L1· ·
;	col2 > Al L  Z  O  9  S  W  2	> f2R2s1· · D1U1·
;	col3 > M  K  X  I  8  D  E  3	> s2D2f1U2· R1· ·
;	col4 > N  J  C  U  7  F  R  4	> s2L2f1· · · · ·
;	col5 never used (BHVY6GT5)
; with a nice trick these can be index of a 64-byte table per player
; d7d6d5d4d3d2d1d0 > 0 0 d7 d6 d5 d4 C  d2 (C = d1 on column 2) via LSR, LSR, BCC*, ORA#2, *
; generic tables (may be interlaced, as only 4 columns are used) should look like...
;				player 1			player 2
;	col 1	>	· · t · · L		>	A · · · · ·
;	col 2	>	· · e · U D		>	B R · · · ·
;	col 3	>	· · B · · R		>	e D · U · ·
;	col 4	>	· · A · · ·		>	t L · · · ·
; whereas the entries are in the usual AtBeULDR format
		LDY #3				; column 4 and below
col_loop:
			LDA pow_col, Y	; get current column bit, note offset EEEEEK
			STA IO9kbd		; select from keyboard
			LDA IO9kbd		; get row
;			LSR				; convert into 64-byte index
;			LSR
			BIT #2			; * possible CMOS optimisation, four cycles faster
			BEQ no_d1		; * instead of BCC
				ORA #8		; * instead of #2
no_d1:
;			ASL				; times four for interlacing!
;			ASL
			AND #%11111100	; * clear lowest bits for interlacing
			ORA id_table, Y	; add interlaced offset
			TAX
			LDA kbd2pad0, X	; get equivalent pad bits
			ORA pad0val
			STA pad0val		; add to actual pad bits
			LDA kbd2pad1, X	; ditto for player 2
			ORA pad1val
			STA pad1val
			DEY
			BPL col_loop	; finish all columns
		PLY
		PLX
isr_fin:
	PLA
isr_end:					; common interrupt exit
	RTI

code_end:					; for reference

; ********************
; *** picture data ***
; ********************
splash:
	.bin	0, 0, "art/start.rle"
playfield:
	.bin	0, 0, "art/columns.rle"

#ifndef	POCKET
pre_io:						; this should be BEFORE I/O page!
	.dsb	$E000-*, $FF	; skip I/O page!
#endif

sprites:
	.dsb	32, 0									; first tile is blank
	.bin	0, 0, "art/jewels.sv4"					; uncompressed file, 4-byte wide!
	.dsb	32, 0									; add an extra blank tile
gameover:
	.bin	0, 0, "art/gameover.sv24"				; uncompressed, 24-byte wide
numbers:
	.bin	0, 0, "art/numbers.sv20"				; generic number images, 20-byte wide
levelsel:
	.bin	0, 0, "art/level.sv24"					; uncompressed, 24-byte wide, 23 lines tall

art_end:					; for reference

; **************
; *** tables ***
; **************

	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment to avoid penalty
#if ((* & $FF00) == $DF00)
	.dsb	$100, $FF		; skip IO page!
#endif

; *** data for player 1 *** (player 2 uses 128-byte offset)
id_table:
	.byt	0, 1, 2, 3, 4, 5, 6, 7		; useful for ADX/ADY emulation, note reindex at 0

play_col:					; player display colour
	.byt	$99				; sky blue for player 1

num_bl:						; base addresses of numeric displays (LSB, player 1)
	.byt	$5C				; level $6C5C
	.byt	$4A				; jewels $7E4A
	.byt	$07				; score $6007
num_bh:						; base addresses of numeric displays (MSB, player 1)
	.byt	$6C				; level $6C5C
	.byt	$7E				; jewels $7E4A
	.byt	$60				; score $6007

disp_id:
	.byt	0, 1, 3, 6		; starting offsets on BCD array (player 1)
disp_top	= disp_id+1		; limit index for 1, 2 or 3 BCD bytes (2-4-6 digits, player 1)

psum6:
	.byt	27				; 6-byte offset for next piece
poff9:
	.byt	0				; 9-col offset, player 1
psum36:
	.byt	2				; 36-byte x-position, player 1

; * common data *
; multimedia
cmpr_pics:					; to be displayed by dispic
	.word	splash
	.word	playfield

magic_colour:
	.byt	$FF, $22, $33, $77, $55, $99, $AA, $FF	; six jewel colours [1..6], note first and last entries void

m_tone:
;			C#6  D6   D#6  E6   F6   F#6  G6  G#6 A6  A#6 B6  C7  C#7 D7  D#7
	.byt	136, 129, 121, 114, 108, 102, 96, 90, 85, 80, 76, 71, 67, 63, 60	; C#6 to D#7

; * gameplay *
ix_dir:
	.byt	1, 8, 255, 0, 0	; matrix index displacement (R/D/L/rot/none)

bit_pos:
	.byt	%00000001, %00000010, %00000100, %00001000		; allowable movements for each direction, ····xLDR

; initial level & scores according to difficulty
ini_lev:
	.byt	0, 5, $10		; initial level (BCD)
ini_lbin:
	.byt	0, 5, 10		; initial level (binary)
ini_score:
	.byt	0, 1, 2			; high byte initial score (BCD)
ini_sc_l:
	.byt	0, 0, $50		; middle byte initial score (BCD)

; base score for matching runs (0...9, which is the expected maximum)
base_sc:
	.byt	  0,  0,  0, 15, 30, 45, 60, 75, 90, 105			; half of the original game 

; new values for up to 10 levels (coarse granularity, alas)
ini_spd:
	.byt	125, 87, 74, 56, 42, 32, 25, 18, 14, 11, 8

; * keyboard data *
pow_col:
	.byt	1, 2, 4, 8		; read up to 4 columns

	.dsb	$80*((* & $7F) <> 0) - (* & $7F), $FF	; HALF page alignment EEEEEEK

; *** data for player 2 *** (labels for convenience, always +128)

id_table2:
	.byt	128, 129, 130, 131, 132, 133, 134, 135		; no longer reindex at 0

play_col2:					; player display colour
	.byt	$BB				; lavender pink for player 2

num_bl2:					; base addresses of numeric displays (LSB, player 2)
	.byt	$60				; level $7960 (!)
	.byt	$6E				; jewels $7E6E
	.byt	$2D				; score $602D
num_bh2:					; base addresses of numeric displays (MSB, player 2)
	.byt	$79				; level $7960 (!)
	.byt	$7E				; jewels $7E6E
	.byt	$60				; score $602D

disp_id2:
	.byt	128, 129, 131, 134			; starting offsets on BCD array (player 2)
disp_top2	= disp_id2+1				; limit index for 1, 2 or 3 BCD bytes (2-4-6 digits, player 2)

psum6_2:
	.byt	33				; 6-byte offset for next piece, player 2
poff9_2:
	.byt	9				; 9-col offset, player 2
psum36_2:
	.byt	38				; 36-byte offset, player 2

; any more?

	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment to avoid penalty

; *** 2x256-byte keyboard to pad tables ***
#include "kbd2pad.s"

; this table preferably goes in another full page
jwl_ix:						; convert random byte into reasonable tile index [1...6] with a few magic tiles [7]
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	;  0...23
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 24...47
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 48...71
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 72...95
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 96...119
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 120...143
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 144...167
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 168...191
#ifndef	MAGIC
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 192...215
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 216...239
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6										; 240...251
#else
#echo More magic tiles!
	.byt	7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7	; 192...215
	.byt	7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7	; 216...239
	.byt	7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7										; 240...251
#endif
	.byt	7, 7, 7, 7		; 252...255 are the magic tiles

; BCD conversion tables
bcd_id:
	.byt	$00, $01, $02, $03, $04, $05, $06, $07, $08, $09
	.byt	$10, $11, $12, $13, $14, $15, $16, $17, $18, $19
	.byt	$20, $21, $22, $23, $24, $25, $26, $27, $28, $29
	.byt	$30, $31, $32, $33, $34, $35, $36, $37, $38, $39
	.byt	$40, $41, $42, $43, $44, $45, $46, $47, $48, $49
	.byt	$50, $51, $52, $53, $54, $55, $56, $57, $58, $59
	.byt	$60, $61, $62, $63, $64, $65, $66, $67, $68, $69
	.byt	$70, $71, $72, $73, $74, $75, $76, $77, $78, $79
	.byt	$80, $81, $82, $83, $84, $85, $86, $87, $88, $89
	.byt	$90, $91, $92, $93, $94, $95, $96, $97, $98, $99

; powers of two in BCD
bcd_p_h:					; high byte
	.byt	  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   1,   3
bcd_p_m:					; mid byte
	.byt	  0,   0,   0,   0,   0,   0,   0,   1,   2,   5, $10, $20, $40, $81, $63, $27
bcd_p_l:					; low byte
	.byt	  1,   2,   4,   8, $16, $32, $64, $28, $56, $12, $24, $48, $96, $92, $84, $68

; reverse BCD-to-binary table, any use?
bcd2bin:
	.byt	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	10, 11, 12, 13, 14, 15, 16, 17, 18, 19, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	20, 21, 22, 23, 24, 25, 26, 27, 28, 29, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	30, 31, 32, 33, 34, 35, 36, 37, 38, 39, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	40, 41, 42, 43, 44, 45, 46, 47, 48, 49, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	50, 51, 52, 53, 54, 55, 56, 57, 58, 59, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	60, 61, 62, 63, 64, 65, 66, 67, 68, 69, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	70, 71, 72, 73, 74, 75, 76, 77, 78, 79, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	80, 81, 82, 83, 84, 85, 86, 87, 88, 89, $FF, $FF, $FF, $FF, $FF, $FF
	.byt	90, 91, 92, 93, 94, 95, 96, 97, 98, 99, $FF, $FF, $FF, $FF, $FF, $FF

data_end:

#ifdef	POCKET
file_end:					; for pocket format
#else
; ***************************
; *** ROM padding and end ***
; ***************************
	.dsb	$FFD6-*, $FF	; ROM fill
; standard ROM tail
	.asc	"DmOS"			; minimOS-compliant signature
; interrupt handlers fit here
irq_hndl:
	JMP (irq_ptr)			; standard IRQ handler @ $FFDA
nmi_hndl:
	JMP (nmi_ptr)			; standard NMI handler @ $FFDD
	.byt	$FF				; some padding
switch:
	JMP ($FFFC)				; devCart switching support $FFE1

	.dsb	$FFFA-*, $FF	; ROM fill, not using checksum
; 6502 hardware vectors
	.word	nmi_hndl		; NMI as warm reset
	.word	reset
	.word	irq_hndl

file_end:					; should be $10000 for ROM images
#endif
