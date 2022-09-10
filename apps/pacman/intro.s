; PacMan intro
; (c) 2022 Carlos J. Santisteban
; last modified 20220910-1706

#include "../../OS/macros.h"

; *** definitions ***
IO8attr	= $DF80
IO8sync	= $DF88
IOAen	= $DFA0
screen3	= $6000
ban_pos	= $6D00				; line 52 looks nicer

; *** zeropage usage *** placeholder
orig	= $F0
dest	= $F2
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

end: JMP end

; **********************
; *** included files ***
; **********************
rle:
#include "../../OS/firmware/modules/rle.s"

banner:
	.bin	0, 0, "../../other/data/title_c.rle"
