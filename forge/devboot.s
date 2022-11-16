; development cartridge boot firmware for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20221117-0011

.(
	*	= $C000				; 16 KiB seems enough
reset:
	SEI						; standard 6502 init
	CLD
	LDX #$FF
	TXS
	LDA #$38				; colour mode as standard
	STA IO8attr
	STX IOAien				; turn off led for a while
; fill screen with some colour
	LDA #$22				; red while checking ROM, will stay red in case of error
	JSR fill
; *** check ROM integrity ***
	LDX #>reset				; start page as per interface
	LDY #<reset				; this will reset index too
	STY ptr
	STY sum					; reset values too
	STY chk
p_loop:
		STX ptr+1			; temporary ZP pointer
; main loop, original version takes 20b, 426kt for 16KB ~0.28s on Durango-X
loop:
			LDA (ptr), Y	; get ROM byte (5+2)
			CLC
			ADC sum			; add to previous (3+3+2)
			STA sum
			CLC
			ADC chk			; compute sum of sums too (3+3+2)
			STA chk
			INY
			BNE loop		; complete one page (3..., 6655t per page)
		INX					; next page (2)
; MUST skip IO page (usually $DF), very little penalty though
		CPX #$DF			; I/O space?
		BNE f16_noio
			INX				; skip it!
f16_noio:
;		CPX af_pg			; VRAM is the limit for downloaded modules, otherwise 0
		BNE p_loop			; will end at last address! (3...)
; now compare computed checksum with ZERO
;	LDA chk					; this is the stored value in A, saves two bytes
	ORA sum					; any non-zero bit will show up
	BEQ good				; otherwise, all OK!
; non-zero is invalid, sum & check as output parameters for checking
		JMP panic
good:
	LDA #$DD				; azur...
	JSR fill				; means checksum passed
; check RAM? hard to do with cartridge's
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
	LDA #$BB				; light pink...
	JSR fill				; means ROM copied into RAM
; menu? nanoboot with timeout? check SD?
; limit indicator:
;	LDY #$22				; red for end of scale
;	LDA limit
;	JSR dot

; progress indicator:
;		LDY #$11			; medium green as indicator
;		LDA page
;		JSR dot
; *********************************************
; *** useful routines ***
fill:
; fill screen with colour in A (II format)
	LDX #$60
	LDY #0
	STY ex_ptr
f_page:
		STX ex_ptr+1
f_loop:
			STA (ex_ptr), Y
			INY
			BNE f_loop
		INX
		BPL f_page
	RTS

dot:
; show dot of colour Y in coord depending on A
	LSR						; 128 pages in one line (64 bytes)
	TAX
	TYA
	STA $7F00, X			; use lines 124-125
	RTS
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
