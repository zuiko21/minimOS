; testing 65C816 board for Durango-X
; (c) 2023 Carlos J. Santisteban

#echo fix 16-bit pointers

; *** common ***
ptr		= 0
src		= ptr+3				; note extra padding
dest	= src+3

; *** *** ROM contents *** ***
	* = $8000
; Durango-X ROM image header
demo_start:
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; image header for Durango-X devCart SD
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"65C816 demo!", 0
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
	.bin	0, 0, "../../other/data/elvira.sv"
b6502:
	.byt	$66, $60, $66, $60, $66, $60, $66, $60	; brick red (as in "not supported") 6502
	.byt	$60, $00, $60, $00, $60, $60, $00, $60
	.byt	$66, $60, $66, $60, $60, $60, $66, $60
	.byt	$60, $60, $00, $60, $60, $60, $60, $00
	.byt	$66, $60, $66, $60, $66, $60, $66, $60

b65816:
	.byt	$BB, $B0, $BB, $0B, $BB, $0B, $0B, $BB	; pink 65816 @ +120
	.byt	$B0, $00, $B0, $0B, $0B, $0B, $0B, $00
	.byt	$BB, $B0, $BB, $0B, $BB, $0B, $0B, $BB
	.byt	$B0, $B0, $0B, $0B, $0B, $0B, $0B, $0B
	.byt	$BB, $B0, $BB, $0B, $BB, $0B, $0B, $BB

	.dsb	$FE00-*, $FF	; padding

; *** *** ROM code *** ***

; usual init
reset:
	SEI
	CLD
	LDX #$FF
	TXS
; Durango stuff
	STX $DFA0				; turn LED off
	LDA #$38
	STA $DF80				; colour mode

; *** main loop ***
; 6502 code
t6502:
	LDX #$60				; screen address
	LDY #$0
	TYA						; will clear screen
	STY ptr
clr_p:
		STX ptr+1			; select page
clr_l:
			STA (ptr), Y	; clear byte
			INY
			BNE clr_l
		INX
		BPL clr_p
; draw 6502 banner (TBD)
	LDX #7					; max. offset
loop_02:
		LDA b6502, X
		STA $6F1C, X
		LDA b6502+8, X
		STA $6F5C, X
		LDA b6502+16, X
		STA $6F9C, X
		LDA b6502+24, X
		STA $6FDC, X
		LDA b6502+32, X
		STA $701C, X
		DEX
		BPL loop_02
	JSR delay
; scroll up picture
	LDX #$7F				; last page on screen
	STX dest				; temporary use
up02:
		LDA #>picture		; set origin pointer
		LDY #<picture		; MUST be zero!
		STA src+1
		STY src
		STY ptr
page02:
			STX ptr+1		; current destination pointer
loop02:
				LDA (src), Y
				STA (ptr), Y			; copy byte into selected location
				INY
				BNE loop02
			INC src+1		; next page
			INX
			BPL page02		; ouside screen?
		DEC dest			; will start one page upwards
		LDX dest
		CPX #$60			; already over screen top?
		BCS up02			; if not, redraw
; side scroll
	LDA #64					; set counter
	STA dest
sh02:
		LDX #$60
		LDY #1
		STY src				; source is one byte ahead
		DEY
		STY ptr
sp02:
			STX src+1
			STX ptr+1
sr02:
			LDY #0			; eeek
sl02:
				LDA (src), Y
				STA (ptr), Y
				INY			; fill raster
				CPY #63
				BNE sl02
			LDA src
			CLC
			ADC #64			; next raster
			STA src
			DEC				; destination is one byte before
			STA ptr
			BNE sr02		; still within same page?
				INX
			BPL sp02		; otherwise advance until end of screen
		DEC dest			; next iteration
		BNE sh02

; 65816 code
t65816:
	CLC
	XCE						; make sure it's in NATIVE mode!
	REP #$30
	.al:.xl					; all 16-bit
	STZ $6000				; crear first two bytes as pattern
	LDX #$6000				; screen address
	LDY #$6002
	LDA #8191				; will move two less bytes of screen size
	MVN 0, 0				; clear the screen FAST!

	SEP #$10				; back to 8-bit index
	.xs

; draw 65816 banner (TBD)
	LDX #6					; max. offset (16-bit mode)
loop_816:
		LDA b65816, X
		STA $6F1C, X
		LDA b65816+8, X
		STA $6F5C, X
		LDA b65816+16, X
		STA $6F9C, X
		LDA b65816+24, X
		STA $6FDC, X
		LDA b65816+32, X
		STA $701C, X
		DEX
		DEX
		BPL loop_816
	SEP #$20				; 8-bit memory for a while
	JSR delay
	REP #$20				; back to 16-bit... but for indices too!
;	.xl
; scroll up picture *** now using MVN




	LDX #$7F				; last page on screen
	STX dest				; temporary use
up816:
		LDA #picture		; set 16-bit origin pointer
		STA src
		LDY #0
		STY ptr
page816:
			STX ptr+1		; current destination pointer
loop816:
				LDA (src), Y
				STA (ptr), Y			; copy byte into selected location
				INY
				INY
				BNE loop816
			INC src+1		; next page
			INX
			BPL page816		; ouside screen?
		DEC dest			; will start one page upwards
		LDX dest
		CPX #$60			; already over screen top?
		BCS up816			; if not, redraw
; side scroll *** using MVN

	REP #$30				; back to 16-bit... but for indices too!
	.xl



	LDA #64					; set counter (16-bit to avoid mode change)
	STA dest
sh816:
		LDX #$6001			; source is one byte ahead
		LDY #$6000
sp816:
			LDA #62			; will move 63 bytes
			MVN 0, 0		; *** not sure about xa syntax...
			INX
			INY				; advance to next raster, as easy as this!
			BPL sp816		; otherwise advance until end of screen
		DEC dest			; next iteration
		BNE sh816
; go back to 6502 demo
	SEC
	XCE						; make sure it's in emulation mode!
	.as
	JMP t6502

; *** delay routine ***
delay:
	LDA #10
d_loop:
				INX
				BNE d_loop
			INY
			BNE d_loop
		DEC
		BNE d_loop
	RTS

; *** void interrupt handler ***
dummy:
	RTI

; ***************
; *** ROM end ***
	.dsb	$FFE1-*, $FF	; usual padding

	JMP ($FFFC)				; devCart support

; 65816 vectors @ $FFE4
	.word	dummy			; COP-16
	.word	dummy			; BRK-16
	.word	dummy			; ABORT-16
	.word	dummy			; NMI-16
	.word	$FFFF			; reserved
	.word	dummy			; IRQ-16
	.word	$FFFF			; reserved
	.word	$FFFF			; reserved
	.word	dummy			; COP-8
	.word	$FFFF			; reserved
	.word	dummy			; ABORT-8

; 6502 vectors
;	.dsb	$FFFA-*, $FF

	.word	dummy			; NMI
	.word	reset			; RST
	.word	dummy			; IRQ/BRK
