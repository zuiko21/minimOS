; COLUMNS for Durango-X
; original idea by SEGA
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230619-0025

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

; ****************************
; *** constant definitions ***
; ****************************
#define	PAD_BUTTONS
#define	PAD_FIRE	%10000000
#define	PAD_STRT	%01000000
#define	PAD_B		%00100000
#define	PAD_SEL		%00010000
#define	PAD_UP		%00001000
#define	PAD_LEFT	%00000100
#define	PAD_DOWN	%00000010
#define	PAD_RGHT	%00000001

#define	MOV_LEFT	2
#define	MOV_RGHT	0
#define	MOV_DOWN	1
#define	MOV_ROT		3
#define	MOV_NONE	3

#define	FIELD_PG	$63
#define	BANNER_PG	$6C

#define	DISP_LVL	0
#define	DISP_JWL	1
#define	DISP_SCO	2

#define	STAT_OVER	0
#define	STAT_LVL	1
#define	STAT_PLAY	2
#define	STAT_BLNK	3
#define	STAT_DIE	4

#define	NUM_LVLS	3

#define	NUM_JWLS	10

#define	MAGIC_JWL	7

; *************************
; *** memory allocation ***
; *************************
; player-1 data (player 2 has 128-byte offset)
status	= 64				; player status [0=game over, 1=level select, 2=playing, 3=flashing?]
speed	= status+1			; 7-bit value between events (127 at level 0, halving after that, but never under 5?)
ev_dly	= speed+1			; 8-bit counter for next event (ditto)
s_level	= ev_dly+1			; selected difficulty
pad0mask= s_level+1			; gamepad masking values
pad1mask= pad0mask+128
pad0val	= pad0mask+1		; gamepad current status
pad1val	= pad0val+128
padlast	= pad0val+1			; last pad status
column	= padlast+1			; current column
next_c	= column+3			; next piece
posit	= next_c+3			; position in 8x16 matrix
bcd_arr	= posit+1			; level/jewels/score arrays [LJJSSS] in BCD
yb		= bcd_arr+6			; base row for death animation
die_y	= yb+1				; current death animation index (formerly Y)
mag_col	= die_y+1			; specific magic jewel colour animation
; common data (non-duplicated)
temp2	= mag_col+1			; now another temporary
temp	= temp2+1
select	= temp+1			; player iteration in main loop
bcd_lim	= select+1
colour	= bcd_lim+1
seed	= colour+1			; PRNG seed
; may let these at $FC for minimOS compliance
src		= seed+2			; $FC
ptr		= src+2				; $FE
; these save a few bytes and cycles in ZP
irq_ptr	= ptr+2				; $0200 is standard minimOS, may save a few bytes putting these on ZP
ticks	= irq_ptr+2			; $0206 but no NMI or BRK in use, and only 8-bit!!
ticks_h	= ticks+1
kbd_ok	= ticks_h+1			; if non-zero, supported keyboard has been detected
col_sel	= kbd_ok			; keyboard column counter
; player 2 data for convenience
status2	= 192				; player status [0=game over, 1=level select, 2=playing, 3=flashing?]
speed2	= status2+1			; 7-bit value between events (127 at level 0, halving after that, but never under 5?)
ev_dly2	= speed2+1			; 8-bit counter for next event (ditto)
s_level2= ev_dly2+1			; selected difficulty
padlast2= pad1val+1			; last pad status
column2	= padlast2+1		; current column
next_c2	= column2+3			; next piece
posit2	= next_c2+3			; position in 8x16 matrix
bcd_arr2= posit2+1			; level/jewels/score arrays [LJJSSS] in BCD
yb2		= bcd_arr2+6		; base row for death animation
die_y2	= yb2+1				; current death animation index (formerly Y)
mag_col2= die_y2+1			; specific magic jewel colour animation

_end_zp	= mag_col2+1
; these MUST be outside ZP, change start address accordingly
field	= $0200				; 8x16 (6x13 visible) game status arrays (player2 = +128)
;field2	= $0280

; *****************
; *** main code ***
; *****************

* = $C000					; will 16K suffice?
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"columns", 0	; C-string with filename @ [8], max 238 chars
	.asc	"Original idea by SEGA"		; comment with IMPORTANT attribution
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $F8 - *, $FF

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5800			; time, 11.00
	.word	$5673			; date, 2023/3/19
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

