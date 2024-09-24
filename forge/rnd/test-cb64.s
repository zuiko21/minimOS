; PRNG test for Durango-X
; (c) 2024 Carlos J. Santisteban
; last modified 20240924-1828

; legacy nanoBoot @ $1000
; use -x 0x1000

; *** memory allocation ***
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
	STX px_col				; valid colour in HIRES
	LDA #%10110000			; HIRES mode, screen 3 as usual
	STA $DF80
	LDY #<reset
	LDX #>reset				; start address...
	STY $0202
	STX $0203				; ...as a cold reset via NMI
; clear the screen
start:
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
; wait for any key on column 1 (e.g. space, enter) and set seed
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
	BRA start				; and again

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
	RTS
lo_z:
	LDA seed+1
		BEQ do_eor2
	ASL
	BEQ no_eor
	BCS do_eor
no_eor:
	STA seed+1
	RTS

; *** PLOT library ***
#include "../../OS/firmware/modules/durango-plot.s"
