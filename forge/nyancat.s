; nyan cat demo for Durango-X (or -S)
; (c) 2022 Carlos J. Santisteban
; last modified 20220809-1137

; *** usual definitions ***
IO8attr	= $DF80				; video mode register
IO8blk	= $DF88				; blanking signals register
IOAie	= $DFA0				; interrupt control
IOBeep	= $DFB0				; buzzer output
screen2	= $4000				; screen start addresses
screen3	= $6000

; *** specific values ***
fwidth	= 90				; frame width in pixels (45 bytes)
swidth	= 128				; screen width in pixels (64 bytes)
fheight	= 42				; frame height in pixels
homepos	= screen3 + $AC0	; address of leftmost upper corner of frames (0,43)

; *** memory allocation ***
ptr		= 3					; safe ZP address for indirect pointers (.w)
anim	= ptr+2				; animation pointer, will increment by 2K
org		= anim+2			; local copy of animation pointer
togg12	= org+2				; switch between both 6-frame banks

_last	= togg12+1

; ********************
; *** ROM contents ***
; ********************
	*	= $C000				; 16K ROM

; **********************
; *** animation data ***
; **********************
; all frames 90x42 pixels, as 2K-aligned there will be 158 free bytes in between (1890/frame)
anim0:
	.bin	0, $762, "../other/data/cataa"
	.dsb	$C800-*, $FF	; padding
anim1:
	.bin	0, $762, "../other/data/catab"
	.dsb	$D000-*, $FF	; padding
anim2:
	.bin	0, $762, "../other/data/catac"
	.dsb	$D800-*, $FF	; padding
anim3:
	.bin	0, $762, "../other/data/catad"
	.dsb	$E000-*, $FF	; padding, will skip I/O at $DFxx
anim4:
	.bin	0, $762, "../other/data/catae"
	.dsb	$E800-*, $FF	; padding
anim5:
	.bin	0, $762, "../other/data/cataf"
	.dsb	$F000-*, $FF	; padding

; ***********************
; *** executable code ***
; ***********************
start:
; usual 6502 stuff
	SEI
	CLD
	LDX #$FF
	TXS
; usual Durango setup
	STX IOAie				; allow interrupts for good measure (X was $FF)
	LDA #%00101000			; colour, RGB mode, note SCREEN 2!
	STA IO8attr				; set video mode

; *** initialise demo ***
; clear alternate intro screen
	LDX #>screen2			; SCREEN 2 initial page
	LDY #0					; reset LSB and index
	STY ptr					; set indirect pointer to clear screen
	STY togg12				; clear frame bank switch
	TYA						; will be all zeroes
cl_page:
		STX ptr+1			; pointer complete after update
cls:
			STA (ptr), Y	; fill screen 2
			INY
			BNE cls
		INX					; next page
		CPX #>screen3		; unfortunately no BPL trick here
		BNE cl_page
; fill standard screen in blue
	LDA #$88				; all BLUE for standard screen
bl_page:
		STX ptr+1			; pointer complete after update
