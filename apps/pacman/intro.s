; PacMan intro
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230323-1701

#include "../../OS/macros.h"

; *** definitions ***
IO8attr	= $DF80
IO8sync	= $DF88
IOAen	= $DFA0
IOBeep	= $DFB0
screen3	= $6000
ban_pos	= $6CC0				; line 51 looks nicer, and makes animation simpler!
ctl_pos	= $7440				; bottom of the screen
sp_buf	= $1000				; sprite buffer

; *** zeropage usage *** placeholder
orig	= $F0
dest	= $F2
pos		= $F4
temp	= pos
width	= $F5
redraw	= $F6
rle_src	= orig				; pointer to compressed source
rle_ptr	= dest				; pointer to screen output

; *****************
; *** init code ***
; *****************
#ifndef	MULTIBOOT
	* = $E800				; 6K OK for now

rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Pacman intro", 0	; C-string with filename @ [8], max 238 chars
;	.asc	"(comment)"		; optional C-string with comment after filename, filename+comment up to 238 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $F8 - *, $FF

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5800			; time, 11.00
	.word	$5673			; date, 2023/3/19
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

#endif

intro:
; usual 6502 stuff
	SEI
	CLD
	LDX #$FF
	TXS
; Durango-X init
	STX IOAen
	LDA #$38				; colour mode
	STA IO8attr

; *******************
; *** intro start ***
; *******************
; clear screen
	LDX #>screen3
	LDY #0					; actually <screen3
	STY dest
	TYA						; black background
cpage:
		STX dest+1			; update MSB
cl_l:
			STA (dest), Y
			INY
			BNE cl_l
		INX					; next page
		BPL cpage			; stops at $8000
; decompress banner
	LDX #>ban_pos
	LDY #<ban_pos
	STY dest				; set banner screen position
	STX dest+1
	LDX #>banner
	LDY #<banner
	STY orig				; set compressed data source
	STX orig+1
	JSR rle					; decompress!
	LDA #14					; ~3 sec delay
	JSR delay
; pacman animation!
	LDX #>sp_buf
	LDY #<sp_buf
	STY dest				; this will decompress into free RAM
	STX dest+1
	LDX #>anim
	LDY #<anim
	STY orig				; set compressed data source
	STX orig+1
	JSR rle					; decompress!
	LDA #$D1				; byte LSB to initial pacman position
	STA pos
; *** redraw extra code ***
	LDX #$70				; position of area to be redrawn
	LDY #$11
	STY redraw
	STX redraw+1
; *************************
; the fun begins!
an_loop:
		LDA #$6C			; position MSB
		STA dest+1
		LDA pos				; current LSB
		STA dest
; *** code to correct missing part of the A ***
		PHA
		CMP #$D3			; when pacman clears A eeeeeeek
		BNE an_cont
; redraw 4x7 pix area, note horizontal flip, byte level! (pixels=2301...)
			LDX #0
rd_vloop:
				LDY #1
rd_hloop:
					LDA repeat, X	; get original data
					STA (redraw), Y	; restore screen
					INX				; next origin byte
					DEY
					BPL rd_hloop
				LDA redraw
				CLC
				ADC #64
				STA redraw
				BCC rd_ok
					INC redraw+1
rd_ok:
				CPX #14				; finished?
				BNE rd_vloop
an_cont:
		PLA
; *********************************************
		AND #7				; mod 8
		TAX
		LDA af_ind, X		; get frame index (MSB of sprite file)
		STA orig+1
		STZ orig
		JSR frame			; draw!
		INC pos				; next position
		BNE an_loop
; wait a bit before redrawing
	LDA #7
	JSR delay
; decompress banner again
	LDX #>ban_pos
	LDY #<ban_pos
	STY dest				; set banner screen position
	STX dest+1
	LDX #>banner
	LDY #<banner
	STY orig				; set compressed data source
	STX orig+1
	JSR rle					; decompress!
; decompress controls
	LDX #>ctl_pos
	LDY #<ctl_pos
	STY dest				; set banner screen position
	STX dest+1
	LDX #>controls
	LDY #<controls
	STY orig				; set compressed data source
	STX orig+1
	JSR rle					; decompress!

; game init TBD
lda #20: jsr delay
; ***************************
; *** show initial screen ***
; ***************************
	LDX #>screen3
	LDY #<screen3
	STY dest				; set banner screen position
	STX dest+1
	LDX #>maze4
	LDY #<maze4
	STY orig				; set compressed data source
	STX orig+1
	JSR rle					; decompress!

