; nyan cat demo for Durango-X (or -S)
; (c) 2022 Carlos J. Santisteban
; last modified 20220810-1641

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
temp	= togg12+1			; temporary use, for cleanliness
mus_pt	= temp+1

_last	= mus_pt+1

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
	STY mus_pt				; reset music player cursor
	TYA						; will fill the screen with zeroes
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
; copy first sprite into hidden screen
	JSR draw_frame

; play initial music here
intro:
		LDY mus_pt			; get offset to current note
		LDX i_dur, Y		; get duration (log scale, 2=semiquaver, 3=quaver etc)
			BEQ mus_end		; zero is end of score, go for animation
		LDA i_note, Y		; get pitch
		BNE note_pb			; is audible note, play it back
			LDA #10			; base cycles for 32 ms rest
rs_loop:
				ASL				; times two
				DEX
				BNE rs_loop
			TAX					; actual duration
			JSR rest		; otherwise is rest
			BEQ next_n		; no need for BRA
note_pb:
		TAY					; use chromatic note as index
		LDA c2freq, Y		; convert to frequency
		TAY					; save period!
		LDA m_cyc, Y		; get base cycles for this note
len_loop:
			ASL				; times two
			DEX
			BNE len_loop
		TAX					; actual duration
		TYA					; retrieve pitch
		JSR note			; play sound
next_n:
		INC mus_pt			; next note EEEEEEK
		BNE intro			; continue intro, no need for BRA
mus_end:
	STX mus_pt				; reset pointer for main melody

; switch to standard screen
	LDA #%00111000			; colour, RGB mode, SCREEN 3 as usual
	STA IO8attr				; set final video mode

; *****************
; *** main loop ***
; *****************
loop:
; almost TWO frames (~32 ms) are devoted to audio, then the next one for video rendering
		LDY mus_pt			; get offset to current note
		LDA m_freq, Y		; get pitch
		BPL m_cont			; negative pitch at end of list
			STZ mus_pt
			JMP loop		; get first note again
;			JMP start		; *** OK?
m_cont:
		BNE m_pb			; is audible note, play it back
			JSR wait_frame
			JSR wait_frame
			BRA end_r
m_pb:
		TAY					; use as index
		LDX m_cyc, Y		; get length for this particular frequency (~35 ms length)
		JSR note			; play sound
end_r:
		INC mus_pt			; next note EEEEEEK
end_note:
	JSR wait_frame			; delay animation at 1/3 frame rate

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

; time to show some stars... routine needs anim.H in A
	JSR update_stars		; just for clarity

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

; *** update starfield *** needs A with anim.H
update_stars:
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
dr_end:
	RTS

; *** indirect indexed call emulation ***
call_star:
	JMP (star_tab, X)		; PHA;LDA st,X;STA ptr;LDA st+1,X;STA ptr+1;PLA;JMP(ptr) for NMOS

; *** wait for VSYNC ***
wait_frame:
	BIT IO8blk
	BVS wait_frame
wait_sync:
	BIT IO8blk
	BVC wait_sync
	RTS

; *** basic note play ***
note:
; *** X = length, A = freq. ***
; *** X = cycles (HALF)     *** returns with Z, X=0
; *** tcyc = 2 (5A + 12)    ***
; ***     @1.536 MHz        ***
		TAY					; determines frequency (2)
n_tim:
			DEY				; count pulse length (y*2)
			BNE n_tim		; stay this way for a while (y*3-1)
		LDY #1
		STY IOBeep			; toggle beeper hi (2+4)
		NOP
		STY temp			; equalising delay (2+3)
		TAY
n_tim2:
			DEY				; count pulse length (y*2)
			BNE n_tim2		; stay this way for a while (y*3-1)
		LDY #0
		STY IOBeep			; toggle beeper lo (2+4)
		NOP
		STY temp			; equalising delay (2+3)
		TAY
n_tim3:
			DEY				; count pulse length (y*2)
			BNE n_tim3		; stay this way for a while (y*3-1)
		LDY #1
		STY IOBeep			; toggle beeper hi (2+4)
		NOP
		STY temp			; equalising delay (2+3)
		TAY
n_tim4:
			DEY				; count pulse length (y*2)
			BNE n_tim4		; stay this way for a while (y*3-1)
		LDY #0
		STY IOBeep			; toggle beeper lo (2+4)
		DEX					; toggles even/odd number (2)
		BNE note			; new cycle, beeper ends off (3)
n_exit:
	RTS

; *** ** rest routine ** ***
; ***     X = length     *** returns with Z, X=0
; *** X 3.2 ms @ 1.536M ***
rest:
		LDY #0				; this resets the counter
r_loop:
			NOP
			JSR none		; delay at 1.536 MHz
			INY
			BNE r_loop		; this will take ~ 3.2 ms
		DEX					; continue
		BNE rest
	RTS

; non-existent interrupt routine (this far)
intexit:
	RTI

; **********************
; *** star templates ***
; **********************
; assume A is $FF to set, $88 to clear!
; adjust base accordingly

