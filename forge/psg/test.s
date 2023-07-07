; interrupt-driven music player for PSG card in Durango-X! TEST CODE
; (c) 2023 Carlos J. Santisteban
; last modified 20230707-1642

; *** hardware definitions ***
IO8attr	= $DF80
IOAen	= $DFA0
screen3	= $6000

; *** zeropage definitions ***
dest	= $F8				; memory filling

*	= $C000					; convenient 16K ROM

	SCORE	= >music

rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"SN76489A test", 0	; C-string with filename @ [8], max 238 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.dsb	8, '$'			; unused field
; NEW main commit (user field 1) *** currently the hash BEFORE actual commit on multi.s
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$0000

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$A380			; time, 20.28
	.word	$56E5			; date, 2023/7/5
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number


; *** interrupt service ***
#include "player.s"

; *****************
; *** TEST code ***
; *****************
reset:
	SEI						; standard stuff
	CLD
	LDX #$FF
	TXS
	STX IOAen				; turn interrupts on
;	LDY #<isr				; for DevCart compatibility
;	LDX #>isr
;	STY $0200
;	STX $0201
;	LDY #<nmi
;	LDX #>nmi
;	STY $0202
;	STX $0203
	JSR psg_init			; clear stuff!

; init screen
	LDA #%10110000			; HIRES mode
	STA IO8attr
	LDX #1					; initial pattern
	JSR diagonal
; now should enable playback and start scrolling the screen
	LDA #3					; three channels this far
	STA pb_flag				; *** label from player.s ***
	CLI
; keep scrolling
	LDA #2
lock:
		TAX
;		JSR diagonal
		TXA
		ASL
	BCC lock
		ROL
	BRA lock

; diagonal lines routine
diagonal:
	LDA #>screen3
;	LDY #<screen3			; actually zero
	STZ dest
	STA dest+1
raster:
; *** extra code for clearing interraster ***
		LDA #0
		LDY #63
clr_l:
			STA (dest), Y
			DEY
			CPY #31
			BNE clr_l
; *******************************************
		TXA
		LDY #31
sc_loop:
			STA (dest), Y	; fill one raster
			DEY
			BPL sc_loop
		ASL
		BCC carry1			; after bit 7, back to bit 0
			ROL
carry1:
		ROL					; *** double shift
		BCC carry			; after bit 7, back to bit 0
			ROL
carry:
		TAX
		LDA dest
;		CLC
		ADC #64				; advance to next raster
		STA dest
		BCC raster
			INC dest+1		; next page
		BPL raster
	RTS

; **************************
; *** interrupt handlers ***
; **************************
isr:
	PHA
	LDA IO8attr
	EOR #64					; inverse
	STA IO8attr
	PHX
	PHY
	JSR psg_isr
	PLY
	PLX
	LDA IO8attr
	EOR #64					; back to normal
	STA IO8attr
	PLA
nmi:
	RTI

; *******************
; *** music score ***
; *******************

	.dsb	$E000-*, $FF
music:
; ch1 notes
;	.byt	 12,  12,  12,  24,  24,   0,   0
.byt 0,19,0,0,0
	.dsb	$E100-*, $FF
; ch1 lengths [0=end]
;	.byt	250, 250, 250, 250, 250, 250,   0
.byt 125,250,250,250,0
	.dsb	$E200-*, $FF
; ch1 volume
;	.byt	 15,  15,  15,  15,  15,   0,   0
.byt 0,15,0,0,0
	.dsb	$E300-*, $FF
; ch1 envelope
;	.byt	  1,   0, 255,   0, 255,   0,   0
.byt 0,255,0,0,0

	.dsb	$E400-*, $FF
; ch2 notes
;	.byt	  0,  16,  16,  16,  36,  36,  36,   0
.byt 0,0,23,0,0
	.dsb	$E500-*, $FF
; ch2 lengths [0=end]
;	.byt	125, 250, 125, 250, 250, 250, 250,   0
.byt 125,250,250,250,0
	.dsb	$E600-*, $FF
; ch2 volume
;	.byt	  0,  15,  15,  15,  15,  15,   0,   0
.byt 0,0,15,0,0
	.dsb	$E700-*, $FF
; ch2 envelope
;	.byt	  0,   1,   0, 255,   1, 255,   0,   0
.byt 0,0,255,0,0

	.dsb	$E800-*, $FF
; ch3 notes
;	.byt	  0,  19,  19,  48,  48,   0,   0
.byt 0,0,0,26,0
	.dsb	$E900-*, $FF
; ch3 lengths [0=end]
;	.byt	250, 250, 250, 250, 250, 250,   0
.byt 125,250,250,250,0
	.dsb	$EA00-*, $FF
; ch3 volume
;	.byt	  0,  15,  15,  15,  15,   0,   0
.byt 0,0,0,15,0
	.dsb	$EB00-*, $FF
; ch3 envelope
;	.byt	  0,   1, 255,   1, 255,   0,   0
.byt 0,0,0,255,0
; ***************
; *** ROM end ***
; ***************

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)

	.dsb	$FFFA-*, $FF
	.word	nmi
	.word	reset
	.word	isr