; ***********************
; *** play the music! ***
; ***********************
music:
	LDX #0					; *** don't know if X is still zero after positions AND drawing sprites
	STX temp				; reset cursor (temporary use)
m_loop:
		LDY temp			; get index
		LDX m_len, Y		; get length from duration array
			BEQ m_end		; length=0 means END of score
		LDA m_note, Y		; get note period (10A+20 t) from its array
		BEQ mc_rest			; if zero, no sound!
			JSR m_beep		; play this note (exits with Z)
			BRA m_next		; go for next note
mc_rest:
		JSR m_rest
m_next:
		INC temp			; advance cursor to next note
		BNE m_loop
m_end:


end: JMP end
; ***********************
; *** useful routines ***
; ***********************
; some delay (approx. A * 213 ms)
delay:
				INX
				BNE delay
			INY
			BNE delay
		DEC
		BNE delay
	RTS

; * draw animation frame 22x20 *
; set orig and dest (with byte offset) as desired
frame:
	LDA #$FF
	SEC
	SBC pos					; how many bytes until the end?
	CMP #10					; max offset for 22-pix wide
	BCC w_ok				; too close, use available space
		LDA #10				; if far enough, take standard value
w_ok:
	STA width				; 10 or less
	LDX #20					; raster counter
fr_ras:
		LDY width
fr_loop:
			LDA (orig), Y	; get sprite data
			STA (dest), Y	; put on screen
			DEY
			BPL fr_loop
		LDA orig			; add 11 to orig
		CLC
		ADC #11
		STA orig
;		BCC o_now			; manage possible carry *** not possible if frames (220-byte) are page-aligned
;			INC orig+1
;o_now:
		LDA dest			; add 64 to dest
		CLC
		ADC #64
		STA dest
		BCC d_now			; manage possible carry
			INC dest+1
d_now:
		DEX					; next raster
		BNE fr_ras
	LDX #2					; frames to wait
sync:
			BIT IO8sync		; wait for vsync
			BVS sync		; still on it
wait:
			BIT IO8sync
			BVC wait
		DEX
		BNE sync
	RTS

; *** ** beeping routine ** ***
; *** X = length, A = freq. ***
; *** X = 2*cycles          ***
; *** tcyc = 16 A + 20      ***
; ***     @1.536 MHz        ***
; modifies Y, returns X=0
m_beep:
	PHP
	SEI						; eeeeeek
beep_l:
		TAY					; determines frequency (2)
		STX IOBeep			; send X's LSB to beeper (4)
rb_zi:
			STY orig		; small delay for 1.536 MHz! (3)
			DEY				; count pulse length (y*2)
			BNE rb_zi		; stay this way for a while (y*3-1)
		DEX					; toggles even/odd number (2)
		BNE beep_l			; new half cycle (3)
	STX IOBeep				; turn off the beeper!
	PLP						; restore interrupts... if needed
	RTS

; *** ** rest routine ** ***
; ***     X = length     ***
; *** X 1.33 ms @ 1.536M ***
; modifies Y, returns X=0
m_rest:
		LDY #0				; this resets the counter
r_loop:
			STY orig		; delay for 1.536 MHz
			INY
			BNE r_loop		; this will take ~ 1.33 ms
		DEX					; continue
		BNE m_rest
	RTS

; ************************
; *** external library ***
; ************************
rle:
#include "../../OS/firmware/modules/rle.s"

int:
	RTI						; void interrupt

; *** *** DATA *** ***

; **************************
; *** animation sequence *** get MSB from here (index = byte offset % 8)
; **************************
af_ind:
	.byt	$13, $10, $11, $12, $11, $10, $13, $14

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

; ************************
; *** missing 'A' part *** note byte-level flip! 2301...
; ************************
repeat:
	.byt	$00, $80
	.byt	$00, $80
	.byt	$00, $88
	.byt	$00, $78
	.byt	$80, $78
	.byt	$80, $77
	.byt	$88, $88

; **********************
; *** included files ***
; **********************
banner:
	.bin	0, 0, "../../other/data/title_c.rle"

controls:
	.bin	0, 0, "../../other/data/controls.rle"

anim:
	.bin	0, 0, "../../other/data/ipac.rle"

maze4:
	.bin	0, 0, "../../other/data/maze4.rle"

; ************************
; *** ROMmable version ***
; ************************
#ifndef	MULTIBOOT
	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFE1-*, $FF
autoreset:
	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
	.dsb	$FFFA-*, $FF	; padding

	.word	int
	.word	intro			; RESET vector
	.word	int
#endif
