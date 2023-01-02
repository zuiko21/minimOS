; COLUMNS for Durango-X
; original idea by SEGA
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230102-2357

; ****************************
; *** hardware definitions ***
; ****************************

screen3	= $6000
IO8attr	= $DF80
IO8blk	= $DF88
IO9nes0	= $DF9C
IO9nlat	= IO9nes0
IO9nes1	= $DF9D
IO9nclk	= IO9nes1
IOAie	= $DFA0
IOBeep	= $DFB0

; ****************************
; *** constant definitions ***
; ****************************
#define	PAD_FIRE	%10000000
#define	PAD_STRT	%01000000
#define	PAD_B		%00100000
#define	PAD_SEL		%00010000
#define	PAD_UP		%00001000
#define	PAD_LEFT	%00000100
#define	PAD_DOWN	%00000010
#define	PAD_RGHT	%00000001

#define	FIELD_PG	$63
#define	BANNER_PG	$6C

#define	DISP_LVL	0
#define	DISP_JWL	2
#define	DISP_SCO	4

#define	STAT_OVER	0
#define	STAT_LVL	1
#define	STAT_PLAY	2
#define	STAT_BLINK	3

#define	NUM_LVLS	3

; *************************
; *** memory allocation ***
; *************************
status	= 128				; array of player status [0=game over, 1=level select, 2=flashing entry?, 3=playing, 4=flashing?]
speed	= status+2			; array of 16-bit counters for next event
s_level	= speed+4			; array for selected difficulty [0-2]
pad0mask= s_level+2			; gamepad masking values
pad1mask= pad0mask+1
pad0val	= pad1mask+1		; gamepad current status
pad1val	= pad0val+1
padlast	= pad1val+1			; array of last pad status
column0	= padlast+2			; current column for player 1
next0	= column0+3			; next piece for player 1
column1	= next0+3			; current column for player 2
next1	= column1+3			; next piece for player 2
x_tile	= next1+3			; X coordinates 0...5 (note player 2 must be 9...14 instead)
y_tile	= x_tile+2			; Y coordinates 0...12
yb		= y_tile+2			; base row for death animation (may become an array)
limit	= yb+1				; right column for death animation (may become an array)
temp	= limit+1
select	= temp+1			; player iteration in main loop
bcd_arr	= select+1			; level/jewels/score arrays [LxJJSSS] in BCD for each player, includes _lim and colour $EC
bcd_lim	= bcd_arr+1			; $ED
colour	= bcd_arr+8			; $F4
seed	= bcd_arr+14		; PRNG seed, $FA
; may let these at $FC for minimOS compliance
src		= seed+2			; $FC
ptr		= src+2				; $FE
; these save a few bytes and cycles in ZP
irq_ptr	= ptr+2				; $0200 is standard minimOS, may save a few bytes putting these on ZP
ticks	= irq_ptr+2			; $0206 but no NMI or BRK in use, and only 16-bit
_end_zp	= ticks+2
; these MUST be outside ZP, change start address accordingly
fields	= $0200				; 8x16 (6x13 actually used) game status arrays (player2 = +128)
delta	= $0300				; screen change log [0=unchanged, 1=display, 2=flashing counter?]

; *****************
; *** main code ***
; *****************

* = $C000					; will 16K suffice?

reset:
	SEI						; usual 6502 init
	CLD
	LDX #$FF
	TXS
; Durango-X specifics
	STX IOAie				; enable interrupts, as X is an odd value
	STX ticks
	STX ticks+1				; will reach zero upon the very first interrupt
	LDA #$38				; colour mode, screen 3, RGB
	STA IO8attr				; set video mode
; show splash screen
	INX						; was $FF, now 0 is the index of compressed file entry
	JSR dispic				; decompress!
; TODO * may check here for supported keyboard presence (col 6 = $2C) * TODO
; * init game stuff *
	LDA #0
	LDX #seed-1-status		; will clear everything below seed
rst_loop:
		STA status, X
		DEX
		BPL rst_loop		; OK if less than 128 bytes
; setup controllers etc (assume minstrel-type kbd)
	STZ pad0mask
	STZ pad1mask			; need these reset the very first time
	JSR read_pad			; get initial values
	LDX pad0val
	LDY pad1val
	STX pad0mask			; ...and store them
	STY pad1mask
	JSR read_pad			; just for clearing the values
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
	STX seed+1				; quite random seed
	PHY						; save selected player
; display game field
	LDX #2					; set compressed file index
	JSR dispic				; decompress!