reset:
	SEI						; usual 6502 init
	CLD
	LDX #$FF
	TXS
; Durango-X specifics
#ifdef	DEBUG
	lda #$f0
	sta $df94	;enable Virtual Serial Port
#endif
	STX IOAie				; enable interrupts, as X is an odd value
;	STZ ticks
	LDA #$38				; colour mode, screen 3, RGB
	STA IO8attr				; set video mode
; show splash screen
	INX						; was $FF, now 0 is the index of compressed file entry
	JSR dispic				; decompress!
; * init game stuff * actually whole ZP
	LDX #0
;	TXA
rst_loop:
		STZ 0, X			; was status, X [CMOS only, use TXA/STA otherwise]
		INX
		BNE rst_loop
; setup controllers etc (assume minstrel-type kbd)
;	STZ pad0mask
;	STZ pad1mask			; need these reset the very first time
	JSR read_pad			; get initial values
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
	CLI						; enable interrupts!
; let at least one player start the game
	JSR continue			; wait for user action
	LDA ticks
	STA seed
	STY seed+1				; quite random seed
	STX select				; save selected player
; display game field
	LDX #2					; set compressed file index
	JSR dispic				; decompress!
; then level selection according to player
	LDX select				; retieve selected player
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
;		JMP next_player		; does this make sense?
chk_stat:
	LDA status, X			; check status of current player
; * * STATUS 0, game over * *
;	CMP #STAT_OVER
	BNE not_st0
		TYA					; get this player controller status
		BIT #PAD_FIRE|PAD_B|PAD_SEL|PAD_STRT	; start new game
			BEQ not_st0		; not if not pressed...
		CMP padlast, X
			BEQ not_st0		; ...or not just released
		STA padlast, X		; anyway, register this press
		LDA #STAT_LVL
		STA status, X		; go into selection status
		JSR sel_ban			; after drawing level selection menu
		BRA loop			; reload player status
not_st0:
	LDA status, X			; check status of current player
; * * STATUS 1, level selection * *
	CMP #STAT_LVL			; selecting level?
	BNE not_st1
; selecting level, check up/down and fire/select/start
		TYA					; get this player controller status
		BIT #PAD_DOWN		; increment level
		BEQ not_s1d			; not if not pressed
			CMP padlast, X	; still pressing?
		BEQ not_st1			; ignore either!
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
		BEQ not_st1			; ignore!
			STA padlast, X	; anyway, register this press
			JSR inv_row		; deselect current
			DEC s_level, X	; decrement level
			BPL s1_nw		; wrap if negative
				LDA #NUM_LVLS-1			; max level index
				STA s_level, X
				BRA s1_nw	; common ending
not_s1u:
		BIT #PAD_FIRE|PAD_B|PAD_SEL|PAD_STRT	; select current level
		BEQ not_st1
; level is selected, set initial score and display
			CMP padlast, X	; still pressing?
		BEQ not_st1			; ignore!
			STA padlast, X	; anyway, register this press
			LDY s_level, X	; selected level
			LDA ini_spd, Y
			STA speed, X	; eeeeek
			LDA ini_lev, Y	; level as index for initial value
			PHA				; later...
			LDA ini_score, Y
			STA bcd_arr+3, X			; score counter eeeeek
			PLA
			STA bcd_arr, X				; place initial values in adequate array indices
			LDY #DISP_LVL
			JSR numdisp
			LDY #DISP_JWL
			JSR numdisp
			LDY #DISP_SCO
			JSR numdisp		; display all values
; and go into playing mode
			JSR clearfield	; init game matrix and all gameplay status
			LDX select
			LDA speed, X	; eeeeek
			CLC
			ADC ticks
			STA ev_dly, X	; compute delay until next event
			LDA #STAT_PLAY
			STA status, X
; TODO * I believe some screen init is needed here * TODO
			BRA not_st1
s1_nw:
		JSR inv_row			; mark new value
		LDY pad0val, X		; restore and continue evaluation
not_st1:
	LDA status, X
; * * STATUS 2, play * * IN THE MAKING
	CMP #STAT_PLAY			; playing?
		BEQ is_st2 
	JMP not_st2
is_st2:
		TYA					; get this player controller status
		BIT #PAD_LEFT		; move to the left?
		BEQ not_s2l			; not if not pressed
			CMP padlast, X	; still pressing?
			BNE is_s2l 
		JMP not_st2			; ignore either!
