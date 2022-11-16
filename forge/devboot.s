; development cartridge boot firmware for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20221116-1335

.(
	*	= $C000				; 16 KiB seems enough
reset:
	SEI						; standard 6502 init
	CLD
	LDX #$FF
	TXS
	LDA #$38				; colour mode as standard
	STA IO8attr
; fill screen with some colour?
; check ROM integrity?
; *** copy actual ROM into shadow RAM ***
	LDY #<reset				; actually 0
	LDX #>reset
	STY ex_ptr				; set ZP pointer
copy_p:
		STX ex_ptr+1		; update page
copy_l:
			LDA (ex_ptr), Y
			STA (ex_ptr), Y	; read from ROM, write in RAM
			INY
			BNE copy_l		; next byte
		INX
		BMI copy_p			; until the end of ROM
; menu? nanoboot with timeout? check SD?


; *********************************************
; *********************************************
	.dsb	$FFD1-*, $FF	; ROM padding until last 47 bytes
; 13-byte PANIC routine, just make the LED flash
panic_l:
				SEI
				INX
				BNE panic_l
			INY
			BNE panic_l
		INC
		STA IOAien			; make LED toggle every ~0.3s
		BRA panic_l
; 4 extra bytes for further compatibility
checksum:
	.word	$FFFF			; standard checksum address reserved
panic:
	BRA panic_l				; standard PANIC call @ $FFE0
; *** standard ROM contents (last 30 bytes) ***
irq_hndl:
	JMP ($0200)
nmi_hndl:
	JMP ($0202)
switch:
	LDY ex_ptr				; get load vector
	LDA ex_ptr+1
	STY $FFFC				; set hard vector in shadow RAM!
	STA $FFFD
go_ram:
	LDA #%11				; disable ROM, write-protect RAM
	STA IOCmode				; switch to code in RAM now...
	JMP ($FFFC)				; ...and jump to desired reset vector (must be set in RAM)
; *** hardware vectors from $FFFA ***
vectors:
	.word	nmi_hndl
	.word	reset
	.word	irq_hndl