; then level selection according to player
	PLX						; retieve selected player
;lda#$f0
;sta$df94;enable VSP for debug
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
		JMP next_player		; does this make sense?
chk_stat:
	LDA status, X			; check status of current player
; * * STATUS 0, game over * *
;	CMP #STAT_OVER
	BNE not_st0
		TYA					; get this player controller status
		BIT #PAD_FIRE|PAD_SEL|PAD_STRT	; start new game
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
		BIT #PAD_FIRE|PAD_SEL|PAD_STRT	; select current level
		BEQ not_st1
; level is selected, set initial score and display
			CMP padlast, X	; still pressing?
		BEQ not_st1			; ignore!
			STA padlast, X	; anyway, register this press
			LDY s_level, X	; selected level
			LDA ini_lev, Y	; as index for initial value
			PHA				; later...
			LDA ini_score, Y
			LDY poff7, X	; reindex for BCD arrays
			STA bcd_arr+DISP_SCO, Y
			PLA
			STA bcd_arr+DISP_LVL, Y		; place initial values in adequate array indices
;			LDX select
			LDY #DISP_LVL
			JSR numdisp
			LDX select
			LDY #DISP_JWL
			JSR numdisp
			LDX select
			LDY #DISP_SCO
			JSR numdisp		; display all values
; and go into playing mode
			LDY select
			JSR clearfield	; init game matrix and all gameplay status
			LDX select
			LDA #STAT_PLAY
			STA status, X
; TODO * I believe some screen init is needed here * TODO
			BRA not_st1
s1_nw:
		JSR inv_row			; mark new value
		LDY pad0val, X		; restore and continue evaluation
not_st1:
	LDA status, X
; * * STATUS 2, play * * TODO TODO
	CMP #STAT_PLAY			; selecting level?
	BNE not_st2
		TYA					; get this player controller status
		BIT #PAD_LEFT		; move to the left?
		BEQ not_s2l			; not if not pressed
			CMP padlast, X	; still pressing?
		BEQ not_st2			; ignore either!
			STA padlast, X	; anyway, register this press
			JSR chkroom		; is it possible?
			ASL				; d7=0 means left OK
		BCS not_st2			; no way!
			DEC x_tile, X	; otherwise, x is one less
; TODO * update screen, delta etc * TODO
			JMP next_player
not_s2l:
		BIT #PAD_RGHT		; move to the right?
		BEQ not_s2r			; not if not pressed
			CMP padlast, X	; still pressing?
		BEQ not_st2			; ignore either!
			STA padlast, X	; anyway, register this press
			JSR chkroom		; is it possible?
			LSR				; d0=0 means right OK
		BCS not_st2			; no way!
			INC x_tile, X	; otherwise, x is one more
; TODO * update screen, delta etc * TODO
			JMP next_player
not_s2r:
		BIT #PAD_DOWN		; let it drop?
		BEQ not_s2d			; not if not pressed
;			CMP padlast, X	; still pressing? don't care, will fall asap
;		BEQ not_st2			; ignore either!
;			STA padlast, X	; anyway, register this press
			JSR chkroom		; is it possible?
			AND #64			; d6=0 means down OK
		BNE not_st2			; no way!
			INC y_tile, X	; otherwise, x is one more
; TODO * update screen, delta etc * TODO
			JMP next_player
not_s2d:
		BIT #PAD_FIRE		; let it drop?
		BEQ not_s2x			; not if not pressed
			CMP padlast, X	; still pressing?
		BEQ not_st2			; ignore either!
			STA padlast, X	; anyway, register this press
; piece rotation
			LDA #1
			STA IOBeep		; activate sound...
;			LDY poff6, X	; reindex for column arrays
			LDA poff6, X	; reindex for column arrays
ADC #3; hack to affect next piece
TAY
			LDA column0+2, Y
			PHA				; save last piece
			LDA column0+1, Y
			STA column0+2, Y
			LDA column0, Y
			STA column0+1, Y			; rotate the rest
			PLA
			STA column0, Y	; and wrap the last one
			STZ IOBeep		; ...and finish audio pulse
; TODO * update screen, delta etc * TODO
JSR nextcol; hack to display
			JMP next_player
not_s2x:


; TODO * so far, just die *
;		LDA poff9, X 
;		JSR palmatoria
;		JMP next_player

		LDY pad0val, X		; restore and continue evaluation, is this neeed?
not_st2:

next_player:
	LDA select
	EOR #1					; toggle player in event manager
	STA select
	JMP loop

; ***********************
; *** useful routines ***
; ***********************

