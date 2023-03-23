; dithered picture test for Durango-X
; (c) 2023 Carlos J. Santisteban


; *** definitions ***
IO8attr	= $DF80
IO8blnk	= $DF88
IO9kbd	= $DF9B
IOAie	= $DFA0

; *** RAM usage ***
ptr		= $C0
src		= ptr+2


; *** code ***
	*	= $9e00				; needs whole 32K because of 24K worth of pictures!
rom_start:
; *** *** *** header ID *** *** ***
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"multidither", 0	; C-string with filename @ [8], max 238 chars
	.asc	"a picture of Draghica Laurent"		; optional C-string with comment after filename, filename+comment up to 238 chars
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
reset:
	SEI
	CLD
	LDX #$FF
	TXS						; usual 6502 stuff
	STX IOAie				; enable Durango-X interrupts; not used but turns LED off
	LDA #$08				; RGB mode, note screen 0!
	STA IO8attr				; set video mode
; clear available screen for intro
	LDX #$02				; safe page
	LDY #0
	LDA #$22				; red screen!
	STY ptr
pg_clear:
		STX ptr+1
loop_clear:
			STA (ptr), Y
			INY
			BNE loop_clear
		INX
		CPX #$20			; first page of screen 1
		BNE pg_clear
; in the meanwhile, copy ROM pictures into RAM
	LDA #<rom_pics
	STA src
	LDA #>rom_pics
	STA src+1				; pointers are set
pg_copy:
		STX ptr+1
loop_copy:
			LDA (src), Y
			STA (ptr), Y
			INY
			BNE loop_copy
		INC src+1
		LDA src+1
		CMP #$DF			; skip I/O
		BNE not_io
			INX
			INC src+1
not_io:
		INX
		BPL pg_copy			; negative is the end of screen 3
; display dots waiting for a key press...
	LDA #$82				; left pixel will become blue
	STA $101F
	STA $1020
	STA $1021
; wait for any keypress
wait_key:
		LDA #16				; fifth column
sel_col:
			STA IO9kbd		; select column
			LDX IO9kbd		; and get any rows pressed
		BNE cycle			; start animation!
			LSR				; previous column
		BCC sel_col
	BCS wait_key			; check forever
; go for it!
cycle:
	LDA #$18				; screen 1, RGB mode
frame:
		STA IO8attr
exit_blank:
			BIT IO8blnk
			BVS exit_blank
wait_blank:
			BIT IO8blnk
			BVC wait_blank
; advance to next screen
		CLC
		ADC #$10
		CMP #$40
		BCC frame
	BCS cycle				; start again, forever
_end_code:

; *** images ***
rom_pics:
	.bin	0, 0, "../../other/data/dl1.sv"
	.bin	0, 0, "../../other/data/dl2.sv"
	.bin	0, 0, "../../other/data/dl3.sv"
end_pics:

; *** end of ROM stuff ***
	.dsb	$FFD6-*, $FF	; filler

	.asc	"DmOS"			; standard sigature
null:
	RTI						; null interrupt handler, just in case

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)				; devCart support

	.dsb	$FFFA-*, $FF
	.word	reset			; NMI like reset
	.word	reset
	.word	null			; IRQ/BRK do nothing

