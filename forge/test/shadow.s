; Durango-X shadowRAM test
; (c) 2024 Carlos J. Santisteban
; last modified 20241001-1418

*	= $8000					; 0.5K file with 256-byte payload
; *** *** standard header *** ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"ShradowRAM test", 0		; C-string with filename @ [8], max 238 chars
	.asc	"for Durango·X + devCart and DurangoPLUS"		; comment with IMPORTANT attribution
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$0101			; 0.1a1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$7240			; time, 14.18		%0111 0-010 010-0 0000
	.word	$5941			; date, 2024/10/1	%0101 100-1 010-0 0001
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *** hardware definitions ***
	screen3	= $6000
	strip	= $6F00
	display	= $705F
	IO8attr	= $DF80
	IOAie	= $DFA0
	IOCart	= $DFC0

; *** memory allocation ***
	ptr		= $FC

; *****************
; *** init code ***
; *****************
reset:
	SEI
	CLD
	LDX #$FF
	TXS						; basic 6502 init
	STX IOAie				; turn LED off
	LDA #$38				; screen 3, colour mode, RGB
	STA IO8attr
; clear screen for good measure
	LDX #>screen3
	LDY #<screen3			; expected 0
	TYA						; will set screen black as well
	STY ptr
p_cls:
		STX ptr+1
l_cls:
			STA (ptr), Y
			INY
			BNE l_cls		; clear full page
		INX					; next page
		BPL p_cls			; valid until the end of mux-RAM
; *** test code ***
	LDA #%01111100			; make sure ShadowRAM is write-protected
	STA IOCart
	LDX #0					; reset index
rpt:
		LDA #$11			; mid green for a start
loop:
				STA reset, X			; try overwriting the code
				STA strip, X			; and display on screen as well
				INX
				BNE loop				; complete page
			CLC
			ADC #$11		; next colour
			BCC loop
		INC display+1		; increment cycle counter LSB
	BNE rpt
		INC display			; MSB as well, if needed (note endianness)
	BRA rpt					; restart cycle

; *******************************
; *** dummy interrupt handler ***
; *******************************
irq:
	PHA
	PHX
	TSX
	LDA $0103, X			; get stored PSR
	AND #$10				; check B bit
	BEQ exit
; BRK was detected, start blinking the LED
lock:
				INX
				BNE lock
			INY
			BNE lock		; ~0.3s delay
		INC					; toggle d0
		STA IOAie			; towards LED status
		BRA lock
exit:
	PLX
	PLA
	RTI

; *****************************
; *** alignment and ROM end ***
; *****************************
	.dsb	$FFD6-*, $FF	; padding

	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFE1-*, $FF
; * = $FFE1
autoreset:
	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
; *****************************
; *** standard 6502 vectors ***
; *****************************
	.dsb	$FFFA-*, $FF

; * = $FFFA
	.word	reset			; NMI as warm reset
	.word	reset
	.word	irq
