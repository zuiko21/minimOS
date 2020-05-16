; 65816 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020 Carlos J. Santisteban

; *** CAVEATS ***
; Array up to nearly 16M elements! (on bank boundary start)
; Execution limit is not fully accurate, stopping at 1,000,013,824 cars
; Array elements are bytes, containing either zero or any non-zero value
; 32-bit total and 24-bit partial counters

; *** memory use ***
.zero
ptr			.dsb	3, 0		; 24-bit pointer *** MUST be on zeropage ***
total		.dsb	4, 0		; 32-bit total counter
partial_h	.word	0			; partial counter is 24-bit, but needs to keep clear the fourth byte
array		.dsb	16000000	; *** MUST be on bank boundary start ***
size		=		16000000

; ************
; *** CODE ***
; ************
	REP #$10					; 16-bit indexes
	SEP #$20					; 8-bit memory & accumulator
	LDX #0						; reset partial, also for clearing words
	STX partial_h				; needs 32-bit clean, although uses only 24
	LDA #(array+size-1)>>16		; last BANK used by the array
	LDY #!(array+size-1)		; last low word used by the array
	STA ptr+2					; create LONG indirect pointer
	STX ptr
	STX total					; reset total counter
	STZ total+2
loop:
		LDA [ptr], Y			;(6)   get array data
		BEQ zero				;(2/3) if not zero...
			INX					;(2/0) ...increment partial
			BNE next			;(3/0) VERY rarely over 3 cycles
				INC partial_h	;(5*/0) don't care about fourth byte
			BRA next			;(3*/0) VERY rarely done
zero:
			REP #$21			;(0/3) else clear C and set 16-bit memory
			TXA					;(0/2) add partial...
			ADC total			;(0/4) ...to current total
			STA total			;(0/4)
			LDA total+2			;(0/4) ditto with high word...
			ADC partial_h		;(0/4) ...not just carry
			CMP #15259			;(0/3) are we at the limit?
				BEQ over		;(0/2) return -1 if so, executes at most ONCE
			STA total+2			;(0/4) total is updated
			SEP #$20			;(0/3) back to 8-bit memory & accumulator
next:
		DEY						;(2) next element
		CPY #$FFFF				;(3) are we switching bank?
		BNE loop				;(3) VERY rarely beyond this point
			DEC ptr+2			;(5*) point to previous bank
			LDA ptr+2			;(3*) could be waived if starting at bank 1
			CMP #array>>16		;(2*) could be waived if starting at bank 1
		BCS loop				;(3*) use BNE if waived
	BRA end
over:
		LDX #$FFFF				; -1 to be set in case of overflow
		STX total
		STX total+2
end:
; ************
; *) Very rarely (~0.00015%) executed
; 21 or 50 cycles per iteration, 76 bytes