is_s2l:
			STA padlast, X	; anyway, register this press
			LDY #MOV_LEFT	; otherwise, x is one less
			BRA s2end
not_s2l:
		BIT #PAD_RGHT		; move to the right?
		BEQ not_s2r			; not if not pressed
			CMP padlast, X	; still pressing?
			BNE is_s2r
		JMP not_st2			; ignore either!
is_s2r:
			STA padlast, X	; anyway, register this press
			LDY #MOV_RGHT	; otherwise, x is one more
			BRA s2end
not_s2r:
		BIT #PAD_DOWN		; let it drop?
		BEQ not_s2d			; not if not pressed
;			CMP padlast, X	; still pressing? don't care, will fall asap
;		BEQ not_st2			; ignore either!
;			STA padlast, X	; anyway, register this press
			LDY #MOV_DOWN	; otherwise, y is one more
			BRA s2end
not_s2d:
		BIT #PAD_FIRE|PAD_B	; flip?
		BEQ not_s2f			; not if not pressed
			CMP padlast, X	; still pressing?
		BEQ not_st2			; ignore either!
			STA padlast, X	; anyway, register this press
; piece rotation
			LDA #1
			STA IOBeep		; activate sound...
;			LDY poff6, X	; reindex for column arrays
			LDY select		; ***
			LDA column+2, Y
			PHA				; save last piece
			LDA column+1, Y
			STA column+2, Y
			LDA column, Y
			STA column+1, Y			; rotate the rest
			PLA
			STA column, Y	; and wrap the last one
			LDY posit, X	; display recently rotated column!
			JSR coldisp
			STZ IOBeep		; ...and finish audio pulse
			LDY #MOV_ROT	; this was a rotation, thus no change
			BRA s2end
/**/
not_s2f:
		LDY #MOV_NONE		; eeek
; *** CODE UNDER TEST ***
; first of all, check for magic jewel
		LDX select
		LDA column, X
		CMP #MAGIC_JWL
		BNE do_advance
			LDY posit, X
			JSR coldisp
			LDY #MOV_NONE
do_advance:
; *** *** ***
; in case of timeout, put piece down... or take another
		LDA ticks
		CMP ev_dly, X
		BMI s2end			; if timeout expired... but not BCC eeeeeek
;			LDA ev_dly, X
			CLC
			ADC speed, X
			STA ev_dly, X	; update time for next event
; check if possible to move down * TODO * should use #MOV_DOWN

			LDY posit, X
			LDA #0
			JSR tiledis		; clear topmost tile
			LDX select		; eeeeeek
			LDA posit, X	; reload original position
			CLC
			ADC #8
			STA posit, X	; one row down
			JSR coldisp		; show all column
			LDY #MOV_NONE

s2end:
; move according to Y-direction, if possible
;			JSR chkroom
;*/
		LDA posit, X
		CLC
		ADC ix_dir, Y			; add combined offset
		STA posit, X
; test, check bottom
		AND #$7F
		CMP #%01100000	; row 12
		BCC not_move
; TODO * so far, just die *
;		JSR palmatoria
;		JMP next_player
		LDA #STAT_DIE		; will trigger palmatoria
		STA status, X		; eeeeeeeeeeeeeeeeeeeeek
; prepare loops for the new status
		LDA #113			; 14*8+1
		ORA id_table, X		; first column in new coordinates, plus player offset
		STA die_y, X		; eeeek
		LDY #15				; needs 16 iterations non-visible rows
		STY yb, X
; start this animation immediatly, then once every 5 ticks (10 interrupts ~ 2 fields)
		LDA ticks
		STA ev_dly, X
; now will display the gameover animation concurrently!

not_move:
		LDX select
		LDY pad0val, X		; restore and continue evaluation, is this neeed?
not_st2:

; * * STATUS 3, blink * * TO DO
	LDA status, X
; * * STATUS 4, die * *
	CMP #STAT_DIE			; just died?
	BNE not_st4
		LDA ticks
		CMP ev_dly, X
		BMI not_st4			; if timeout expired... but not BCC
			CLC
			ADC #5			; next in 5 ticks
			STA ev_dly, X	; update time for next event
			JSR palmatoria	; will switch to STAT_OVER when finished
not_st4:

