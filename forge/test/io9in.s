; Durango IO9 test (input)
; revised version for 'joystick'
; (c) 2021-2022 Carlos J. Santisteban

*		= $400				; standard download

; zp variables
xflag	= 2					; only d0 for left/right pixel
sptr	= 3					; 16-bit screen pointer
old_f	= 5					; old flag
old_p	= 6					; old pointer for updates
dir		= 7					; sampled address

; 011yyyyy yyxxxxxx f		coordinate format (note flag)
; 01110000 00100000 0		initial values for the middle of the screen

	CLD
	LDA #%00111000			; colour, non-inverse, screen 3, non grey
	STA $DF80
; clear screen!
	LDA #$60
	LDY #0					; screen 3 base and reset index
	STY sptr
	STA sptr+1
	TYA						; all black
lda#$88;blue
cls:
			STA (sptr), Y
			INY
			BNE cls
		INC sptr+1
		BPL cls
; init position
	STZ xflag				; left pixel
	LDA #$70
	LDY #$20
	STA sptr+1
	STY sptr
; place initial dot
	LDA #$F0				; left pixel as flag is 0
	STA (sptr)
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
			LDY #2			; red
			JSR draw
not_fire:
		BIT dir				; get fire & START from standard joystick port
		BVC not_st			; START = draw GREEN dot
			LDY #5			; green
			JSR draw
not_st:
		LSR dir				; C = RIGHT
		BCC not_r
			JSR clear
			INC xflag		; LSb
			LDA xflag
			LSR				; check d0
			BCS not_r		; 0->1 means same byte
				INC sptr	; +1, but may get into Y
				LDA sptr
				AND #%00111111		; if X = 0, wrap appropriately
			BNE not_r
				LDA sptr
				SEC
				SBC #$40	; Y -= 1
				STA sptr
not_r:
		LSR dir				; C = DOWN
		BCC not_d
			JSR clear
			LDA sptr
			ADC #$3F		; not $40 as C is set!
			STA sptr
			LDA sptr+1
			ADC #0
			AND #%01111111	; make sure it does not wrap!
			ORA #%01100000	; %011xxxxx
			STA sptr+1		; will draw later
not_d:
		LSR dir				; C = LEFT
		BCC not_l
			JSR clear
			DEC xflag		; LSb
			LDA xflag
			LSR				; check d0
			BCC not_l		; 1->0 means same byte
				DEC sptr	; +1, but may get into Y
				LDA sptr
				AND #%00111111		; if X is all ones, wrap appropriately
				CMP #%00111111
			BNE not_l
				LDA sptr
				CLC
				ADC #$40	; Y += 1
				STA sptr
not_l:
		LSR dir				; C = UP, no more to be saved
		BCC not_u			; no move selected
			JSR clear
			LDA sptr
			SBC #$40		; perfect value as C is set!
			STA sptr
			LDA sptr+1
			SBC #0
			ORA #%01100000	; make sure it does not wrap! no need for AND?
			STA sptr+1		; will draw later
not_u:
		LDA dir				; fire or start were pressed?
		BNE done			; keep new colour, then
			LDY #$F			; otherwise draw white dot
			JSR draw
done:
		JMP loop

; *** routines ***
clear:
	LDA #0
lda#$88;blue
	STA (sptr)
	RTS

draw:
	LDA xflag				; needed for drawing!
	LDX sptr
	CPY #$F					; white?
	BNE do_draw				; if not, draw even if in the same place
		CPX old_p
	BNE do_draw				; address changed, do draw
		CMP old_f
	BEQ same				; same address, do nothing
do_draw:
		STX old_p			; update these
		STA old_f
		LSR					; xflag.do is in C!
		TYA
ORA #$80			; blue background
		BCS nib_ok			; odd flag is right pixel, already OK
			ASL				; otherwise is left pixel, shift pattern 
			ASL
			ASL
			ASL
ORA #$8				; blue background
nib_ok:
		STA (sptr)
same:
	RTS
