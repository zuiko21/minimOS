; power stress test for Durango-X
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211208-1705

; ****************************
; *** standard definitions ***
	IO8lh	= $DF80			; will become $DF80
	IO8blk	= $DF88			; new, balnking signales
	IOAen	= $DFA0			; will become $DFA0
	IOBeep	= $DFB0			; will become $DFB0
; ****************************

* = $400					; downloadable start address

	SEI						; standard 6502 stuff, don't care about stack
	CLD
; Durango-X specific stuff
	LDA #$39				; flag init, colour, screen 3, plus int on
	STA IO8lh				; set colour mode
	STA IOAen+1				; ...and interrupts

loop:
	EOR #%01000001			; toggle inverse mode AND buzzer
	STA IO8lh
	STA IOBeep
nop
wait:
;	BIT IO8blk				; check blanking
;	BPL wait
finish:
;	BIT IO8blk				; until it ends
;	BMI finish
	BRA loop				; forever

delay:
	RTS						; 12t delay
