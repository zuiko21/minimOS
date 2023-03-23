; test of hires Durango-X font
; (c) 2021-2023 Carlos J. Santisteban 

	* =	$F000
rom_start:
; *** *** *** header ID *** *** ***
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"font", 0	; C-string with filename @ [8], max 238 chars
	.asc	"Colour font demo"		; optional C-string with comment after filename, filename+comment up to 238 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $F8 - *, $FF

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5800			; time, 11.00
	.word	$5673			; date, 2023/3/19
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number
; ***************************

; zeropage usage
ptr		= 0
org		= 2
ink		= 4
paper	= 5
fd		= 6
cnt		= 7

; code & I/O location
io8flags	= $DF80			; will be $DF80

reset:
	SEI
	CLD
	LDX #$FF
	TXS
	STX $DFA0
; init stuff
	LDA #$38
	STA io8flags			; set colour mode
	LDY #0
	STY paper				; reset background colour, assume 0
	STY ptr
	STY org					; assume font is page-aligned
	LDX #$60				; screen start
	STX ptr+1
	LDX #>font				; font start
	STX org+1

; ****************************
; go for it!

row:
		LDA #8
		STA cnt				; preset raster count
raster:
			LDY #0			; reset horizontal offset
			STY ink			; reset horizontal colour!
char:
				LDA (org)	; CMOS, LDAX is suitable replacement
				STA fd		; font byte read
				LDX #4		; four screen bytes each font byte
fourb:
					ASL fd	; extract leftmost bit
					BCC nleft		; was clear
						LDA ink		; or use foreground colour
						BRA sleft
nleft:
					LDA paper
sleft:
					ASL		; put the colour into leftmost pixel
					ASL
					ASL
					ASL
					ASL fd	; extract next bit
					BCC nright		; was clear
						ORA ink		; or use foreground colour
						BRA sright
nright:
					ORA paper
sright:
					STA (ptr), Y	; store byte
					INY				; advance address
					DEX				; one less for each font byte
					BNE fourb
				LDA org
				CLC
				ADC #8		; next char is 8 bytes ahead in font
				STA org		; assume page-aligned, otherwise carry might occur!
				INC ink		; each char in a different colour
				CPY #64		; end of raster?
				BNE char
; new raster, must reset screen offset
			TYA				; it is 64 already
			CLC
			ADC ptr			; ptr += Y
			STA ptr
			BCC rnw
				INC ptr+1	; will happen every 4 rasters!
rnw:
; now get back 16 chars but advance one raster
			LDA org
			SEC
			SBC #127		; 16*8-1
			STA org			; should not wrap...
; before next raster, check out row change
			DEC cnt			; one less raster
			BNE raster
; all rasters done, go for next row
		LDA org
		CLC
		ADC #120			; advance 15 chars, as eventually advanced 1
		STA org
		BCC lnw
			INC org+1
lnw:
		INC paper
		LDA paper
		CMP #16				; all lines done?
		BNE row

; ****************************
; ended, keep psychedelic bars
	LDA #$38				; keep colour mode...
lock:
; inverse bars 
	STA io8flags			; set flags
	LDX #4
rb_1:
		INX
		BNE rb_1			; delay 1.28 kt (~830 µs, 600 Hz)
	CLC
	EOR #64					; toggle inverse mode
	BRA lock
none:
	RTI

	.dsb	$F200-*, $FF
font:
#include "../../OS/drivers/fonts/8x8.s"
end:
; *** fill and vectors ***
	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)				; devCart support

	.dsb	$FFFA-*, $FF

	.word reset				; NMI does cold start
	.word reset				; RESET does full init
	.word none				; IRQ does nothing


