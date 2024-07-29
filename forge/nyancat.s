; nyan cat demo for Durango-X (or -S)
; (c) 2022 Carlos J. Santisteban
; last modified 20240727-0839

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
mus_pt	= temp+1			; score cursor
rest_f	= mus_pt+1			; remaining animation frames of rest

_last	= rest_f+1

; ********************
; *** ROM contents ***
; ********************
	*	= $8000				; now 32K ROM, makes room for the header!

rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"nyancat"		; C-string with filename @ [8], max 220 chars
; note terminator below
; optional C-string with comment after filename, filename+comment up to 220 chars
	.asc	0, 0

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1041			; 1.0b1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$3A00			; time, 07.16		%0011 1-010 000-0 0000
	.word	$5892			; date, 2024/4/18	%0101 100-0 100-1 0010
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; filling
	.dsb	$C000-*, $FF

; **********************
; *** animation data ***
; **********************
; all frames 90x42 pixels, as 2K-aligned there will be 158 free bytes in between (1890/frame)
anim0:
	.bin	0, $762, "../other/data/cataa"
; 158 free bytes for some code (star templates?)
	.dsb	$C800-*, $FF	; padding
anim1:
	.bin	0, $762, "../other/data/catab"
; 158 free bytes for some code (star templates?)
	.dsb	$D000-*, $FF	; padding
anim2:
	.bin	0, $762, "../other/data/catac"
; 158 free bytes for some code (star templates?)
	.dsb	$D800-*, $FF	; padding
anim3:
	.bin	0, $762, "../other/data/catad"
; 158 free bytes for some code (star templates?)
	.dsb	$E000-*, $FF	; padding, will skip I/O at $DFxx
anim4:
	.bin	0, $762, "../other/data/catae"
; 158 free bytes for some code (star templates?)
	.dsb	$E800-*, $FF	; padding
anim5:
	.bin	0, $762, "../other/data/cataf"
; 158 free bytes for some code (star templates?)
	.dsb	$F000-*, $FF	; padding

