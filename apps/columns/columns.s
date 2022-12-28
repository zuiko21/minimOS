; COLUMNS for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20221228-1131

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

; *************************
; *** memory allocation ***
; *************************

colour	= $F9
seed	= colour+1			; $FA
src		= seed+2			; $FC
ptr		= src+2				; $FE

irq_ptr	= $0200				; standard minimOS, may save a few bytes putting these on ZP
ticks	= irq_ptr+2			; no NMI or BRK in use, and only 16-bit

pad0mask= ticks+2			; gamepad masking values
pad1mask= pad0mask+1
pad0val	= pad1mask+1		; gamepad current status
pad1val	= pad0val+1

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
; setup controllers etc (assume minstrel-type kbd)
	STZ pad0mask
	STZ pad1mask			; need these reset the very first time
	JSR read_pad			; get initial values
	LDX pad0val
	LDY pad1val
	STX pad0mask			; ...and store them
	STY pad1mask
	JSR read_pad			; just for clearing the values
; * may check here for supported keyboard presence (col 6 = $2C)
; setup interrupt system
	LDY #<isr
	LDX #>isr				; ISR address
	STY irq_ptr				; standard FW adress
	STX irq_ptr+1
	CLI						; enable interrupts!
; wait for action * should check keyboard also * TODO
	LDA #%11000000			; look for start or fire
wait_s:
		INX
		BIT pad0val
	BNE start
		BIT pad1val
		BEQ wait_s
start:
	LDA ticks
	STA seed
	STX seed+1				; quite random seed
; TODO * init game stuff * TODO

; display game field
	LDX #2					; set compressed file index
	JSR dispic				; decompress!

; TODO * do game stuff... * TODO
lock:jmp lock
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

; ** number display **
; input
;	Y		type of display (0=level, 2=jewels, 4=score)
;	X		player [0-1]
;	colour	AND mask
; fixed size; score=6 digits, level=2 digits, jewels=4 digits
; BCD data array [LxJJSSSS] thus Y-indexed
; fixed player 1 base addresses; score $6007 (14,0), level $6C5C (56,49), jewels $7E4A (20,121)
; player 2 level adds 52 Y-offset! (64,101)
; fixed player 2 offset; score $26 (90-14), level 4 (actually $D04) (64-56), jewels $24 (92-20)
numdisp:
	PHX						; save player for later
	TXA						; player offset
	CLC
	ADC disp_id, Y			; select type of display
	TAX						; offset to base address
	LDA num_bl, X
	STA ptr
	LDA num_bh, X
	STA ptr+1				; screen pointer is ready
; TODO *** assume A is number to be displayed
	ASL						; two bytes per raster
	TAX						; first raster address

n_rast:
			LDA numbers, X
			AND colour
			STA (ptr), Y	; copy glyph raster into screen
			INX
			INY
			LDA numbers, X
			AND colour
			STA (ptr), Y	; copy glyph raster into screen
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
; TODO * read keyboard too? * TODO
isr_end:					; common interrupt exit
	RTI

; **************
; *** tables ***
; **************
cmpr_pics:					; to be displayed by dispic
	.word	splash
	.word	field

num_bl:						; base addresses of numeric displays (LSB, interleaved $P2P1)
	.word	$605C			; level $6C5C, $7960 (!)
	.word	$6E4A			; jewels $7E4A, $7E6E
	.word	$2D07			; score $6007, $602D
num_bh:						; base addresses of numeric displays (MSB, interleaved $P2P1)
	.word	$796C			; level $6C5C, $7960 (!)
	.word	$7E7E			; jewels $7E4A, $7E6E
	.word	$6060			; score $6007, $602D
play_col:					; player display colour
	.byt	9, 11			; sky blue and lavender pink
disp_id:					; identity array (every 2)
	.word	0, 2, 4

; ********************
; *** picture data ***
; ********************
splash:
	.bin	0, 0, "col_start.rle"
field:
	.bin	0, 0, "columns.rle"
sprites:
	.bin	0, 0, "jewels.sv4"						; uncompressed file, 4-byte wide!
gameover:
	.bin	0, 0, "col_gameover.sv24"				; uncompressed, 24-byte wide
numbers:
	.bin	0, 0, "../../other/data/numbers.sv20"	; generic number images, 20-byte wide

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
