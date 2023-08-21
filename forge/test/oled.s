; SPI OLED display test
; (c) 2023 Carlos J. Santisteban

; *** definitions ***
IOAie	= $DFA0
IO9sp_c	= $DF9F
IO9sp_d	= $DF9E

#define	SPI5	%11011111

; *** *** ROM contents *** ***
	* = $8000
; Durango-X ROM image header
demo_start:
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; image header for Durango-X devCart SD
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"OLED-display test"
	.word	0				; non-existent comment

; advance to end of header
; commits or version make no sense here, thus all the way to timestamp
	.dsb	demo_start + $F8 - *, $FF

	.word	0
	.word	0				; so far, midnight Jan 1, 1980

; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$8000			; 32K ROM image
	.word	0				; if less than 16M, [255]=NUL may be third magic number

; *** ROM data ***
picture:
	.bin	10, 0, "../../other/data/durango-mono.pbm"

; *** code ***
reset:
; usual 6502 stuff
	SEI
	CLD
	LDX #$FF
	TXS
; Durango-X stuff
	STX IOAie				; turn LED off, but don't bother with screen
; prepare SPI interface
	LDA #SPI5
	STA IO9sp_c				; keep SPI device 5 selected all the time
; init OLED screen via SPI
	LDX #tab_end-tab_start
init_l:
		LDA tab_start, X
		JSR send_spi
		DEX
		BPL init_l
; convert PBM to 

; *** support ***
send_spi:

; *** data tables ***
tab_start:					; OLED init sequence... in reverse!
	.byt	$00, $10, $B0, $AF, $A4, $11, $D9, $7F, $FE, $12, $DA, $00, $20
	.byt	$C8, $A1, $14, $8D, $40, $3F, $A8, $F0, $D5, $AE
tab_end:

; *** *** ROM end *** ***
	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; minimOS compliant
void:
	RTI						; null interrupt handler

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)				; multiBoot support

	.dsb	$FFFA-*, $FF	; hardware vectors
	.word	reset			; NMI as soft reset
	.word	reset
	.word	void
