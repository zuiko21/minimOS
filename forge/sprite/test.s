; masked sprites demo for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220715-1123

; *** variables and pointers ***
IO8attr	= $DF80				; video mode register
IO8blk	= $DF88				; sync signals
screen3	= $6000				; standard screen address

; *** zeropage definitions ***
screen	= 3					; pointer to screen, with offset for desired sprite position
bg		= 5					; pointer to 'intact' background, like the above (PAGE ALIGNED with it, which is easy)
sprite	= 7					; pointer to sprite data (PAGE ALIGNED with mask)
mask	= 9					; pointer to sprite mask ($00=opaque/$F0/$0F/$FF=transparent) may be offset if L-clipping
spr_wid	= 11				; sprite width in bytes (maxoff+1 if no clipping)
maxoff	= 12				; number of bytes per raster to transfer - 1 (may be less than width in case of clipping)
maxras	= 13				; number of rasters to transfer - 1 (aka sprite height-1)
; *** extra data for this test ***
pos_s	= 14				; pointer to screen position (backup)
pos_b	= 16				; pointer to background (backup)
dir		= 18				; sprite X direction (0=right/-1=left)

; *** ROM starts with binaries ***
	* = $C000

background:
	.bin	0, 8192, "../../other/data/elvira.sv"	; background picture

; should be $E000
sprites:
	.bin	0, 2240, "../../other/data/sprites.sv"	; sprite data (28*32, 448 bytes each)
	.dsb	$E900-*, $FF							; ended at $E8C0, mask MUST be page-aligned!
masks:
	.bin	0, 2240, "../../other/data/mask.sv"		; mask data (28*32, 448 bytes each)

; *** data structures ***

; *** sprite routines ***
#include "mask.s"

; *** initialisation code ***
demo:
	LDA #$38
	STA IO8attr				; set colour mode, screen 3
; copy background to screen
	LDA #>screen3
	LDX #>background
	LDY #0
	STY dir					; important, start to the right
	STA screen+1			; set screen pointer (will be used by sprites)
	STX bg+1				; also background
	STY screen
	STY bg					; page-aligned, and index is reset!
copy:
		LDA (bg), Y
		STA (screen), Y		; copy background into screen
		INY
		BNE copy
			INC bg+1		; in case of page crossing...
			INC screen+1	; ...look for end of screen ($8000)
		BPL copy
; initialise some sprite data structures ***
	LDA #>(screen3+3200)	; Y=50
	LDX #>(background+3200)
	LDY #<(screen3+3200)	; X=0
	STA pos_s+1
	STX pos_b+1
	STY pos_s
	STY pos_b				; LSB is the same as they're page-aligned
	LDX #14					; sprites are 28 pixels wide, thus 14 bytes
	STX spr_wid
	DEX
	STX maxoff				; counter will go 13 down
anim:
		STY pos_s				; must update this!
		STY pos_b				; needed?
		LDA pos_s+1				; get position backup
		LDX pos_b+1
;		LDY pos_s
		STA screen+1			; restore this as may change
		STX bg+1
		STY screen
		STY bg					; LSB is the same as they're page-aligned
; this data will remain constant, but must be reloaded
		LDY #31					; sprites are 32 pixels tall, thus maxras is 31
		STY maxras
		LDA #>(sprites+3*448)	; fourth sprite
		LDX #>(masks+3*448)		; fourth sprite mask
		LDY #<(sprites+3*448)
		STA sprite+1
		STX mask+1
		STY sprite
		STY mask				; LSBs are the same
; single sprite test animation!
		JSR raster
; let's do ANOTHER sprite
		LDY pos_s+1				; get position backup
		LDX pos_b+1
;		LDA pos_s				; LSB will be "inverted"
		LDA #$B1
		SEC
		SBC pos_s
		CLC
		ADC #$80
		INX						; I think this will turn the sprite 32 rasters down
		INX
		INX
		INX
		INY
		INY
		INY
		INY
		STY screen+1			; restore this as may change
;		STY bg+1				; OVERLAP *** does NOT work this way
		STX bg+1
		STA screen
		STA bg					; LSB is the same as they're page-aligned
; this data will remain constant, but must be reloaded
		LDY #31					; sprites are 32 pixels tall, thus maxras is 31
		STY maxras
		LDA #>(sprites+4*448)	; fifth sprite
		LDX #>(masks+4*448)		; fifth sprite mask
		LDY #<(sprites+4*448)
		STA sprite+1
		STX mask+1
		STY sprite
		STY mask				; LSBs are the same

		JSR raster
; and ANOTHER sprite
		LDY pos_s+1				; get position backup
		LDX pos_b+1
		LDA pos_s				; LSB will be "halved"
		LSR
		CLC
		ADC #$40
		PHA						; save for another!
		DEX						; I think this will turn the sprite 32 rasters up
		DEX
		DEX
		DEX
		DEX
		DEX
		DEX
		DEX
		PHX						; save for another!
		DEY
		DEY
		DEY
		DEY
		DEY
		DEY
		DEY
		DEY
		PHY						; save for another!
		STY screen+1			; restore this as may change
		STX bg+1
		STA screen
		STA bg					; LSB is the same as they're page-aligned
; this data will remain constant, but must be reloaded
		LDY #31					; sprites are 32 pixels tall, thus maxras is 31
		STY maxras
		LDA #>(sprites+1*448)	; 2nd sprite
		LDX #>(masks+1*448)		; 2nd sprite mask
		LDY #<(sprites+1*448)
		STA sprite+1
		STX mask+1
		STY sprite
		STY mask				; LSBs are the same

		JSR raster

; afraid of NOTHING
		PLY						; retrieve previous positions!
		PLX
		PLA
		LSR
		CLC
		ADC #$60
		DEX						; I think this will turn the sprite 16 rasters up
		DEX
		DEX
		DEX
		DEY
		DEY
		DEY
		DEY
		STY screen+1			; restore this as may change
		STX bg+1
		STA screen
		STA bg					; LSB is the same as they're page-aligned
; this data will remain constant, but must be reloaded
		LDY #31					; sprites are 32 pixels tall, thus maxras is 31
		STY maxras
		LDA #>(sprites)		; 1st sprite
		LDX #>(masks)		; 1st sprite mask
		LDY #<(sprites)
		STA sprite+1
		STX mask+1
		STY sprite
		STY mask				; LSBs are the same

		JSR raster

/*
wait:
			BIT IO8blk
			BVC wait		; wait for VSYNC
sync:
			BIT IO8blk
			BVS sync		; wait for display?*/
;		LDY pos_s
;		INY
;		CPY #$b2			; end for this demo
;		BNE anim
;			LDY #$80
;		BNE anim
		LDY pos_s
		BIT dir				; check direction
		BMI left
			INY
			CPY #$B2		; check right limit
			BNE done
				LDY #$B0
				DEC dir		; was 0, goes $FF, move to the left
			BNE done
left:
		DEY
		CPY #$7F
		BNE done
			LDY #$81
			INC dir			; was -1, now 0
done:
		JMP anim

	.dsb	$FFFA - *, $DB	; ROM filling

	.word demo
	.word demo
	.word demo