-screen3=$6680

star_0:
-base=$6680+$240+$3C
	STA base		; (0,0), reference upper left
	STA base+$40	; (0,1)
none:
	RTS

star_1:
-base=$6680+$1C0+$38
	STA base+1		; (1,0), centre offset by (1,1)
	STA base+$41	; (1,1)
	STA base+$80	; (0,2)
	STA base+$82	; (2,2)
	STA base+$C0	; (0,3)
	STA base+$C2	; (2,3)
	STA base+$101	; (1,4)
	STA base+$141	; (1,5)
	RTS

star_2:
-base=$6680+$140+$30
	STA base+2		; (2,0), centre offset by (2,2)
	STA base+$42	; (2,1)
	STA base+$82	; (2,2)
	STA base+$C2	; (2,3)
	STA base+$100	; (0,4)
	STA base+$101	; (1,4)
	STA base+$103	; (3,4)
	STA base+$104	; (4,4)
	STA base+$140	; (0,5)
	STA base+$141	; (1,5)
	STA base+$143	; (3,5)
	STA base+$144	; (4,5)
	STA base+$182	; (2,6)
	STA base+$1C2	; (2,7)
	STA base+$202	; (2,8)
	STA base+$242	; (2,9)
	RTS

star_3:
-base=$6680+$C0+$24
	STA base+3		; (3,0), centre offset by (3,3)
	STA base+$43	; (3,1)
	STA base+$83	; (3,2)
	STA base+$C3	; (3,3)
	STA base+$180	; (0,6)
	STA base+$181	; (1,6)
	STA base+$183	; (3,6)
	STA base+$185	; (5,6)
	STA base+$186	; (6,6)
	STA base+$1C0	; (0,7)
	STA base+$1C1	; (1,7)
	STA base+$1C3	; (3,7)
	STA base+$1C5	; (5,7)
	STA base+$1C6	; (6,7)
	STA base+$283	; (3,10)
	STA base+$2C3	; (3,11)
	STA base+$303	; (3,12)
	STA base+$343	; (3,13)
	RTS

star_4:
-base=$6680+$C0+$14
	STA base+3		; (3,0), centre offset by (3,3)
	STA base+$43	; (3,1)
	STA base+$81	; (1,2)
	STA base+$85	; (5,2)
	STA base+$C1	; (1,3)
	STA base+$C5	; (5,3)
	STA base+$180	; (0,6)
	STA base+$186	; (6,6)
	STA base+$1C0	; (0,7)
	STA base+$1C6	; (6,7)
	STA base+$281	; (1,10)
	STA base+$285	; (5,10)
	STA base+$2C1	; (1,11)
	STA base+$2C5	; (5,11)
	STA base+$303	; (3,12)
	STA base+$343	; (3,13)
	RTS

star_5:
-base=$6680+$C0+$04
	STA base+3		; (3,0), centre offset by (3,3)
	STA base+$43	; (3,1)
	STA base+$180	; (0,6)
	STA base+$186	; (6,6)
	STA base+$1C0	; (0,7)
	STA base+$1C6	; (6,7)
	STA base+$303	; (3,12)
	STA base+$343	; (3,13)
	RTS

star_0b:
-base=$6680+$1240+$3C
	STA base		; (0,0), reference upper left
	STA base+$40	; (0,1)
	RTS

star_1b:
-base=$6680+$11C0+$38
	STA base+1		; (1,0), centre offset by (1,1)
	STA base+$41	; (1,1)
	STA base+$80	; (0,2)
	STA base+$82	; (2,2)
	STA base+$C0	; (0,3)
	STA base+$C2	; (2,3)
	STA base+$101	; (1,4)
	STA base+$141	; (1,5)
	RTS

star_2b:
-base=$6680+$1140+$30
	STA base+2		; (2,0), centre offset by (2,2)
	STA base+$42	; (2,1)
	STA base+$82	; (2,2)
	STA base+$C2	; (2,3)
	STA base+$100	; (0,4)
	STA base+$101	; (1,4)
	STA base+$103	; (3,4)
	STA base+$104	; (4,4)
	STA base+$140	; (0,5)
	STA base+$141	; (1,5)
	STA base+$143	; (3,5)
	STA base+$144	; (4,5)
	STA base+$182	; (2,6)
	STA base+$1C2	; (2,7)
	STA base+$202	; (2,8)
	STA base+$242	; (2,9)
	RTS

star_3b:
-base=$6680+$10C0+$24
	STA base+3		; (3,0), centre offset by (3,3)
	STA base+$43	; (3,1)
	STA base+$83	; (3,2)
	STA base+$C3	; (3,3)
	STA base+$180	; (0,6)
	STA base+$181	; (1,6)
	STA base+$183	; (3,6)
	STA base+$185	; (5,6)
	STA base+$186	; (6,6)
	STA base+$1C0	; (0,7)
	STA base+$1C1	; (1,7)
	STA base+$1C3	; (3,7)
	STA base+$1C5	; (5,7)
	STA base+$1C6	; (6,7)
	STA base+$283	; (3,10)
	STA base+$2C3	; (3,11)
	STA base+$303	; (3,12)
	STA base+$343	; (3,13)
	RTS

