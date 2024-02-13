; scroller for Durango-X
; (C) 2024 Carlos J. Santisteban
; last modified 20240213-1315

; uncomment for bankswitching version! (32 KB banks)
;#define	BANKSWITCH

* = $8000

; *** place standard header here ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Scroller (Gloria Fuertes)"		; C-string with filename @ [8], max 220 chars
; note terminator below
#ifdef	BANKSWITCH
	.asc	" for 32K bankswitching cartridge, bank ", '0'+bank
#endif
; optional C-string with comment after filename, filename+comment up to 220 chars
	.asc	0, 0

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1001			; 1.0a1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$6BC0			; time, 13.30		%0110 1-011 110-0 0000
	.word	$584D			; date, 2024/2/13	%0101 100-0 010-0 1101
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *** include image files (128x120, 30 pages in order to skip I/O and standard header) ***

; *** Durango·X hardware definitions ***
	IO8attr	= $DF80
 	IOAien	= $DFA0
	IOBank	= $DFFC			; for bankswitching only

; *** memory usage ***
	src		= $FA
	ptr		= $FC
	tmp		= $FE
	fw_irq	= $0200
	fw_nmi	= $0202
	ticks	= $0206

; *****************
; *** init code ***
; *****************
	.dsb	$FE80-*, $FF		; last ONE-AND-A-HALF pages for code
; may actually install some code between images
reset:
	SEI							; standard 6502 init
	CLD
	LDX #$FF
	TXS
; *** Durango specifics ***
	STX IOAien					; turn error LED off (assume X = odd value)
	LDA #$38					; standard screen 3, colour mode, RGB
	STA IO8attr
; set interrupt vectors
	LDA #>isr
 	LDY #<isr
	STY fw_irq
	STA fw_irq+1				; standard $0200 vector
; this far, NMI just does warm reset
	LDA #>reset
	LDY #<reset					; actually $FE80
	STY fw_nmi
	STA fw_nmi+1				; standard $0202 vector
; reset interrupt counter
	LDX #3						; max offset
t_res:
		STZ ticks, X			; clear byte
		DEX
		BPL t_res				; base-0
; clear screen for good measure
	LDX #$60					; initial page for screen 3
	LDY #0						; LSB
	TYA							; also black screen
r_pg:
		STX ptr+1				; set current page pointer
r_loop:
			STA (ptr), Y		; clear byte
			INY
			BNE r_loop
		INX						; next page
		BPL r_pg				; until end of screen memory
; *****************
; *** main code ***
; *****************

; ************************
; *** scroller library ***
; ************************
; *** note images MUST be stored at $x100-$yEFF, where y = x+1 ***

sc_left:
; shift existing screen one byte to the left
	LDX #$61					; first screen page
	LDY #0						; first byte offset
	STY ptr
sl_pg:
		STX ptr+1				; set page
sl_loop:
			INY					; pick byte to the right
			LDA (ptr), Y
			DEY					; write to byte to the left
			STA (ptr), Y
			INY
			BNE sl_loop
		INX						; next page
		CPX #$7F
		BNE sl_pg
; now add another column from next image at the rightmost byte column

	RTS

sc_right:
; shift existing screen one byte to the right
	LDX #$61					; first screen page
	LDY #0						; first byte offset (will pick last in page anyway)
	STY ptr
sr_pg:
		STX ptr+1				; set page
sr_loop:
			DEY					; pick byte to the left
			LDA (ptr), Y
			INY					; write to byte to the right
			STA (ptr), Y
			DEY
			BNE sr_loop
		CPX #$7F
		BNE sl_pg
; now add another column from next image at the leftmost byte column

	RTS

sc_up:
; shift existing screen two lines up
	LDX #$61					; first screen page
	LDY #0						; first byte offset
	STY ptr
	LDA #128					; half-page offset
	STA tmp						; for temporary source, two lines ahead
su_pg:
		STX ptr+1				; set page(s)
		STX tmp+1
su_loop:
			LDA (tmp), Y		; pick byte from two lines ahead
			STA (ptr), Y		; write back two lines up
			INY
			BNE su_loop
		CPX #$7F
		BNE sl_pg
; now add another row from next image at the bottom two lines
	LDY #$7F					; max offset
su_add:
		LDA (src), Y
		STA $7E80, Y
		DEY
		BPL su_add
	LDA src
	EOR #$80					; toggle D7 = add 128
	STA src
	BMI sc_up					; if negative, will do second half of the page next
		LDA src+1				; check 8K-alignment (with two guard pages!)
		INC src+1				; just in case, get ready to enter next page
		AND #%00111111			; remove image position in ROM
		CMP #%00111110			; displayed page is already the last one?
	BNE sc_up
	RTS

sc_down:
; first of all, correct base address as will be scanned backwards
	LDA src+1
	CLC
	ADC #$1D					; make it point to last page in image
	STA src+1
	LDA #128
	STA src						; actually starting at bottom half page
scd_rpt:
; shift existing screen two lines down
	LDX #$7E					; last screen page
	LDY #0						; first byte offset
	STY ptr
	LDA #128					; half-page offset
	STA tmp						; actually destination, two lines ahead
sd_pg:
		STX ptr+1				; set page(s)
		STX src+1
sd_loop:
			LDA (ptr), Y		; pick byte from two lines above
			STA (tmp), Y		; write back two lines down
			INY
			BNE sd_loop
		DEX						; next page
		CPX #$60				; beyond first picture page?
		BNE sd_pg
; must re-clear bottom two lines!
	LDX #$7F
sd_clear:
		STZ $7F00, X
		DEX
		BPL sd_clear
; now add another row from next image at the top two lines
	LDY #$7F					; max offset
sd_add:
		LDA (src), Y
		STA $6100, Y
		DEY
		BPL sd_add
	LDA src
	EOR #$80					; toggle D7 = subtract 128
	STA src
	BPL scd_rpt					; if POSITIVE, will do FIRST half of the page next time
		LDA src+1				; check 8K-alignment (with two guard pages!)
		DEC src+1				; just in case, get ready to enter next page
		AND #%00111111			; remove image position in ROM
		CMP #%00000001			; displayed page is already the first one?
	BNE scd_rpt
	RTS

; **************************
; *** interrupt handlers ***
; **************************
irq:
	JMP (fw_irq)				; standard $0200 vector
nmi:
	JMP (fw_nmi)				; standard $0202 vector
; *** interrupt service routines ***
; so far, just count interrupt for timing purposes
isr:
	INC ticks					; standard interrupt counter at $0206-$209
	BNE i_exit
 		INC ticks+1
	BNE i_exit
		INC ticks+2
	BNE i_exit
		INC ticks+3
i_exit:
	RTI

; ******************
; *** end of ROM ***
; ******************
	.dsb	$FFD6-*, $FF
	.asc	"DmOS"				; standard signature

	.dsb	$FFDE-*, $FF
switch:
	STA IOBank					; bankswitching support
	JMP ($FFFC)					; shadow-RAM support

; standard ROM end
	.dsb	$FFFA-*, $FF
	.word	nmi					; 6502 hard vectors
	.word	reset
	.word	irq
; ***************************************************
; *** *** may continue here for bankswitching *** ***
; ***************************************************
