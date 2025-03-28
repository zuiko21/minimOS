; PRNG test for Durango-X
; (c) 2024 Carlos J. Santisteban
; last modified 20240927-0854

; set PRNG parameters via -DMUL=x, -DSUM=x

; legacy nanoBoot @ $1000
; use -x 0x1000 (-a 0x1000 on Perdita)
; NMI to switch into colour pixel test

#ifndef	MUL
#define	MUL	9377
#endif

#ifndef	SUM
#define	SUM 39119
#endif

; *** memory allocation ***
factor	= $F2				; for generic multiply
temp	= $F4				; temporary storage
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
	LDY #<pixel
	LDX #>pixel				; random pixel test address...
	STY $0202
	STX $0203				; ...to be switched in via NMI
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
	JSR press
	BRA start				; and again
; * random pixel display test *
pixel:
	LDA #%00111000			; colour mode, RGB, screen 3 as usual
	STA $DF80
	JSR cls
	LDY #<start
	LDX #>start				; probability array test address...
	STY $0202
	STX $0203				; ...to be switched back in via NMI
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
/*

; *** *** PRNG under test *** ***
rnd:
; ** LFSR ** DEPRECATED
; based on code from https://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
; input
;	seed
; output
;	A	random value
; affects seed and A
#ifdef	ITER
	LDY #ITER				; 2
rloop:
#endif
	LDA seed				; 3 if on zp
		BEQ lo_z			; 2, usually
	ASL seed				; 5
	LDA seed+1				; 3
	ROL						; 2
	BCC no_eor				; 3/2 (if d7=0 or 1)
do_eor:
		STA seed+1			; 0/3
do_eor2:
		LDA seed			; 0/3
		EOR #$2D			; 0/2
		STA seed			; 0/3
		ROR					; 0/2
#ifdef	ITER
		BRA chk				; 0/(3)
#else
		RTS
#endif
lo_z:
	LDA seed+1				; 3/0
		BEQ do_eor;2		; 2, mostly
	ASL						; 2/0
	BEQ no_eor				; 2, mostly
	BCS do_eor				; 2 or 3
no_eor:
	STA seed+1				; 3
	ROR						; 2
#ifdef	ITER
chk:
	DEY						; 2
	BNE rloop				; 3
#endif
	RTS
*/

/*
; ** linear PRNG ** (9377n+39119, takes 240t constant)
	LDA seed
	STA temp
	LDA seed+1
	STA temp+1				; copy seed into temp as factor has d0 set
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1				; shift five bits
	LDA seed
	CLC
	ADC temp
	STA temp
	LDA seed+1
	ADC temp+1
	STA temp+1				; add to temp
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1				; shift two bits
	LDA seed
	CLC
	ADC temp
	STA temp
	LDA seed+1
	ADC temp+1
	STA temp+1				; add to temp
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1				; shift three bits
	LDA seed
	CLC
	ADC temp
	STA temp
	LDA seed+1
	ADC temp+1
	STA temp+1				; add to temp
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1
	ASL seed
	ROL seed+1				; shift three bits
	LDA seed
	CLC
	ADC temp
	STA temp
	LDA seed+1
	ADC temp+1
	STA temp+1				; add to temp
	LDA temp
	CLC
	ADC #<39119
	STA seed
	LDA temp+1
	ADC #>39119
	STA seed+1				; add constant
;	LDA seed				; is this OK, or will be A valid?
	RTS
*/

; ** linear PRNG (generic version) **
; overhead = 33t + call - 1t for last iteration
; iteration without add = 28n t
; iteration with add = 47n t, let's make it 38t average
; for generic 16-bit factor that's 32+16*38 = 32+608 = 640t
; 9377 is a 14-bit number with only 5 additions, 32+235+252= 519t
	LDY #<MUL				; 2
	LDX #>MUL				; 2
 	STY factor				; 3
	STX factor+1			; 3
	STZ temp				; 3
	STZ temp+1				; 3
	LDY #16					; 2, used bits on factor, change as needed
lp_loop:
		LSR factor+1		; 5n
		ROR factor			; 5n, extract least significant bit
		BCC no_add			; 3n/2n, if enabled...
			LDA temp		; /3n
			CLC				; /2n
			ADC seed		; /3n
			STA temp		; /3n
			LDA temp+1		; /3n
			ADC seed+1		; /3n
			STA temp+1		; /3n ...add current shifted seed to temp
no_add:
		ASL seed			; 5n
		ROL seed+1			; 5n, in any case, shift seed to the left
		DEY					; 2n
		BNE lp_loop			; 3n, until no more bits on factor
	LDA temp				; 3, get multiply result...
	CLC						; 2
	ADC #<SUM				; 2 ...and add constant...
	STA seed				; 3 ...for the new seed
	LDA temp+1				; 3, same for MSB
	ADC #>SUM				; 2
	STA seed+1				; 3, this is already the return value!
	RTS

; ********************
; *** PLOT library ***
; ********************
#include "../../OS/firmware/modules/durango-plot.s"
