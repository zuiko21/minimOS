; PacMan intro
; (c) 2022 Carlos J. Santisteban
; last modified 20220910-2205

#include "../../OS/macros.h"

; *** definitions ***
IO8attr	= $DF80
IO8sync	= $DF88
IOAen	= $DFA0
screen3	= $6000
ban_pos	= $6CC0				; line 51 looks nicer, and makes animation simpler!
ctl_pos	= $7440				; bottom of the screen
sp_buf	= $1000				; sprite buffer

; *** zeropage usage *** placeholder
orig	= $F0
dest	= $F2
tmp		= $F4
rle_src	= orig				; pointer to compressed source
rle_ptr	= dest				; pointer to screen output

; *****************
; *** init code ***
; *****************
	* = $8000				; use -a 0x8000 anyway

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
	STA tmp
; the fun begins!
an_loop:
		LDA #$6C			; position MSB
		STA dest+1
		LDA tmp				; current LSB
		STA dest
		AND #7				; mod 8
		TAX
		LDA af_ind, X		; get frame index (MSB of sprite file)
		STA orig+1
		STZ orig
		JSR frame			; draw!
		INC tmp				; next position
		BNE an_loop
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

end: JMP end

; *** useful routines ***

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
	LDX #20					; raster counter
fr_ras:
		LDY #10				; max offset for 22-pix wide *** must be less if close to the edge
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

; **************************
; *** animation sequence *** get MSB from here (index = byte offset % 8)
; **************************
af_ind:
	.byt	$13, $10, $11, $12, $11, $10, $13, $14

; **********************
; *** included files ***
; **********************
rle:
#include "../../OS/firmware/modules/rle.s"

banner:
	.bin	0, 0, "../../other/data/title_c.rle"

controls:
	.bin	0, 0, "../../other/data/controls.rle"

anim:
	.bin	0, 0, "../../other/data/ipac.rle"
