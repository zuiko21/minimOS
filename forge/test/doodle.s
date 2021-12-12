; Durango IO9 jpypad Doodle!
; (c) 2021 Carlos J. Santisteban
; last modified 20211212-1553

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
bg		= 8					; background colour (both nibbles)
fg		= 9					; foreground colour (both nibbles)
pen		= 10				; pen state (0=down, 1=up)
tmp		= 11
old_x	= 12				; *** do I need these?
old_y	= 13

; 011yyyyy yyxxxxxx x		address from coordinates (note separate flag)
; 01110000 00100000 0		initial values for the middle of the screen

	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango-X stuff
	LDA #%00111000			; colour, non-inverse, screen 3, non grey
	STA $DF80
; *** choose background colour ***
	LDA #0					; black by default
;	STA old_x				; ** unrelated init ** these are zero as we want the first pixel drawn in any case
;	STA old_y
	STA pen					; pen down by default, LED is on
	STA $DFA0				; interrupt control used as pen state indicator
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
	BRA choose_bg			; and update background
bg_set:
	STA bg					; this is the background colour (both nibbles)
	CLC
	ADC #$11				; and the following one in palette for ink
	STA fg
; *** doodle mode ***
; init position
	LDA #64
	STA xc
	STA yc
; place initial dot
	JSR draw				; always according to fg
; *** main loop ***
loop:
			JSR vsync
; will arrive here every 50th of a second
			LDA $DF9F		; full port value for directions
			CMP dir			; same as before?
			BEQ loop		; if so, wait for a different one
		STA dir				; otherwise, register it
		TAY					; not sure about N flag after CMP
		BPL not_fire		; FIRE = switch colours
			LDA fg			; original value
			CLC
			ADC #$11		; next in palette
			STA fg
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
			JSR draw
done:
		JMP loop

; *** *** routines *** *** not so simple but worth it
; *** clear dot (or not if pen is down) ***
clear:
	LDA pen
	LSR						; check d0, if pen is down, do not clear
	BCC cl_end
		LDA bg				; otherwise we need to set actual dot as background
		JSR addr			; (C is left/right pixel)
		BCC cl_left
			AND #$F			; C set, clear right pixel
			STA tmp			; temporary use!
			LDA (sptr)		; older contents
			AND #$F0		; keep other nibble
			BCS cl_ok
cl_left:
			AND #$F0		; C clear, clear left pixel
			STA tmp			; temporary use!
			LDA (sptr)		; older contents
			AND #$F			; keep other nibble
cl_ok:
		ORA tmp				; combine new byte
		STA (sptr)
cl_end:
	RTS

; *** draw pixel in current coordinates ***
draw:
;	LDX xc
;	LDY xy
;	CPX old_x
;		BNE do_draw			; address changed, do draw
;	CPY old_y
;		BEQ same			; same address, do nothing
do_draw:
;	STX old_x				; update these
;	STY old_y
	JSR addr				; X.0 is in C!
	LDA fg					; always gets colour here
	BCC dr_left
		AND #$F				; C set, draw right pixel
		STA tmp				; temporary use!
		LDA (sptr)			; older contents
		AND #$F0			; keep other nibble
		BCS dl_ok
dr_left:
		AND #$F0			; C clear, draw left pixel
		STA tmp				; temporary use!
		LDA (sptr)			; older contents
		AND #$F				; keep other nibble
dr_ok:
	ORA tmp					; combine new byte
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

; wait for vertical blanking
vsync:
		BIT $DF88			; video blanking register, d7=H, d6=V
		BVS vsync			; in case we are still blanking
wait:
		BIT $DF88			; video blanking register, d7=H, d6=V
		BVC wait			; will operate during blanking
	RTS
