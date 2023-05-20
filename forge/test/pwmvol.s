; PWM volume control test for Durango-X
; (c) 2023 Carlos J. Santisteban

	*	= $FC00				; 1 Kbyte space should suffice

rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"PWM volume test", 0	; C-string with filename @ [8], max 238 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.dsb	8, '$'			; unused field
; NEW main commit (user field 1) *** currently the hash BEFORE actual commit on multi.s
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$10C1			; 1.0f1

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$9D00			; time, 19.40
	.word	$56B4			; date, 2023/5/20
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *** zeropage usage ***

	ptr		= $FE

; *** PWM table *** page-aligned
pwm:
	.dsb	20, %11111111	; level 0, all off
	.dsb	18, %01111111	; level 1, hope it sounds OK!
	.dsb	18, %01110111	; level 2
	.dsb	18, %01101101	; level 3
	.dsb	18, %01010101	; level 4, near 50%
	.dsb	18, %10010010	; level 5
	.dsb	18, %10001000	; level 6
	.dsb	20, %00000000	; level 7 (actually 8)
	.dsb	18, %10001000	; level 6
	.dsb	18, %10010010	; level 5
	.dsb	18, %01010101	; level 4, near 50%
	.dsb	18, %01101101	; level 3
	.dsb	18, %01110111	; level 2
	.dsb	18, %01111111	; level 1, hope it sounds OK!

; init code
reset:
	SEI
	CLD
	LDX #$FF
	TXS

	STX $DFA0				; turn off LED for a while
	LDA #%10110000
	STA $DF80				; HIRES mode for low power

	STZ ptr
	STZ ptr+1
	LDY #0
	TYA
cl_loop:
		STA (ptr), Y		; clear whole memory for good measure
		INY
		BNE cl_loop
	INC ptr+1
		BPL cl_loop

; *** start PWM sequence ***

	SEC						; allow full extintion
lev_loop:
		LDA pwm, X			; get pattern
pwm_loop:
			STA $DFA0
			STA $DFB0		; apply PWM to both LED and speaker (8)
			ROR				; keep rotating the pattern (2)
			JSR delay		; (12)
			INY				; (2)
			BNE pwm_loop	; (usually 3, total 15+12)
		INX
		BRA lev_loop

delay:
	RTS

return:
	RTI						; just to disable interrupts

; *** padding, signatures and hardware vectors ***

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; minimOS-compliant Durango-X cartridge signature
	.dsb	$FFE1-*, $FF
	JMP ($FFFC)				; devCart support @ $FFE1!

	.dsb	$FFFA-*, $FF	; *** may place PANIC routine here ***

	.word	return			; standard 6502 hardware vectors
	.word	reset
	.word	return
