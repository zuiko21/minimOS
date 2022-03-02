; 16-bit divide-by-10
; based on Alexandre Dumont's idea
; (c) 2022 Carlos J. Santisteban

; *** not necessarily in zeropage, but convenient for performance ***
; INPUT
;	num.W (will be destroyed)
; TEMPORARY
;	tmp.W
;	frac.W
; OUTPUT
;	div.W

	STZ tmp					; clear temporary values (3+3+3+3)
	STZ tmp+1
	STZ frac
	STZ frac+1
	STZ div					; also clear result (3+3)
	STZ div+1
	INC num					; offset is needed! (5)
	BCC of_nw				; check for wrap (usually 3)
		INC num+1
of_nw:
	LDY #4					; number of sums (2)
sum_loop:
; shift 4 bits num|tmp
		LDX #4				; number of bits per shift (2*4)
sh_loop:
			LSR num+1		; (5*4*4)
			ROR num			; (5*4*4)
			ROR tmp+1		; shifts into temporary value! (5*4*4)
			ROR tmp			; (5*4*4)
			DEX				; (2*4*4)
			BNE sh_loop		; ((3*4-1)*4)
; add this shifted value
; *** consider using a loop with consecutive bytes
		CLC					; (2*4)
		LDA frac			; (3*4)
		ADC tmp				; (3*4)
		STA frac			; (3*4)
		LDA frac+1			; (3*4)
		ADC tmp+1			; (3*4)
		STA tmp+1			; (3*4)
		LDA div				; (3*4)
		ADC num				; (3*4)
		STA div				; (3*4)
		LDA div+1			; (3*4)
		ADC num+1			; (3*4)
		STA div+1			; (3*4)
; next value
		DEY					; (2*4)
		BNE sum_loop		; (3*4-1)
; shifted sums are done, now make it one-and-a-half
; *** consider using a loop with consecutive bytes
	LDA div+1				; (3)
	LSR						; (2)
	STA num+1				; store half of it (3)
	LDA div					; (2)
	ROR						; this injects previous carry (2)
	STA num					; (3+3+2)
	LDA frac+1
	ROR
	STA tmp+1				; (3+3+2)
	LDA frac
	ROR
;	STA tmp					; this is the LSB for final addition, already in A
;	LDA tmp
	CLC						; (2)
	ADC frac				; (3+3+3)
	STA frac
	LDA tmp+1
	ADC frac+1				; (3+3+3)
	STA frac+1
	LDA num
	ADC div					; (3+3+3)
	STA div
	LDA num+1
	ADC div+1				; (3+3+3+3)
	STA div+1
; div.w has the result now!