; ** display one full screen from list index in X (always even) **
dispic:
	LDY cmpr_pics, X
	LDA cmpr_pics+1, X
	STY src
	STA src+1				; set source pointer
	LDY #<screen3
	LDX #>screen3			; screen 3 start address
	STY ptr
	STX ptr+1				; set destination pointer
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

; ** display column from 8x16 matrix (6x13 in use) ** TO DO
; input
;	X, Y	coordinates in matrix
;	A		player [0-1]
coldisp:
	LSR						; extract d0...
	ROR						; ...thru d7...
	LSR						; ...and into d6
	STA temp
	TYA
	ASL
	ASL
	ASL						; times 8 bytes per row
	ADC id_table, X			; add X (1...6), C clear
	ORA temp				; select between playfield
	TAX						; use as index
	LDY #3					; number of tiles per column
cd_loop:
		LDA fields, X		; get this tile
		
; ** display tile **
; input
;	X = column from player 1 left (player 2 is +9)
;	Y = row from top
;	A = tile number [0-10, where 0 is blank]
; affects 'colour'
tiledis:
	PHA
	TYA						; will be MSB...
	ASL						; ...two pages per row
	ADC #FIELD_PG			; place into screen 3, 12 rasters below
	STA ptr+1				; first address is ready!
	TXA
	ASL
	ASL						; times four bytes per column
	ADC #2					; first pixel in line is 4, C known clear
	STA ptr					; LSB is ready
	PLA						; retrieve tile index
; * external interface with tile index in A, for next piece *
tileprn:
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
	RTS

; ** show next column **
; input
;	X		player [0-1], displayed at (54,12) & (66,12), a 6-byte offset
nextcol:
	LDY poff6, X			; get byte offset
	TYA						; eeeeek
	CLC
	ADC #27					; start position for player 1
	STA ptr
	LDA #FIELD_PG
	STA ptr+1				; pointer complete
	LDX #3					; number of tiles per column
nc_loop:
		PHX
		PHY
		LDA next0, Y		; get jewel to be displayed
		JSR tileprn			; just show this tile
		PLY
		PLX
		INY					; next tile in column
		DEX
		BNE nc_loop			; all tiles in column done?
	RTS

; ** number display **
; input
;	Y		type of display (0=level, 2=jewels, 4=score)
;	X		player [0-1]
; fixed size; score=6 digits, level=2 digits, jewels=4 digits
; BCD data array [LxJJSSS] thus Y-indexed, then another one for player two
; fixed player 1 base addresses; score $6007 (14,0), level $6C5C (56,49), jewels $7E4A (20,121)
; player 2 level adds 52 Y-offset! (64,101)
; fixed player 2 offset; score $26 (90-14), level 4 (actually $D04) (64-56), jewels $24 (92-20)
numdisp:
	LDA play_col, X			; get colour according to player
	STA colour				; set colour
	TXA						; player offset
	CLC
	ADC disp_id, Y			; select type of display
	TAY						; offset to base address
	LDA num_bl, Y
	STA ptr
	LDA num_bh, Y
	STA ptr+1				; screen pointer is ready
	TAX						; this must be reset after each digit!
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
; actual printing, A has BCD nibble
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
		ADC #19				; advance to next raster in font
		TAX
		CPX #140			; within valid raster? (10 numbers * 2 bytes * 7 rasters)
		BCC n_rast
	INC ptr					; advance digit position
	INC ptr
	PLY
	PLX
	RTS

; ** death animation ** (non concurrent)
; input
;	A	player (0,9)
palmatoria:
	SEI						; *** temporary improvement until the concurrent version ***
	STA temp				; will be constant initial X
; this section is for clearing the next piece field, but no really necessary
;	TAX
;	BEQ dz_nok
;		LDX #6				; offset between arrays for next piece
;dz_nok:
;	LDY #3					; number of tiles per column
;dz_nxt:
;		STZ next0, X		; clear next tiles for this player
;		INX
;		DEY
;		BNE dz_nxt
;	LDX temp				; must be 0 or 1
;	BEQ dz_nnok
;		LDX #1				; ...and not 9
;dz_nnok:
;	JSR nextcol				; clear this part of the display
;	LDA temp				; retreive this value
	CLC
	ADC #6					; compute limit
	STA limit
	LDY #12					; yb=12
	STY yb
	LSR
	LSR
	LSR						; divide by 8, is 0 or 1
	TAX
;	LDA STAT_OVER			; conveniently zero
	STZ status, X			; back to gameover status
	STZ s_level, X			; reset this too! eeeeeeeek