star_4b:
-base=$6680+$10C0+$14
	STA base+3		; (3,0), centre offset by (3,3)
	STA base+$43	; (3,1)
	STA base+$81	; (1,2)
	STA base+$85	; (5,2)
	STA base+$C1	; (1,3)
	STA base+$C5	; (5,3)
	STA base+$180	; (0,6)
	STA base+$186	; (6,6)
	STA base+$1C0	; (0,7)
	STA base+$1C6	; (6,7)
	STA base+$281	; (1,10)
	STA base+$285	; (5,10)
	STA base+$2C1	; (1,11)
	STA base+$2C5	; (5,11)
	STA base+$303	; (3,12)
	STA base+$343	; (3,13)
	RTS

star_5b:
-base=$6680+$10C0+$04
	STA base+3		; (3,0), centre offset by (3,3)
	STA base+$43	; (3,1)
	STA base+$180	; (0,6)
	STA base+$186	; (6,6)
	STA base+$1C0	; (0,7)
	STA base+$1C6	; (6,7)
	STA base+$303	; (3,12)
	STA base+$343	; (3,13)
	RTS

; *** pointer table (leave first entry clear) ***
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

; ***********************
; *** data structures ***
; ***********************
; clear list
cl_lst:
	.byt	 0, 0, 0, 0, 0, 0, 0,$0	; every row (frame) is 0-terminated
	.byt	 2, 0, 0, 0, 0, 0, 0,$0
	.byt	 4, 0, 0, 0, 0, 0, 0,$0
	.byt	 6, 0, 0, 0, 0, 0, 0,$0
	.byt	 8, 0, 0, 0, 0, 0, 0,$0
	.byt	10, 0, 0, 0, 0, 0, 0,$0
	.dsb	16, 0			; complete 8 rows for each 6-frame bank
	.byt	12,14, 0, 0, 0, 0, 0,$0
	.byt	16, 0, 0, 0, 0, 0, 0,$0
	.byt	18, 0, 0, 0, 0, 0, 0,$0
	.byt	20, 0, 0, 0, 0, 0, 0,$0
	.byt	22, 0, 0, 0, 0, 0, 0,$0
	.byt	24, 0, 0, 0, 0, 0, 0,$0

; draw list
dr_lst:
	.byt	 2, 0, 0, 0, 0, 0, 0,$0
	.byt	 4, 0, 0, 0, 0, 0, 0,$0
	.byt	 6, 0, 0, 0, 0, 0, 0,$0
	.byt	 8, 0, 0, 0, 0, 0, 0,$0
	.byt	10, 0, 0, 0, 0, 0, 0,$0
	.byt	12,14, 0, 0, 0, 0, 0,$0
	.dsb	16, 0			; complete 8 rows for each 6-frame bank
	.byt	16, 0, 0, 0, 0, 0, 0,$0
	.byt	18, 0, 0, 0, 0, 0, 0,$0
	.byt	20, 0, 0, 0, 0, 0, 0,$0
	.byt	22, 0, 0, 0, 0, 0, 0,$0
	.byt	24, 0, 0, 0, 0, 0, 0,$0
	.byt	 0, 0, 0, 0, 0, 0, 0,$0

; *** music scores ***
; intro music
i_dur:
	.byt	 2,  2,  2,  2,	 2,  2,  2,  2,	 2,  2,  2,  2,	 2,  2,  2,  2
	.byt	 2,  2,  2,  2,	 2,  2,  3,		 2,  2,  2,  2,	 2,  2,  2,  2,	$0	; duration list, placeholder (0-terminated)
i_note:
	.byt	15, 16, 18,  0,	23, 16, 15, 16,	18, 23, 27, 28,	27, 22, 23,  0	; chromatic note list
	.byt	18,  0, 15, 16,	18,  0, 23,		25, 22, 23, 25,	28, 27, 28, 25
; music during animation
m_freq:
	.byt	0, $FF			; chromatic indices, zero is rest, negative is end of list, placeholder
; *** musical data ***
; conversion from chromatic scale (C#5-E7) to frequency (actually period) (first entry not used)
c2freq:
	.byt	$FF, 137, 129, 121, 115, 108, 102, 96, 90, 85, 80, 75, 71, 67, 63, 59, 56, 53, 50, 47, 44
	.byt	 41,  39,  37,  35,  33,  31,  29, 27	; these for intro only
; lenght of each pitch to make ~32 ms notes
m_cyc:
	.byt	$FF,  9, 9, 10, 10, 10, 11, 12, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 28, 30, 31, 33, 35, 37, 39, 42	; pair of cycles per note for ~32 ms
; ************************
; *** hardware vectors ***
; ************************

	.dsb	$FFFA-*, $FF	; usual filling to end-of-ROM

	.word	intexit			; no NMI
	.word	start			; code begins here
	.word	intexit			; no interrupts for now