next_player:
	LDA select
	EOR #128				; toggle player in event manager
	STA select
; check possible colour animation on magic jewel
	LDX select				; just in case... or just TAX?
	LDA next_c, X
	CMP #MAGIC_JWL			; is the magic jewel next?
	BNE nx_nonmagic
		JSR magic_jewel		; pick one random colour
		JSR nextcol			; and redisplay it
nx_nonmagic:
; TO DO * the same with player column *
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
coldisp:
; this displays falling column at index Y
	LDY posit, X			; get current position
	PHY						; eeeeeek
	LDA column, X
	JSR tiledis				; show top tile
	PLA
	CLC
	ADC #8
	PHA
	TAY
	LDX select
	LDA column+1, X
	JSR tiledis				; middle one
	PLA
	CLC
	ADC #8
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
; affects temp2 and all registers (not worth saving here as two entry points)
tiledis:
	STA temp2				; eeeeek
	DEY						; let's be consistent...
	TYA						; will be MSB...
	AND #%01111000			; filter row
	CMP #120
		BCS td_exit			; last row (15) is not-visible
	CMP #16
		BCC td_exit			; first two rows aren't either
	SBC #16					; first visible row is 2 (C known set)
	LSR
	LSR						; ...two pages per row
	ADC #FIELD_PG			; place into screen 3, 12 rasters below
	STA ptr+1				; first address is ready!
	TYA
	AND #128
	TAX						; just sign as player index
	TYA
	AND #%00000111			; filter column
	ASL
	ASL						; times four bytes per column
	ADC psum36, X			; first pixel in line is 4, perhaps with 36-byte offset, C known clear
	STA ptr					; LSB is ready
	LDA temp2				; eeeeek
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
	LDX #8					; number of rasters
s_rloop:
		LDY #3				; max index per raster
s_bloop:
			LDA (src), Y	; get sprite data...
			AND colour
			STA (ptr), Y	; ...and place on screen
			DEY
			BPL s_bloop		; for all 4 bytes in raster
		LDA src
		CLC
		ADC #4				; next raster in sprite file
		STA src
		BCC s_rnw
			INC src+1		; in case of page crossing
s_rnw:
		LDA ptr
		CLC
		ADC #64				; next raster in screen
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
; affects colour, bcd_lim and all registers

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
		ADC #63				; one raster minus 2 bytes of a number
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

; ** death animation ** (concurrent IN THE MAKING)
; input
;	select	player [0,128]
; affects status, s_level, yb, die_y, temp and all registers
palmatoria:
; these will go after the last one
; id while changing status
		LDX select			; eeeeeeeeeek
		LDA #7				; initial explosion tile - 1
		LDY die_y, X
dz_tile:
			INC				; next tile
			CMP #NUM_JWLS+1
			BNE dz_nw
				LDA #0		; 0, then exit
dz_nw:
			STA temp		; will hold current tile
			LDX #6			; six columns
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
		SBC #40				; 5 rows back
		LDX select
		STA die_y, X		; store for next call!
; no wait here, will be called every 10 interrupts
		LDA #30
		JSR tone			; brief beep!
		LDX select
		DEC yb, X			; one less row
		BPL go_exit			; not the last, give CPU back
; all finished, change status to definitive
	LDX select
;	LDA STAT_OVER			; conveniently zero, and X is proper player offset
	STZ status, X			; back to gameover status
	STZ s_level, X			; reset this too! eeeeeeeek
; now print the game over banner
	LDY #<gameover
	LDX #>gameover
	STY src
	STX src+1				; set origin pointer
	LDA temp				; get X for player field
	LDY #10					; raster counter
; * alternate entry to print a 24*x banner *
;	Y		rasters - 1
;	select	player [0-128]
;	src		points to .sv24
; affects temp and all registers
banner:
	LDX select
	STY temp				; counter in memory
	LDA psum36, X
	STA ptr
	LDA #BANNER_PG			; two rows above centre
	STA ptr+1
go_vloop:
		LDY #23				; max horizontal offset
go_hloop:
			LDA (src), Y
			STA (ptr), Y
			DEY
			BPL go_hloop
		DEC	temp			; one raster is ready
	BMI go_exit
		LDA src
		CLC
		ADC #24				; next raster in image
		STA src
		BCC go_nw
			INC src+1
