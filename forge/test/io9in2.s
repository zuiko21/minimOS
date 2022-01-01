; Durango IO9 test (input)
; revised version for 'joystick'
; optimised version
; (c) 2021-2022 Carlos J. Santisteban

*		= $400				; standard download

; uncomment for a nice blue background instead of black
;#define	BLUE	_BLUE

; uncomment for leaving a trace in black (BLUE must be allowed)
;#define	TRACE	_TRACE

; zp variables
sptr	= 2					; 16-bit screen pointer
xc		= 4					; X coordinate
yc		= 5					; Y-coordinate
old_x	= 5
old_y	= 6
dir		= 7					; sampled address

; 011yyyyy yyxxxxxx x		address from coordinates (note separate flag)
; 01110000 00100000 0		initial values for the middle of the screen

	CLD
	LDA #%00111000			; colour, non-inverse, screen 3, non grey
	STA $DF80
; clear screen!
	LDA #$60
	LDY #0					; screen 3 base and reset index
	STY sptr
	STA sptr+1
#ifdef	BLUE
	LDA #$88				; all blue
#else
	TYA						; all black
#endif
cls:
			STA (sptr), Y
			INY
			BNE cls
		INC sptr+1
		BPL cls
; init position
	LDA #64
	STA xc
	STA yc
	STY old_x				; these are zero as we want the first pixel drawn in any case
	STY old_y
; place initial dot
	LDX #$F					; white colour, note new parameter
	JSR draw
; *** main loop ***
loop:
; wait for vertical blanking
			BIT $DF88		; video blanking register, d7=H, d6=V
			BVS loop		; in case we keep blanking
wait:
			BIT $DF88		; video blanking register, d7=H, d6=V
			BVC wait		; will operate during blanking
; will arrive here every 50th of a second
		LDA $DF9F			; full port value for directions
		STA dir				; N is already d7
		BPL not_fire		; FIRE = draw RED dot
			LDX #2			; red
			JSR draw
not_fire:
		BIT dir				; get fire & START from standard joystick port
		BVC not_st			; START = draw GREEN dot
			LDX #5			; green
			JSR draw
not_st:
		LSR dir				; C = RIGHT
		BCC not_r
			JSR clear
			LDA xc
			INC				; CMOS!
			AND #127		; wrap properly
			STA xc			; ...and we're done!
not_r:
		LSR dir				; C = DOWN
		BCC not_d
			JSR clear
			LDA yc
			INC				; CMOS!
			AND #127		; wrap properly
			STA yc			; ...and we're done!
not_d:
		LSR dir				; C = LEFT
		BCC not_l
			JSR clear
			LDA xc
			DEC				; CMOS!
			AND #127		; wrap properly
			STA xc			; ...and we're done!
not_l:
		LSR dir				; C = UP, no more to be saved
		BCC not_u			; no move selected
			JSR clear
			LDA yc
			DEC				; CMOS!
			AND #127		; wrap properly
			STA yc			; ...and we're done!
not_u:
		LDA dir				; fire or start were pressed?
		BNE done			; keep new colour, then
			LDX #$F			; otherwise draw white dot
			JSR draw
done:
		JMP loop

; *** routines *** not so simple but worth it
clear:
	JSR addr
#ifdef	BLUE
#ifndef	TRACE
	LDA #$88				; all blue, don't care about left/right
#else
	LDA (sptr)
	BCC cl_tr
		ORA #$08			; put blue in right pixel, is this OK?
		BCS cl_ok
cl_tr:
		ORA #$80			; put blue in left pixel, is this OK?
cl_ok:
#endif
#else
	LDA #0					; black otherwise
#endif
	STA (sptr)
	RTS

draw:
	LDA xc
	LDY xy
	CPX #$F					; white?
		BNE do_draw			; if not, draw even if in the same place
	CPA old_x
		BNE do_draw			; address changed, do draw
	CPY old_y
		BEQ same			; same address, do nothing
do_draw:
	STA old_x				; update these
	STY old_y
	JSR addr				; X.0 is in C!
	TXA
#ifdef	BLUE
#ifndef	TRACE
	ORA #$80				; blue background in left pixel 
#endif
#endif
	BCS nib_ok				; odd flag is right pixel, already OK
		ASL					; otherwise is left pixel, shift pattern 
		ASL
		ASL
		ASL
#ifdef	BLUE
#ifndef	TRACE
		ORA #$08			; blue background in right pixel
#endif
#endif
nib_ok:
	STA (sptr)
same:
	RTS

; *** compute address ***
addr:
	LDA xc
	ASL						; times two as will shift in two Y bits (and one X out!)
	STA sptr
	LDA yc					; this will do more ops, thus worth keeping in A
	LSR
	ROR sptr				; 00yyyyyy yxxxxxxx -
	LSR
	ROR sptr				; 000yyyyy yyxxxxxx x, now C is X.0
	ORA #%01100000			; set into screen 3 space!
	STA sptr+1				; pointer ready, keep C if rightmost pixel of the byte
	RTS