; ***********************
; *** executable code *** at $F000
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
	STY rest_f				; and rest counter
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
; ** format for intro music **
; log duration list @i_dur (2=semiquaver... 0=end)
; chromatic notes @i_note (0=rest, 1..28=C#5-E7)
; convert to loop iterations @c2freq (first entry free)
; for proper timing, number of cycles/2 for ~32 ms play @m_cyc (same indices as @i_note)
; rest takes 3.2 ms per iteration, like m_cyc shift according to i_dur
intro:
		LDY mus_pt			; get offset to current note
		LDX i_dur, Y		; get duration (log scale, 2=semiquaver, 3=quaver etc)
			BEQ mus_end		; zero is end of score, go for animation
		LDA i_note, Y		; get pitch
		BNE note_pb			; is audible note, play it back
			LDA #5			; base cycles for 32 ms rest
rs_loop:
				ASL				; times two
				DEX
				BPL rs_loop
			TAX					; actual duration
			JSR rest		; otherwise is rest
			BEQ next_n		; no need for BRA
note_pb:
		TAY					; use chromatic note as index
		LDA m_cyc, Y		; get base cycles for this note
len_loop:
			ASL				; times two
			DEX
			BPL len_loop
		TAX					; actual duration
		LDA c2freq, Y		; convert note to frequency
		JSR note			; play sound
next_n:
		INC mus_pt			; next note EEEEEEK
		BNE intro			; continue intro, no need for BRA
mus_end:
	STZ mus_pt				; reset pointer for main melody eeeeek

; switch to standard screen
	LDA #%00111000			; colour, RGB mode, SCREEN 3 as usual
	STA IO8attr				; set final video mode

; *****************
; *** main loop ***
; *****************
loop:
; almost TWO frames (~32 ms) are devoted to audio, then the next one for video rendering
; ** format for in-demo music **
; chromatic notes @m_note (0=END, 1..28=C#5-E7, negative=REST)
; each tone is always played ~32 ms according to m_cyc, longer notes are simulated with rests
; the number of "animation frames" of silence is the negative pitch in two's-complement
; as each play/anim cycle takes ~60 ms, a default one-cycle rest makes semiquaver as default (tempo ~ 8 semiq/sec)
		LDX rest_f			; check any active rest
		BPL m_play			; no longer negative, time to play
			INX
			STX rest_f		; one frame less of rest
		BEQ m_play 			; if the end of rest, go playing
			BRA end_r
m_play:
		LDA #$3C
		STA IO8attr			; EXPERIMENTAL, turn on white LED when not in rest
		LDY mus_pt			; get offset to current note
		LDA m_note, Y		; get chromatic pitch
		BNE m_cont			; zero at end of list
			STZ mus_pt
			JMP loop		; get first note again
;			JMP start		; *** OK?
m_cont:
		BPL m_pb			; is audible note, play it back
			STA rest_f		; otherwise set remaining frames and exit
			LDA #$38
			STA IO8attr			; EXPERIMENTAL, turn off white LED while in rest
			BRA end_r
m_pb:
		TAY					; use as index
		LDa m_cyc, Y		; get length for this particular frequency (~35 ms length)
asl
asl
tax
		LDA c2freq, Y		; convert note to frequency EEEEEEEEEK
		JSR note			; play sound
		LDX #255			; default rest between notes = 60 ms
		STX rest_f
		BRA end_note
end_r:
		JSR wait_frame		; wait for the approximate length of sound
end_note:
	INC mus_pt				; next note EEEEEEK

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
	JSR wait_frame			; delay animation at 1/3 frame rate

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

; ********************
; *** music scores ***
; ********************

; * intro music *
i_dur:
; duration list (0-terminated)
	.byt	 2,  2,  2,  2,	 2,  2,  2,  2,	 2,  2,  2,  2,	 2,  2,  2,  2
	.byt	 2,  2,  2,  2,	 2,  2,  3,		 2,  2,  2,  2,	 2,  2,  2,  2,	$0
i_note:
; chromatic note list
	.byt	 3,  4,  6,  0,	11,  4,  3,  4,	 6, 11, 15, 16,	15, 10, 11,  0
	.byt	 6,  0,  3,  4,	 6,  0, 11,		13, 10, 11, 13,	16, 15, 16, 13

; * music during animation *
m_note:
; chromatic indices, zero is END, negative is rest counter (adding one rest cycle by default, $FE is semiquaver rest, or quaver length)
	.byt	 18,$FE, 20,$FE,	 14, 15,$FE, 13,	 14, 13, 11,$FE,	 11,$FE, 13,$FE
	.byt	 14,$FE, 14, 13,	 11, 13, 15, 18,	 20, 15, 18, 13,	 15, 11, 13, 11
	.byt	 15,$FE, 18,$FE,	 20, 15, 18, 13,	 15, 11, 14, 15,	 14, 13, 11, 13
	.byt	 15,$FE, 11, 13,	 15, 18, 13, 14,	 13, 11, 13,$FE,	 11,$FE, 13,$FE
	.byt	 18,$FE, 20,$FE,	 14, 15,$FE, 13,	 14, 13, 11,$FE,	 11,$FE, 13,$FE
	.byt	 14,$FE, 14, 13,	 11, 13, 15, 18,	 20, 15, 18, 13,	 15, 11, 13, 11
	.byt	 15,$FE, 18,$FE,	 20, 15, 18, 13,	 15, 11, 14, 15,	 14, 13, 11, 13
	.byt	 15,$FE, 11, 13,	 15, 18, 13, 14,	 13, 11, 13,$FE,	 11,$FE, 11,$FE
	.byt	$0

; ********************
; *** musical data ***
; ********************
; conversion from chromatic scale (C#5-E7) to frequency (actually period) (first entry not used)
c2freq:
	.byt	$FF, 137, 129, 121, 115, 108, 102, 96, 90
	.byt		  85,  80,  75,  71,  67,  63, 59, 56
	.byt		  53,  50,  47,  44,  41,  39, 37, 35
	.byt 		  33,  31,  29,  27
; lenght (pair of cycles) of each pitch to make ~32 ms notes
m_cyc:
	.byt	$FF,   8,   9,   9,  10,  11,  11, 12, 13
	.byt		  14,  14,  15,  16,  17,  18, 20, 21
	.byt		  22,  23,  24,  26,  28,  29, 31, 32
	.byt		  34,  36,  39,  41
; ************************
; *** hardware vectors ***
; ************************

	.dsb	$FFFA-*, $FF	; usual filling to end-of-ROM

	.word	intexit			; no NMI
	.word	start			; code begins here
	.word	intexit			; no interrupts for now