go_nw:
		LDA ptr
		CLC
		ADC #64				; next raster in screen
		STA ptr
		BCC go_vloop
			INC ptr+1		; there was page crossing
		BRA go_vloop
go_exit:
	RTS

; TO DO ** check for available movements ** TO DO
chkroom:
LDA#0
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
	LDX #128				; if arrived here, was player 2
release:
; must wait for release also
		BIT pad0val
	BNE release
		BIT pad1val
	BNE release
	RTS

; ** VSYNC **
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
	LDA #192				; longest G5
	LDX #0
	JSR tone
; display banner
	LDY #<levelsel
	LDX #>levelsel
	STY src
	STX src+1				; set origin pointer
	LDY #22					; raster counter
	JMP banner				; display and return

; ** mark one row as inverted **
; input
;	select	player [0,128]
;	s_level	currently selected
; affects all registers
inv_row:
	LDX select
	LDA psum36, X			; horizontal position in raster
	STA ptr
	LDA s_level, X			; current level determines row
	ASL						; times two
	ADC #BANNER_PG			; into banners area
	STA ptr+1
	LDX #7					; number of rasters
ir_rloop:
		LDY #23				; max. horiz offset 
ir_bloop:
			LDA (ptr), Y
			EOR #$FF		; invert this byte
			STA (ptr), Y
			DEY
			BPL ir_bloop
		LDA ptr
		CLC
		ADC #64				; next raster in screen
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
	LDY #22					; banner rasters - 1
	STY temp
clp_vloop:
		LDY #23				; max horizontal offset
		LDA #0				; will clear area
clp_hloop:
			STA (ptr), Y
			DEY
			BPL clp_hloop
		DEC temp			; one raster is ready
	BMI clp_end				; no more rasters
		LDA ptr
		CLC
		ADC #64				; next raster in screen
		STA ptr
		BCC clp_vloop
			INC ptr+1		; there was page crossing
		BRA clp_vloop
clp_end:
	JSR gen_col				; create new column, display it and init coordinates
	JSR gen_col				; needs another one for the current jewel!
; init matrix
	LDA select				; check player
	CLC
	ADC #118				; last visible tile
	TAX						; should be recovered later
	TAY						; faster counter
cl_loop:
		STZ field, X		; until all visible tiles are clear
		DEX
		DEY					; one less
		BPL cl_loop
; sentinels won't ever change, can be always set for both players!
	LDY #16					; first visible row index
cl_sent:
		LDA #$FF			; invalid tile
		STA field, Y		; left sentinel
		STA field+7, Y		; right sentinel
		STA field+128, Y	; sentinels (2nd player)
		STA field+135, Y
		TYA
		CLC
		ADC #8				; next row
		TAY
		BPL cl_sent
; bottom row of sentinels
	LDY #121
	LDA #$FF				; invalid tile
sfh_loop:
		STA field, Y
		STA field+128, Y
		INX
		BPL sfh_loop		; last one gets repeated, but no worries
	RTS

; ** generate new column with 3 jewels **
; input
;	select	player [0-128]
;	s_level	to allow magic jewels
; affects column, next_c, posit, colour* and all registers
gen_col:
	LDX select
; transfer new column into current
	LDY #3					; jewels per column
gc_copy:
		LDA next_c, X
		STA column, X		; copy next column into actual one
		INX
		DEY
		BNE gc_copy
	LDX select				; restore player index
	LDA s_level, X			; check difficulty
	STA temp2				; must store somewhere eeeek
	LDY #3					; now I need 3 jewels
; generate new jewel
gc_jwl:
		PHY
		JSR rnd
		TAY
		LDA jwl_ix, Y		; make it valid tile index
		PLY
		CMP #7				; is the magic jewel
		BNE gc_nomagic
			LDA temp2		; check stored difficulty
		BEQ gc_jwl			; not accepted in easy mode
; otherwise the magic jewel fills the whole column
			LDX select		; retrieve player index
			LDA #7			; magic tile index
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
;	LDX #$FF
;	STX colour				; respect original jewel colours
was_magic:
	LDX select
; alternative entry point, just in case (X = player 0/128)
	TXA						; player offset
	CLC
	ADC #3					; first row (not visible), fourth column of every player
	STA posit, X			; position set as matrix index
;	JMP nextcol				; show new column and return

