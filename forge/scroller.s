; scroller for Durango-X
; (C) 2024 Carlos J. Santisteban
; last modified 20240212-1307

; uncomment for bankswitching version! (128 KB)
;#define	BANKSWITCH

* = $8000

; *** place standard header here ***

; *** include image files (31 pages in order to skip I/O) ***

; *****************
; *** init code ***
; *****************
	.dsb	$FF00-*, $FF		; last page for code
reset:
	SEI							; standard 6502 init
	CLD
	LDX #$FF
	TXS
; Durango specifics
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
	LDY #<reset					; actually $FF00
	STY fw_nmi
	STA fw_nmi+1				; standard $0202 vector
; reset interrupt counter
	LDX #3						; max offset
	LDA #0						; could use TYA as well
t_res:
		STA ticks, X			; clear byte
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
sc_left:

; shift existing screen one byte to the left
	LDX #$60					; first screen page
	LDY #0						; first byte offset
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
		BPL sl_pg
; now add another column from next image at the rightmost byte column

sc_right:

; shift existing screen one byte to the right
	LDX #$60					; first screen page
	LDY #$FF					; last byte offset
sl_pg:
		STX ptr+1				; set page
sl_loop:
			;????????????????????????????????
			LDA (ptr), Y
			DEY					; write to byte to the right
			STA (ptr), Y
			DEY
			BNE sl_loop
		INX						; next page
		BPL sl_pg
; now add another column from next image at the rightmost byte column

sc_up:


sc_down:

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
; *** end of ROM *** (for non-bankswitching)
; ******************
	.dsb	$FFD6-*, $FF
	.asc	"DmOS"				; standard signature

	.dsb	$FFE1-*, $FF
	JMP ($FFFC)					; shadow-RAM support

	.dsb	$FFFA-*, $FF
	.word	nmi					; 6502 hard vectors
	.word	reset
	.word	irq
; ***************************************************
; *** *** may continue here for bankswitching *** ***
; ***************************************************