dz_row:
		LDY yb
dz_tile:
		TYA
		CLC
		ADC #8				; initial explosion tile
		SEC
		SBC yb				; A = Y + 8 - yb
		CMP #11
		BCC dz_nw
			SBC #11			; 0, then 1 for exit
dz_nw:
		CPY #0
			BMI dz_show
		CPY #13
			BCS dz_show		; if Y >= 0 and Y <=12...
			LDX temp		; retrieve coordinates
dz_col:
				PHA
				PHX
				PHY
				JSR tiledis
				PLY
				PLX
				PLA
				INX			; next column
				CPX limit	; limit!!
				BCC dz_col
dz_show:
			INY				; next row
			DEC				; was tile zero (clear)?
			BPL dz_tile
dz_abort:
		JSR vsync			; wait a bit
		JSR vsync			; wait a bit
		LDA #30
		PHY
		JSR tone			; brief beep!
		PLY
		DEC yb				; next row
		LDA yb
		CMP #252			; -4
		BNE dz_row
	CLI						; *** for non-concurrent version only ***
; now print the game over banner
	LDY #<gameover
	LDX #>gameover
	STY src
	STX src+1				; set origin pointer
	LDA temp				; get X for player field
	LDX #10					; raster counter

banner:
; alternate entry to print a 24*x banner
;	X	= rasters - 1
;	A	= base column [0 for player 1, 9 for player 2]
;	src		points to .sv24
	ASL
	ASL						; times four bytes per column
	ADC #2					; two extra bytes
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
		DEX					; one raster is ready
	BMI go_end
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
go_end:
	RTS

; ** gamepad read **
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
;	Y	selected player (0,1)
continue:
	LDY #0					; default player number 1
	LDA #PAD_STRT|PAD_SEL|PAD_FIRE		; look for start, select or fire
wait_s:
		INX					; just for random seed setting
		BIT pad0val
	BNE release
		BIT pad1val
		BEQ wait_s
	INY						; if arrived here, was player 2
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
;	X	selected player position (0,1)
sel_ban:
	PHX						; eeeek
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
	LDX #22					; raster counter
	PLY						; proper player position
	LDA poff9, Y			; proper player index for banner
	JMP banner				; display and return

; ** mark one row as inverted **
; input
;	X	player (0,1)
inv_row:
	PHX						; must be kept
	LDA poff36, X
	CLC
	ADC #2					; 4 pixels more
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
	PLX						; retrieve and return
	RTS

; ** clear playfield structure **
; input
;	Y	player (0,1)
clearfield:
; init player data (this actually creates new column, should be separate)
	LDX poff6, Y			; jewel array offset
	PHY
cl_jwl:
		JSR rnd
		TAY
		LDA jwl_ix, Y		; make it valid tile index
		CMP #7				; is the magic jewel
		BNE cl_nomagic
			LDA s_level, Y	; check difficulty
		BEQ cl_jwl			; not accepted in easy mode
; otherwise the magic jewel fills the whole column
			PLY
			PHY				; otherwise retrieve and restore player index
			LDX poff6, Y	; jewel array offset
			LDY #3			; 3 jewels in column
			LDA #7			; magic tile index
cl_magic:
				STA column0, X
				DEY
				BNE cl_magic
			BRA cl_clear
cl_nomagic:
		STA column0, X		; set jewel for this player
		INX
		CPX #6
	BEQ cl_clear			; repeat for player 1...
		CPX #12
		BCC cl_jwl			; ...or for player 2
cl_clear:
	PLX
	PHX
	JSR nextcol				; display next column
	PLY
; init coordinates
	LDA poff9, Y			; tile offset
	CLC
	ADC #3					; fourth column of every player
	STA x_tile, Y
	LDA #254				; initial vertical position is -2
	STA y_tile, Y
; init matrix
	LDA poff128, Y			; check player
	CLC
	ADC #104				; 13th row
	TAX
cl_loop:
		LDA #$FF			; invalid tile
		STA fields, X		; sentinel
		STZ fields+1, X
		STZ fields+2, X
		STZ fields+3, X
		STZ fields+4, X
		STZ fields+5, X
		STZ fields+6, X
		STA fields+7, X		; sentinel
		TXA
		SEC
		SBC #8
		TAX
		AND #$7F			; eeeek
		BNE cl_loop
	LDA poff128, Y			; check player
	CLC
	ADC #8					; max horiz offset+1
	TAX
