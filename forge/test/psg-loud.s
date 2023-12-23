; Durango·X PSG loudness test
; (c) 2023 Carlos J. Santisteban

#echo	PSG loudness test

; *** hardware definitions ***
screen	= $6000
IO8attr	= $DF80
IOAie	= $DFA0
IO_PSG	= $DFDB				; PSG riser port

ptr		= $FE				; indirect pointer

	* = $C000				; 16 kiB ROM image, non-downloadable

; ***********************
; *** standard header *** to be found before ANY ROM image
; ***********************
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"PSG loudness test"		; C-string with filename @ [8], max 220 chars
; optional C-string with comment after filename, filename+comment up to 220 chars
	.asc	0, 0

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1000			; 1.0a0		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$52C0			; time, 18.22		%1001 0-010 110-0 0000
	.word	$5786			; date, 2023/12/06	%0101 011-1 100-0 0110
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

reset:
	SEI
	CLD
	LDX #$FF
	TXS						; usual 6502 stuff
; Durango-X specifics
	STX IOAie				; enable interrupt hardware, turn off error LED
	LDA #$B0				; HIRES, screen 3
	STA IO8attr
; clear screen for good measure
	LDA #>screen
	LDY #<screen			; 0
	STY ptr
	STA ptr+1				; set indirect pointer
	TYA						; 0 is expected
clear:
			STA (ptr), Y
			INY
			BNE clear
		INC ptr+1
		BPL clear
; Set PSG for maximum loudness!
	LDA #%10010000			; min. attenuation channel 0
psg_mute:
		STA IO_PSG
		JSR psg_del			; suitable 36-cycle delay
		CLC
		ADC #32				; next channel
		BMI psg_mute
; set adequate frequencies
	LDX #3					; max channel offset
psg_load:
		JSR psg_del			; suitable 36-cycle delay
		LDA frq_lo, X
		STA IO_PSG
		JSR psg_del			; suitable 36-cycle delay
		LDA frq_hi, X
		STA IO_PSG
		DEX
		BNE psg_load
; *** lock ***
lock:
				INX
				BNE lock
			INY
			BNE lock
		INC
		STA IOAie
		JMP lock

; delay routine for PSG access
psg_del:
	JSR psg_rts
	JSR psg_rts
psg_rts:
	RTS

; ************
; *** data ***
; ************
frq_lo:
	.byt	%10000000, %10100000, %11000000, %11101100

frq_hi:
	.byt	%00001000, %00000100, %00000010, %11101100
; **************************
; *** interrupt handlers ***
; **************************
irq:
	RTI

; ***************************
; *** devCart ROM support ***
; ***************************

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFE1-*, $FF

	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
	.dsb	$FFFA-*, $FF

; *****************************
; *** standard 6502 vectors ***
; *****************************
* = $FFFA
	.word	reset			; NMI will do cold reset
	.word	reset
	.word	irq
rom_end:
