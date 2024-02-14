; scroller for Durango-X
; (C) 2024 Carlos J. Santisteban
; last modified 20240214-0716

; number of ~seconds (250/256) between images
#define	DELAY	3

; uncomment for bankswitching version! (32 KB banks)
;#define	BANKSWITCH
	bank	= 0

; *** Durango·X hardware definitions ***
	IO8attr	= $DF80			; video mode register
 	IOAien	= $DFA0			; interrupt enable register
	IOBank	= $DFFC			; for bankswitching only

; *** memory usage ***
	bnk		= $F7			; stored bank (even number)
	index	= $F8			; image index 0...3
	cnt		= $F9			; scroll cycle counter
	src		= $FA			; pointer to image to be displayed ($81/$A1/$C1/$E1 only!)
	ptr		= $FC			; screen pointer (local)
	tmp		= $FE			; temporary usage (local for vertical scroll)
	fw_irq	= $0200			; standard firmware vectors and counters
	fw_nmi	= $0202
	ticks	= $0206

; **************************
; *** standard bank code ***
; **************************
.(
*		= $8000

; *** standard header ***
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
	.word	$B800			; time, 23.00		%1011 1-000 000-0 0000
	.word	$584D			; date, 2024/2/13	%0101 100-0 010-0 1101
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; ********************************************************************************
; *** image files (128x120, 30 pages in order to skip I/O and standard header) *** interleaved with code
; ********************************************************************************
pic1:
	;.bin	512, 7680, "images/image1.dsv"	; note new image format with header! 128x120 4bpp (or 256x240 1bpp)
.bin	0,7680,"../other/data/col_start.sv"

code1:
; ************************
; *** scroller library ***
; ************************

; *** scrolling routines ***
sc_left:
;	STZ src						; will pick LEFTmost byte in column
sl_do:
; * shift existing screen one byte to the left *
	LDX #$61					; first screen page
	LDY #0						; first byte offset
;	STY ptr
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
	LDA #63						; rightmost byte on screen
	STA ptr
	LDA #$61					; screen top page eeeek
	STA ptr+1
	LDY #0
fl_loop:
			LDA (src), Y
			STA (ptr), Y
			TYA
			CLC
			ADC #64				; next raster
			TAY
			BNE fl_loop
		INC src+1
		INC ptr+1
		LDA ptr+1
		CMP #$7F				; eeeek
		BNE fl_loop
	LDX index
	LDA pages, X
	STA src+1					; reset origin page, just vertically
	INC src						; eeeeeek
	DEC cnt						; 64 times!
	BNE sl_do
	RTS

sc_right:
	LDA #63						; will load leftmost byte in column
	STA src
sr_do:
; * shift existing screen one byte to the right *
	LDX #$7E					; LAST screen page
;	STZ ptr						; eeeek
sr_pg:
		LDY #$FF				; will pick last in page
		STX ptr+1				; set page
sr_loop:
			DEY					; pick byte to the left
			LDA (ptr), Y
			INY					; write to byte to the right
			STA (ptr), Y
			DEY
			BNE sr_loop
		DEX						; eeeeeek
		CPX #$60				; over screen top?
		BNE sr_pg
; now add another column from next image at the leftmost byte column
	LDA #$61					; screen top page eeeeek
	STA ptr+1
	LDY #0
	STY ptr
fr_loop:
			LDA (src), Y
			STA (ptr), Y
			TYA
			CLC
			ADC #64				; next raster
			TAY
			BNE fr_loop
		INC src+1
		INC ptr+1
		LDA ptr+1
		CMP #$7F				; eeeek
		BNE fr_loop
	LDX index
	LDA pages, X
	STA src+1					; reset origin page, just vertically
	DEC src						; next byte eeek
	DEC cnt						; 64 times!
	BNE sr_do
	RTS

sc_up:
;	STZ src						; will start at leftmost byte in row
su_do:
; * shift existing screen two lines up *
	LDX #$61					; first screen page
	LDY #0						; first byte offset
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
		BNE su_pg
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
	DEC cnt						; 64 times!
	BNE su_do
	RTS

sc_down:
; * first of all, correct base address as will be scanned backwards *
	LDA src+1
	CLC
	ADC #$1D					; make it point to last page in image
	STA src+1
	LDA #128
	STA src						; actually starting at bottom half page
sd_do:
; shift existing screen two lines down
	LDX #$7E					; last screen page
	LDY #0						; first byte offset
;	STY ptr
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
	BPL sd_do					; if POSITIVE, will do FIRST half of the page next time
		LDA src+1				; check 8K-alignment (with two guard pages!)
		DEC src+1				; just in case, get ready to enter next page
		AND #%00111111			; remove image position in ROM
		CMP #%00000001			; displayed page is already the first one?
	BNE sd_do
	INC src+1					; fix global counter eeek
	STZ src						; eeek?
	RTS
lib_end:

	.dsb	$A100-*, $FF
pic2:
	;.bin	512, 7680, "images/image2.dsv"	; note new image format with header! 128x120 4bpp (or 256x240 1bpp)
.bin	0,7680,"../other/data/elvira.sv"

code2:

	.dsb	$C100-*, $FF
pic3:
	;.bin	512, 7680, "images/image3.dsv"	; note new image format with header! 128x120 4bpp (or 256x240 1bpp)
.bin	0,7680,"../other/data/fafa.sv"

	.dsb	$E000-*, $FF					; this will skip I/O area at $DFxx

code3:
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

; *** scroll library entry point ***
scroll:
	STZ ptr
	STZ src						; worth it as commonly used
	TXA							; original value
	ASL							; make suitable index (times two)
	TAX							; use X as animation index (0=right, 1=down, 2=left, 3=up)
	LDA #64						; scroll cycle counter
	STA cnt
	JMP (scr_tab, X)			; jump to routine

scr_tab:						; *** pointer table ***
	.word	sc_right
.word	sc_left
;	.word	sc_down
	.word	sc_right
.word	sc_left
;	.word	sc_up

; *** data tables ***
pages:
	.byt	>pic1, >pic2, >pic3, >pic4	; initial pages (will be read backwards)
tab_end:
; *** continue with last picture ***

	.dsb	$E100-*, $FF
pic4:
.bin	0,7680,"../other/data/jaqueria.sv";EEEEEK
	;.bin	512, 7680, "images/image4.dsv"	; note new image format with header! 128x120 4bpp (or 256x240 1bpp)
endish:

; *****************
; *** init code ***
; *****************
;	.dsb	$FF00-*, $FF		; last page for code
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
	STX index
t_res:
		STZ ticks, X			; clear byte
		DEX
		BPL t_res				; base-0
	CLI							; eeeeeeeek
#ifndef	INITED
#define	INITED
	STZ bnk						; reset bank counter
; clear screen for good measure
	LDX #$60					; initial page for screen 3
	LDY #0						; LSB
	STY ptr						; eeeeeek
	TYA							; also black screen
r_pg:
		STX ptr+1				; set current page pointer
r_loop:
			STA (ptr), Y		; clear byte
			INY
			BNE r_loop
		INX						; next page
		BPL r_pg				; until end of screen memory
#endif
; *****************
; *** main code ***
; *****************
slide:
	LDX index
	JSR scroll					; display new image according to index (and scroll type by X)
; *** add delay between pictures ***
	LDA ticks+1					; check current second (250/256)
	ADC #DELAY					; compute next target
wait:
		CMP ticks+1				; wait until target
		BNE wait
	DEC index
	BPL slide					; next slide
#ifdef	BANKSWITCH
nxt_bnk:
	INC bnk
 	INC bnk						; 32K banks use even numbers
	LDA bnk
	JMP switch					; execute reset from new bank!
#endif
	LDA #3
	STA index					; if no more banks, reset index and begin again
	BRA slide
code_end:

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

	-bank	= bank + 1			; switch bank for generated code
.)
; ***************************************************
; *** *** may continue here for bankswitching *** ***
; ***************************************************
#ifdef	BANKSWITCH
#endif