sfh_loop:
		LDA #$FF			; invalid tile
		STA fields-1, X		; note offsets
		STA fields+111, X
		DEX
		TXA
		AND #127			; player-independent offset
		BNE sfh_loop
; should clear mode selection banner as well, pretty much like 'banner'
	LDX #22					; banner rasters - 1
	LDA poff36, Y			; check player
	CLC
	ADC #2					; will be 2 for player 1, 38 for player 2
	STA ptr
	LDA #BANNER_PG			; two rows above centre
	STA ptr+1
clp_vloop:
		LDY #23				; max horizontal offset
		LDA #0				; will clear area
clp_hloop:
			STA (ptr), Y
			DEY
			BPL clp_hloop
		DEX					; one raster is ready
	BMI clp_end
		LDA ptr
		CLC
		ADC #64				; next raster in screen
		STA ptr
		BCC clp_vloop
			INC ptr+1		; there was page crossing
		BRA clp_vloop
clp_end:
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
;	JMP tone

tone:
; ** play tone for 50 cycles **
; input A	= period (10+5y)
; might call x_tone with X	= number of semicycles
	LDX #99					; 100 semicycles
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
	LDX #13					; will do ~65 µs
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
	INC ticks
	BNE tk_nw
		INC ticks+1
tk_nw:
	PHA						; only register to save for read_pad
	JSR read_pad
	PLA
; TODO * read keyboard too? * TODO * as keypad emulation
isr_end:					; common interrupt exit
	RTI

; **************
; *** tables ***
; **************
cmpr_pics:					; to be displayed by dispic
	.word	splash
	.word	field

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
	
id_table:
	.byte	0, 1, 2, 3, 4, 5, 6, 7		; useful for ADX/ADY emulation

num_bl:						; base addresses of numeric displays (LSB, interleaved $P2P1)
	.word	$605C			; level $6C5C, $7960 (!)
	.word	$6E4A			; jewels $7E4A, $7E6E
	.word	$2D07			; score $6007, $602D
num_bh:						; base addresses of numeric displays (MSB, interleaved $P2P1)
	.word	$796C			; level $6C5C, $7960 (!)
	.word	$7E7E			; jewels $7E4A, $7E6E
	.word	$6060			; score $6007, $602D
play_col:					; player display colour
	.byt	$99, $BB		; sky blue and lavender pink
disp_id:					; identity array (every 2)
	.byt	0, 7
	.byt	2, 9
	.byt	4, 11			; index value, also start index for BCD array (even=player1, odd=player2)
disp_top:
	.byt	1, 8
	.byt	4, 11
	.byt	7, 14			; limit index for 1, 2 or 3 BCD bytes (2-4-6 digits)

m_tone:
;			C#6  D6   D#6  E6   F6   F#6  G6  G#6 A6  A#6 B6  C7  C#7 D7  D#7
	.byt	136, 129, 121, 114, 108, 102, 96, 90, 85, 80, 76, 71, 67, 63, 60	; C#6 to D#7

; player offsets according to routine
;	.byt	0, 1
poff6:
	.byt	0, 6
poff7:
	.byt	0, 7
poff9:
	.byt	0, 9
poff36:
	.byt	0, 36
poff128:
	.byt	0, 128

; initial level & scores according to difficulty
ini_lev:
	.byt	0, 5, $10		; initial level (BCD)
ini_score:
	.byt	0, 2, 5			; "third" byte initial score (BCD)

; ********************
; *** picture data ***
; ********************
splash:
	.bin	0, 0, "art/start.rle"
field:
	.bin	0, 0, "art/columns.rle"
sprites:
	.dsb	32, 0									; first tile is blank
	.bin	0, 0, "art/jewels.sv4"					; uncompressed file, 4-byte wide!
gameover:
	.bin	0, 0, "art/gameover.sv24"				; uncompressed, 24-byte wide
numbers:
	.bin	0, 0, "../../other/data/numbers.sv20"	; generic number images, 20-byte wide
levelsel:
	.bin	0, 0, "art/level.sv24"					; uncompressed, 24-byte wide, 23 lines tall

; ***************************
; *** ROM padding and end ***
; ***************************

	.dsb	$FFD6-*, $FF		; ROM fill
	.asc	"DmOS"				; minimOS-compliant signature
irq_hndl:
	JMP (irq_ptr)				; standard IRQ handler

	.dsb	$FFFA-*, $FF		; ROM fill, not using cehcksum
; 6502 hardware vectors
	.word	isr_end				; null handler
	.word	reset
	.word	irq_hndl
