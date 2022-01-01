; Durango IO9 joypad Doodle!
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211213-1837

; *** usage ***
; choose background colour with FIRE, then select with START
; use START to toggle pen up (IRQ LED off) or pen down (IRQ LED on)
; FIRE cycles thru colours

*		= $400				; standard download

; zp variables
sptr	= 3					; 16-bit screen pointer
xc		= 5					; X coordinate
yc		= 6					; Y-coordinate
dir		= 7					; sampled address
bg		= 8					; background byte (no longer stores background colour)
fg		= 9					; foreground colour (both nibbles)
pen		= 10				; pen state (0=down, 1=up)
tmp		= 11

; 011yyyyy yyxxxxxx x		address from coordinates (note separate flag)
; 01110000 00100000 0		initial values for the middle of the screen

	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X stuff
	LDA #%00111000			; colour, non-inverse, screen 3, non grey
	STA $DF80
	STX $DFA0				; LED off, thus pen up for the moment
; *** choose background colour ***
	LDA #0					; black by default
choose_bg:
		LDX #$60
		LDY #0				; screen 3 base and reset index
		STY sptr
		STX sptr+1
cls:
				STA (sptr), Y
				INY
				BNE cls
			INC sptr+1
			BPL cls
; check keys, FIRE will try another colour, START will choose it
sel:
			JSR vsync
			LDX $DF9F		; get joypad input
			CPX dir			; same key as before?
			BEQ sel			; ignore it
		STX dir				; otherwise register it
		BIT dir				; and check relevant bits
		BVS bg_set			; START was pressed, end stuff
		BPL sel				; or if FIRE is pressed...
	CLC
	ADC #$11				; ...next colour!
	BCC bg_ok
		LDA #0				; just wrapped!
bg_ok:
	BRA choose_bg			; and update background
bg_set:
;	STA bg					; store background colour as default value under cursor
	CLC						; A is the background colour (both nibbles)
	ADC #$11				; get the following one in palette for ink
	BCC fg_ok
		LDA #0				; just wrapped!
fg_ok:
	STA fg
; *** doodle mode ***
; init position
	LDA #64
	STA xc
	STA yc
	STA pen					; pen down by default, LED is on
	STA $DFA0
; place initial dot
	JSR draw				; always according to fg
; *** main loop ***
loop:
		JSR vsync
; will arrive here every 50th of a second
		LDA $DF9F			; full port value for directions
		CMP #16				; is it a movement?
		BCC rpt				; movements may repeat, colour/pen cycle can't
			CMP dir			; if command, same as before?
			BEQ loop		; if so, wait for a different one;
rpt:
		STA dir				; otherwise, register it
		TAX					; not sure about N flag after CMP, also store in X
		BPL not_fire		; FIRE = switch colours
			LDA fg			; original value
			CLC
			ADC #$11		; next in palette
			BCC col_ok
				LDA #0		; just wrapped!
col_ok:
			STA fg
			JSR clear		; must keep previous value!
			JSR draw		; no need to draw previous one, as did not move
not_fire:
		BIT dir				; get fire & START from standard joystick port
		BVC not_st			; START = toggle pen up/down
			LDA pen
			INC				; this will simply toggle pen status, only d0 will be checked
			STA pen
			STA $DFA0		; update LED (could be AND #1/TAX/STA $A000, X for the older architecture)
not_st:
		LSR dir				; C = RIGHT
		BCC not_r
			JSR clear		; this will act differently whether pen is up or down
			LDA xc
			INC				; CMOS!
			AND #127		; wrap properly
			STA xc			; ...and we're done!
			JSR draw
not_r:
		LSR dir				; C = DOWN
		BCC not_d
			JSR clear
			LDA yc
			INC				; CMOS!
			AND #127		; wrap properly
			STA yc			; ...and we're done!
			JSR draw
not_d:
		LSR dir				; C = LEFT
		BCC not_l
			JSR clear
			LDA xc
			DEC				; CMOS!
			AND #127		; wrap properly
			STA xc			; ...and we're done!
			JSR draw
not_l:
		LSR dir				; C = UP, no more to be saved
		BCC not_u			; no move selected
			JSR clear
			LDA yc
			DEC				; CMOS!
			AND #127		; wrap properly
			STA yc			; ...and we're done!
			JSR draw
not_u:
		STX dir				; retrieve last key combo
		JMP loop

; *** *** routines *** *** not so simple but worth it
; *** clear dot (or not if pen is down) ***
clear:
	LDA pen
	LSR						; check d0, if pen is down, do not clear
	BCC cl_end
		JSR addr			; (C is left/right pixel)
		LDA bg				; we need to set actual dot as previous background
		STA (sptr)			; and we're done!
cl_end:
	RTS

; *** draw pixel in current coordinates ***
draw:
	JSR addr				; X.0 is in C!
	LDA (sptr)				; keep what's under the dot!
	STA bg
	LDA fg					; always gets ink colour here
	BCC dr_left
		AND #$F				; C set, draw right pixel
		STA tmp				; temporary use!
		LDA (sptr)			; older contents
		AND #$F0			; keep other nibble
		BCS dr_ok
dr_left:
		AND #$F0			; C clear, draw left pixel
		STA tmp				; temporary use!
		LDA (sptr)			; older contents
		AND #$F				; keep other nibble
dr_ok:
	ORA tmp					; combine new byte
	STA (sptr)
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

; wait for vertical blanking
vsync:
		BIT $DF88			; video blanking register, d7=H, d6=V
		BVS vsync			; in case we are still blanking
wait:
		BIT $DF88			; video blanking register, d7=H, d6=V
		BVC wait			; will operate during blanking
	RTS
