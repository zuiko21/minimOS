; Durango-X lines demo!
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230323-1722

*	= $FA00					; 1.5 K
; *** *** standard header *** ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"line drawing test", 0	; C-string with filename @ [8], max 238 chars
	.asc	"for Durango�X"		; comment with IMPORTANT attribution
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $F8 - *, $FF

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5800			; time, 11.00
	.word	$5673			; date, 2023/3/19
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number
; *** *** *** ***

#include "../../OS/firmware/modules/durango-line.s"
#include "../../OS/firmware/modules/durango-plot.s"
#include "../../OS/firmware/modules/durango-vert.s"

seed	= $FE
ptr		= $EA

;#define	HIRES
;#define		USE_VLINE

#ifdef	HIRES
#define	LIMIT	255
#else
#define	LIMIT	127
#endif

reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
	STX $DFA0				; will turn off LED for peace of mind
	STX px_col				; original colour (white)

#ifdef	HIRES
	LDA #$B0
#else
	LDA #$38
#endif

; finish Durango & PRNG init
	STA IO8attr				; set proper video mode
	JSR randomize

start:
; clear screen
	LDY #0
	LDX #$60				; screen address
	STY ptr
	TYA						; eeeek
cl_p:
		STX ptr+1
cl_b:
			STA (ptr), Y
			INY
			BNE cl_b
		INX
		BPL cl_p
; draw 256 lines and stop
	STY 0					; line counter
loop:
		JSR random			; get random coordinates and colour
#ifndef	USE_VLINE
		JSR dxline			; draw line
#else
		LDX x1
try:
			LDY y1
			TYA
			SEC
			SBC y2
			STA y_cnt
			CLC
			ADC y1
#ifndef	HIRES
			BMI try			; way too much
#else
			BCS try
#endif
		JSR v_line
#endif
		INC 0
		BNE loop			; in aeternum
lock:
	JMP lock

; *** set random seed ***
randomize:
	LDX #$88
	STX seed
	INX
	STX seed+1
	JSR rnd					; further randomizing
	RTS

; *** fill coordinates (and colour) randomly ***
random:
	JSR rnd
	AND #LIMIT
	STA x1
	JSR rnd		; comment for vertical only
	AND #LIMIT
	STA x2
	JSR rnd
	AND #LIMIT
	STA y1
	JSR rnd		; comment for horizontal only
	AND #LIMIT
	STA y2
	JSR rnd		; this will be colour
#ifndef	HIRES
	AND #15
	STA tmp
	ASL
	ASL
	ASL
	ASL
	ORA tmp		; II format, for HIRES will just look for d7
#endif
	STA px_col
	RTS

; *** generate random number ***
; based on code from https://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
rnd:
	LDA seed
		BEQ lo_z
	ASL seed
	LDA seed+1
	ROL
	BCC no_eor
do_eor:
		STA seed+1
do_eor2:
		LDA seed
		EOR #$2D
		STA seed
	RTS
lo_z:
	LDA seed+1
		BEQ do_eor2
	ASL
	BEQ no_eor
	BCS do_eor
no_eor:
	STA seed+1
	RTS

; disabled interrupt
none:
	RTI

; *** fill and vectors ***
	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)				; devCart support

	.dsb	$FFFA-*, $FF

	.word start				; NMI does cold start
	.word reset				; RESET does full init
	.word none