; ** show next column **
; input
;	select	player [0-128], displayed at (54,12) & (66,12), a 6-byte offset
;	select	player [0-128], displayed at (54,12) & (66,12), a 6-byte offset
; affects colour (via tileprn) and all registers
nextcol:
	LDX select
	LDA psum6, X			; check player for offset
	STA ptr
	LDA #FIELD_PG
	STA ptr+1				; pointer complete
	LDY #3					; number of tiles per column
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
	RTS
; **********************
; *** sound routines ***
; **********************
match:
; ** sound after matching, depending on number of them **
; input Y=0...12 for number of achieved group (plays higher)
	PHY
	LDA m_tone+2, Y			; initial value
	JSR tone				; play
	PLY
	PHY
	LDA m_tone+1, Y			; ditto for second one, a semitone lower
	JSR tone
	PLY
	LDA m_tone+1, Y			; last tone
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
	RTS

; *********************************
; *** interrupt service routine ***
; *********************************
isr:
	PHA
	INC ticks_h				; main will increment every other 2
	LDA ticks_h
	AND #1					; check even/odd
	BNE tk_nw
		INC ticks
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
		PHX					; eeeeek
		PHY
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

; ********************
; *** picture data ***
; ********************
splash:
	.bin	0, 0, "art/start.rle"
playfield:
	.bin	0, 0, "art/columns.rle"
sprites:
	.dsb	32, 0									; first tile is blank
	.bin	0, 0, "art/jewels.sv4"					; uncompressed file, 4-byte wide!
gameover:
	.bin	0, 0, "art/gameover.sv24"				; uncompressed, 24-byte wide
numbers:
	.bin	0, 0, "art/numbers.sv20"				; generic number images, 20-byte wide
levelsel:
	.bin	0, 0, "art/level.sv24"					; uncompressed, 24-byte wide, 23 lines tall
data_end:

; **************
; *** tables ***
; **************

	.dsb	$FB00-*, $FF	; padding to avoid cross-page speed penalty

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
cmpr_pics:					; to be displayed by dispic
	.word	splash
	.word	playfield

m_tone:
;			C#6  D6   D#6  E6   F6   F#6  G6  G#6 A6  A#6 B6  C7  C#7 D7  D#7
	.byt	136, 129, 121, 114, 108, 102, 96, 90, 85, 80, 76, 71, 67, 63, 60	; C#6 to D#7

ix_dir:
	.byt	1, 8, 255, 0, 0	; matrix index displacement (R/D/L/rot/none)

bit_pos:
	.byt	%00000001, %00000010, %00000100, %00001000		; allowable movements for each direction, ····xLDR

; initial level & scores according to difficulty
ini_lev:
	.byt	0, 5, $10		; initial level (BCD)

ini_score:
	.byt	0, 2, 5			; "third" byte initial score (BCD)

ini_spd:
	.byt	125, 32, 8;127, 3, 2		; initial speed value, halving each level, but never below 4 interrupts (note these are HALF values)

magic_colour:
	.byt	$FF, $22, $33, $77, $55, $99, $AA, $FF	; six jewel colours [1..6], note first and last entries void


	.dsb	$FB80-*, $FF	; *** padding to avoid cross-page speed penalty ***

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

; *** keyboard data ***
pow_col:
	.byt	1, 2, 4, 8		; read up to 4 columns

; any more?

	.dsb	$FC00-*, $FF	; padding to avoid cross-page speed penalty

; *** 2x256-byte keyboard to pad tables ***
	.bin	0, 0, "kbd2pad.s"

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
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 192...215
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6	; 216...239
	.byt	1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6										; 240...251
	.byt	7, 7, 7, 7		; 252...255 are the magic tiles

; ***************************
; *** ROM padding and end ***
; ***************************

	.dsb	$FFD6-*, $FF		; ROM fill
	.asc	"DmOS"				; minimOS-compliant signature
irq_hndl:
	JMP (irq_ptr)				; standard IRQ handler @ $FFDA

	.byt	$FF					; ROM fill for devCart support! $FFDD
autoreset:
	STZ $DFC0					; enable devCart ROM $FFDE
	JMP ($FFFC)					; devCart switching support $FFE1

	.dsb	$FFFA-*, $FF		; ROM fill, not using checksum
; 6502 hardware vectors
	.word	autoreset			; devCart remote RESET support
	.word	reset
	.word	irq_hndl
