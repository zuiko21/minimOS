; nyan cat demo for Durango-X (or -S)
; (c) 2022 Carlos J. Santisteban
; last modified 20220808-1656

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
homepos	= screen3 + $AC0	; address of leftmost upper corner of frames

; *** memory allocation ***
ptr		= 3					; safe ZP address for indirect pointers (.w)
anim	= ptr+2				; animation pointer, will increment by 2K
org		= anim+2			; local copy of animation pointer

	*	= $C000				; 16K ROM

; **********************
; *** animation data ***
; **********************
; all frames 90x42 pixels, as 2K-aligned there will be 158 free bytes in between (1890/frame)
anim0:
	.bin	0, 1890, "../other/data/nyancat.sv"
	.dsb	$C800-*, $FF	; padding
anim1:
	.bin	1890, 1890, "../other/data/nyancat.sv"
	.dsb	$D000-*, $FF	; padding
anim2:
	.bin	3780, 1890, "../other/data/nyancat.sv"
	.dsb	$D800-*, $FF	; padding
anim3:
	.bin	5670, 1890, "../other/data/nyancat.sv"
	.dsb	$E000-*, $FF	; padding, will skip I/O at $DFxx
anim4:
	.bin	7560, 1890, "../other/data/nyancat.sv"
	.dsb	$E800-*, $FF	; padding
anim5:
	.bin	9450, 1890, "../other/data/nyancat.sv"
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

; *** should play initial music here (TBD)

; switch to standard screen
	LDA #%00111000			; colour, RGB mode, SCREEN 3 as usual
	STA IO8attr				; set final video mode

; *****************
; *** main loop ***
; *****************
loop:
; *** if first frame is already on screen, maybe start music frame instead of updating screen?
JSR wait_frame				; delay animation at half the frame rate

; advance to next sprite, resetting if needed
	LDA anim+1				; get frame page
	CLC
	ADC #8					; $800 bytes = 2 kiB
	CMP #>start				; did all frames?
	BNE nowrap
		LDA #>anim0			; back to beginning
nowrap:
	STA anim+1				; update frame pointer
	JSR draw_frame			; show me now!
; time to show some stars... TBD

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
	BVC wait_frame
	RTS

; non-existent interrupt routine (this far)
intexit:
	RTI

; ************************
; *** hardware vectors ***
; ************************

	.dsb	$FFFA-*, $FF	; usual filling to end-of-ROM

	.word	intexit			; no NMI
	.word	start			; code begins here
	.word	intexit			; no interrupts for now
