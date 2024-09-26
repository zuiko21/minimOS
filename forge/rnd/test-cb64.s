; PRNG test for Durango-X
; (c) 2024 Carlos J. Santisteban
; last modified 20240926-1651

; legacy nanoBoot @ $1000
; use -x 0x1000
; NMI to switch into colour pixel test

; *** memory allocation ***
count	= $F6				; 16-bit pixel counter
coords	= $F8				; current XY
px_col	= $FA				; pixel colour (must have d7 set for HIRES)
ptr		= $FC				; generic pointer
seed	= $FE				; random seed

fw_nmi	= $0202				; standard address (won't use IRQ)
array	= $0300				; 256-byte array

; *** hardware definitions ***
screen3	= $6000				; screen 3
IO8attr	= $DF80
IO9kbd	= $DF9B
IOAie	= $DFA0

; *** *** CODE *** ***
	*	= $1000

reset:
; base init
	SEI
	CLD
	LDX #$FF
	TXS
	STX IO8attr				; turn error LED off
; * probability array display test *
start:
	LDA #%10110000			; HIRES mode, screen 3 as usual
	STA $DF80
	STA px_col				; valid colour in HIRES
	JSR cls					; clear the screen
; clear the array
	LDX #0
a_loop:
		STZ array, X
		INX
		BNE a_loop
; start statistics
loop:
		JSR rnd
		TAX					; use result as index (horizontal position)
		LDY array, X		; current count (going towards bottom)
		INC array, X		; count one more
	BEQ exit				; if wrapped, end test
		JSR dxplot			; display bar at coordinates
		BRA loop
exit:
	LDY #<pixel
	LDX #>pixel				; random pixel test address...
	STY $0202
	STX $0203				; ...to be switched in via NMI
; wait for any key on column 1 (e.g. space, enter) and set seed
	JSR press
	BRA start				; and again
; * random pixel display test *
pixel:
	LDA #%00111000			; colour mode, RGB, screen 3 as usual
	STA $DF80
	JSR cls
; start display
	STZ count
	STZ count+1				; reset counter
ploop:
		JSR rnd
		LSR					; eeeek
		STA coords			; set X
		JSR rnd
		LSR
		STA coords+1		; set Y
		JSR rnd
		AND #15
		STA px_col
		ASL
		ASL
		ASL
		ASL
		ORA px_col
		STA px_col			; set colour
		LDX coords
		LDY coords+1
		JSR dxplot			; draw random pixel
		INC count			; anther one...
	BNE ploop				; eeek
		INC count+1
		BNE ploop			; ...up to 64K
	LDY #<start
	LDX #>start				; probability array test address...
	STY $0202
	STX $0203				; ...to be switched back in via NMI
; wait for any key on column 1 (e.g. space, enter) and set seed
	JSR press
	BRA pixel				; and again

; *** support routines ***
; clear the screen
cls:
	LDY #<screen3
	LDX #>screen3			; screen 3 address
	TYA						; will clear the screen
	STZ ptr					; eeeeek
c_page:
		STX ptr+1
c_loop:
			STA (ptr), Y
			INY
			BNE c_loop
		INX
		BPL c_page
	RTS

; wait for column 1 key and set seed
press:
	LDA #1					; first keyboard column
	STA IO9kbd
wait:
			INX
			LDA IO9kbd		; any key pressed?
	BNE set					; if so, use current register values as seed
		INY
		BRA wait
set:
	STX seed
	STY seed+1
	RTS

; ** PRNG **
; based on code from https://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
; input
;	seed
; output
;	A	random value
; affects seed and A
rnd:
	LDA seed
		BEQ lo_z
	ASL seed
	LDA seed+1
	ROL
	BCC no_eor
do_eor:
		STA seed+1
do_eor2:
		LDA seed
		EOR #$2D
		STA seed
		ROR
	RTS
lo_z:
	LDA seed+1
		BEQ do_eor2
	ASL
	BEQ no_eor
	BCS do_eor
no_eor:
	STA seed+1
	ROR
	RTS

; *** PLOT library ***
#include "../../OS/firmware/modules/durango-plot.s"