blue:
			STA (ptr), Y	; fill screen 2
			INY
			BNE blue
		INX					; next page
		BPL bl_page			; until beginning of ROM (may use CPX #;BNE if not using SCREEN3 for this)
; some more data init
	LDX #>anim0
	LDY #<anim0
	STX anim+1				; reset animation pointer
	STY anim
; *** maybe copy first sprite into hidden screen?
	JSR draw_frame

; *** should play initial music here (TBD)

; switch to standard screen
	LDA #%00111000			; colour, RGB mode, SCREEN 3 as usual
	STA IO8attr				; set final video mode

; *****************
; *** main loop ***
; *****************
loop:
; *** if first frame is already on screen, maybe start music frame instead of updating screen?
	JSR wait_frame			; delay animation at half the frame rate

; advance to next sprite, resetting if needed
	LDA anim+1				; get frame page
	CLC
	ADC #8					; $800 bytes = 2 kiB
	CMP #>start				; did all frames?
	BNE nowrap
		LDA togg12			; the other 6 frames... ***
		EOR #64				; 8 lines further, for easier logic op. ***
		STA togg12			; update switch ***
		LDA #>anim0			; back to beginning
nowrap:
	STA anim+1				; update frame pointer
; time to show some stars...
	SEC
	SBC #>anim0				; convert to index
	ORA togg12				; switching between both 6-frame lists ***
	PHA						; save for later
	TAY
	LDA #$88				; clear value
cl_loop:
		LDX cl_lst, Y		; look first entry in clear list
		BEQ cl_end			; zero means end of list
		JSR call_star		; emulate indirect indexed call
		INY
		BRA cl_loop
cl_end:
	PLY						; retrieve index on list (use PLA,TAY on NMOS)
	LDA #$FF				; draw value
dr_loop:
		LDX dr_lst, Y		; look first entry in draw list
		BEQ dr_end			; zero means end of list
		JSR call_star		; emulate indirect indexed call
		INY					; try next entry in list
		BRA dr_loop

; *** indirect indexed call emulation ***
call_star:
	JMP (star_tab, X)		; LDA st,X;STA ptr;LDA st+1,X;STA ptr+1;JMP(ptr) for NMOS

dr_end:
; draw animation frame after stars
	JSR draw_frame			; show me now!

; anything else?
	JMP loop				; in aeternum

; ********************
; *** useful stuff ***
; ********************

; *** display one frame ***
draw_frame:
; copy parameters into local variables
	LDX anim+1
	LDY anim
	STX org+1
	STY org
	LDX #>homepos
;	LDY #<homepos			; gonna be zero as well
	STX ptr+1
	STY ptr
; draw
	LDX #fheight			; number of lines per frame!
line_loop:
		LDY #(fwidth/2)-1	; max offset per line!
df_loop:
			LDA (org), Y
			STA (ptr), Y
			DEY
			BPL df_loop		; complete raster
; advance to next raster
		LDA ptr
		CLC
		ADC #(swidth/2)		; advance to next raster in screen...
		STA ptr
		BCC ptr_nw
			INC ptr+1		; in case of page wrap (every 4 rasters)
ptr_nw:
		LDA org
		CLC
		ADC #(fwidth/2)		; ...and advance inside animation file
		STA org
		BCC org_nw
			INC org+1		; in case of page wrap (somewhat more frequent)
org_nw:
		DEX					; one line is complete
		BNE line_loop
	RTS

; *** wait for VSYNC ***
wait_frame:
	BIT IO8blk
	BVS wait_frame
wait_sync:
	BIT IO8blk
	BVC wait_sync
wait_en
	BIT IO8blk
	BVS wait_en

	RTS

; non-existent interrupt routine (this far)
intexit:
	RTI

; ******************
; *** stars code *** TBD
; ******************
; assume A is $FF to set, $88 to clear!
; adjust base accordingly
base = 0	; placeholder

-screen3=$6680
; star routines
star_0:
-base=$240+$3C
	STA screen3+base		; (0,0), reference upper left
	STA screen3+base+$40	; (0,1)
none:
	RTS

star_1:
-base=$1C0+$38
	STA screen3+base+1		; (1,0), centre offset by (1,1)
	STA screen3+base+$41	; (1,1)
	STA screen3+base+$80	; (0,2)
	STA screen3+base+$82	; (2,2)
	STA screen3+base+$C0	; (0,3)
	STA screen3+base+$C2	; (2,3)
	STA screen3+base+$101	; (1,4)
	STA screen3+base+$141	; (1,5)
	RTS

star_2:
-base=$140+$30
	STA screen3+base+2		; (2,0), centre offset by (2,2)
	STA screen3+base+$42	; (2,1)
	STA screen3+base+$82	; (2,2)
	STA screen3+base+$C2	; (2,3)
	STA screen3+base+$100	; (0,4)
	STA screen3+base+$101	; (1,4)
	STA screen3+base+$103	; (3,4)
	STA screen3+base+$104	; (4,4)
	STA screen3+base+$140	; (0,5)
	STA screen3+base+$141	; (1,5)
	STA screen3+base+$143	; (3,5)
	STA screen3+base+$144	; (4,5)
	STA screen3+base+$182	; (2,6)
	STA screen3+base+$1C2	; (2,7)
	STA screen3+base+$202	; (2,8)
	STA screen3+base+$242	; (2,9)
	RTS

star_3:
-base=$C0+$24
	STA screen3+base+3		; (3,0), centre offset by (3,3)
	STA screen3+base+$43	; (3,1)
	STA screen3+base+$83	; (3,2)
	STA screen3+base+$C3	; (3,3)
	STA screen3+base+$180	; (0,6)
	STA screen3+base+$181	; (1,6)
	STA screen3+base+$183	; (3,6)
	STA screen3+base+$185	; (5,6)
	STA screen3+base+$186	; (6,6)
	STA screen3+base+$1C0	; (0,7)
	STA screen3+base+$1C1	; (1,7)
	STA screen3+base+$1C3	; (3,7)
	STA screen3+base+$1C5	; (5,7)
	STA screen3+base+$1C6	; (6,7)
	STA screen3+base+$283	; (3,10)
	STA screen3+base+$2C3	; (3,11)
	STA screen3+base+$303	; (3,12)
	STA screen3+base+$343	; (3,13)
	RTS

star_4:
-base=$C0+$14
	STA screen3+base+3		; (3,0), centre offset by (3,3)
	STA screen3+base+$43	; (3,1)
	STA screen3+base+$81	; (1,2)
	STA screen3+base+$85	; (5,2)
	STA screen3+base+$C1	; (1,3)
	STA screen3+base+$C5	; (5,3)
	STA screen3+base+$180	; (0,6)
	STA screen3+base+$186	; (6,6)
	STA screen3+base+$1C0	; (0,7)
	STA screen3+base+$1C6	; (6,7)
	STA screen3+base+$281	; (1,10)
	STA screen3+base+$285	; (5,10)
	STA screen3+base+$2C1	; (1,11)
	STA screen3+base+$2C5	; (5,11)
	STA screen3+base+$303	; (3,12)
	STA screen3+base+$343	; (3,13)
	RTS

star_5:
-base=$C0+$04
	STA screen3+base+3		; (3,0), centre offset by (3,3)
	STA screen3+base+$43	; (3,1)
	STA screen3+base+$180	; (0,6)
	STA screen3+base+$186	; (6,6)
	STA screen3+base+$1C0	; (0,7)
	STA screen3+base+$1C6	; (6,7)
	STA screen3+base+$303	; (3,12)
	STA screen3+base+$343	; (3,13)
	RTS

star_0b:
-base=$1240+$3C
	STA screen3+base		; (0,0), reference upper left
	STA screen3+base+$40	; (0,1)
	RTS

star_1b:
-base=$11C0+$38
	STA screen3+base+1		; (1,0), centre offset by (1,1)
	STA screen3+base+$41	; (1,1)
	STA screen3+base+$80	; (0,2)
	STA screen3+base+$82	; (2,2)
	STA screen3+base+$C0	; (0,3)
	STA screen3+base+$C2	; (2,3)
	STA screen3+base+$101	; (1,4)
	STA screen3+base+$141	; (1,5)
	RTS

star_2b:
-base=$1140+$30
	STA screen3+base+2		; (2,0), centre offset by (2,2)
	STA screen3+base+$42	; (2,1)
	STA screen3+base+$82	; (2,2)
	STA screen3+base+$C2	; (2,3)
	STA screen3+base+$100	; (0,4)
	STA screen3+base+$101	; (1,4)
	STA screen3+base+$103	; (3,4)
	STA screen3+base+$104	; (4,4)
	STA screen3+base+$140	; (0,5)
	STA screen3+base+$141	; (1,5)
	STA screen3+base+$143	; (3,5)
	STA screen3+base+$144	; (4,5)
	STA screen3+base+$182	; (2,6)
	STA screen3+base+$1C2	; (2,7)
	STA screen3+base+$202	; (2,8)
	STA screen3+base+$242	; (2,9)
	RTS

star_3b:
-base=$10C0+$24
	STA screen3+base+3		; (3,0), centre offset by (3,3)
	STA screen3+base+$43	; (3,1)
	STA screen3+base+$83	; (3,2)
	STA screen3+base+$C3	; (3,3)
	STA screen3+base+$180	; (0,6)
	STA screen3+base+$181	; (1,6)
	STA screen3+base+$183	; (3,6)
	STA screen3+base+$185	; (5,6)
	STA screen3+base+$186	; (6,6)
	STA screen3+base+$1C0	; (0,7)
	STA screen3+base+$1C1	; (1,7)
	STA screen3+base+$1C3	; (3,7)
	STA screen3+base+$1C5	; (5,7)
	STA screen3+base+$1C6	; (6,7)
	STA screen3+base+$283	; (3,10)
	STA screen3+base+$2C3	; (3,11)
	STA screen3+base+$303	; (3,12)
	STA screen3+base+$343	; (3,13)
	RTS

star_4b:
-base=$10C0+$14
	STA screen3+base+3		; (3,0), centre offset by (3,3)
	STA screen3+base+$43	; (3,1)
	STA screen3+base+$81	; (1,2)
	STA screen3+base+$85	; (5,2)
	STA screen3+base+$C1	; (1,3)
	STA screen3+base+$C5	; (5,3)
	STA screen3+base+$180	; (0,6)
	STA screen3+base+$186	; (6,6)
	STA screen3+base+$1C0	; (0,7)
	STA screen3+base+$1C6	; (6,7)
	STA screen3+base+$281	; (1,10)
	STA screen3+base+$285	; (5,10)
	STA screen3+base+$2C1	; (1,11)
	STA screen3+base+$2C5	; (5,11)
	STA screen3+base+$303	; (3,12)
	STA screen3+base+$343	; (3,13)
	RTS

star_5b:
-base=$10C0+$04
	STA screen3+base+3		; (3,0), centre offset by (3,3)
	STA screen3+base+$43	; (3,1)
	STA screen3+base+$180	; (0,6)
	STA screen3+base+$186	; (6,6)
	STA screen3+base+$1C0	; (0,7)
	STA screen3+base+$1C6	; (6,7)
	STA screen3+base+$303	; (3,12)
	STA screen3+base+$343	; (3,13)
	RTS

; pointer table (leave first entry clear)
star_tab:
	.word	none			; entry 0 is free
	.word	star_0
	.word	star_1
	.word	star_2
	.word	star_3
	.word	star_4
	.word	star_5
	.word	star_0b			; index 14...
	.word	star_1b			; 16
	.word	star_2b			; 18
	.word	star_3b			; 20
	.word	star_4b			; 22
	.word	star_5b			; 24

; clear list
cl_lst:
	.byt	 0, 0, 0, 0, 0, 0, 0, 0	; not needed for 12-frame version, but won't harm anyway
	.byt	 2, 0, 0, 0, 0, 0, 0, 0
	.byt	 4, 0, 0, 0, 0, 0, 0, 0
	.byt	 6, 0, 0, 0, 0, 0, 0, 0
	.byt	 8,20, 0, 0, 0, 0, 0, 0
	.byt	10, 0, 0, 0, 0, 0, 0, 0
	.dsb	16, 0			; complete 8 rows for each 6-frame bank
	.byt	12,14, 0, 0, 0, 0, 0, 0
	.byt	16, 0, 0, 0, 0, 0, 0, 0
	.byt	18, 0, 0, 0, 0, 0, 0, 0
	.byt	20, 0, 0, 0, 0, 0, 0, 0
	.byt	22, 0, 0, 0, 0, 0, 0, 0
	.byt	24, 0, 0, 0, 0, 0, 0, 0

; draw list
dr_lst:
	.byt	 2, 0, 0, 0, 0, 0, 0, 0
	.byt	 4, 0, 0, 0, 0, 0, 0, 0
	.byt	 6, 0, 0, 0, 0, 0, 0, 0
	.byt	 8, 0, 0, 0, 0, 0, 0, 0
	.byt	10, 0, 0, 0, 0, 0, 0, 0
	.byt	12,14, 0, 0, 0, 0, 0, 0
	.dsb	16, 0			; complete 8 rows for each 6-frame bank
	.byt	16, 0, 0, 0, 0, 0, 0, 0
	.byt	18, 0, 0, 0, 0, 0, 0, 0
	.byt	20, 0, 0, 0, 0, 0, 0, 0
	.byt	22, 0, 0, 0, 0, 0, 0, 0
	.byt	24, 0, 0, 0, 0, 0, 0, 0
	.byt	 0, 0, 0, 0, 0, 0, 0, 0
; ************************
; *** hardware vectors ***
; ************************

	.dsb	$FFFA-*, $FF	; usual filling to end-of-ROM

	.word	intexit			; no NMI
	.word	start			; code begins here
	.word	intexit			; no interrupts for now
