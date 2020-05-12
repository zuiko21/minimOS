; 6502 code for the Passing Cars exercise
; https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars
; (c) 2020 Carlos J. Santisteban

; *** CAVEATS ***
; Array up to about 64000 elements
; (needs some space for variables, stack, interrupt vectors, I/O routines and this code itself!)
; Execution limit is not accurate, stopping after counting 1,006,632,960 cars
; Array elements are bytes, containing either zero or any non-zero value
; 32-bit total and 16-bit partial counters

; *** memory use ***
.zero
ptr			.word	0		; indirect pointer *** MUST be on zeropage ***
total		.dsb	4, 0	; 32-bit total counter
partial_h	.byt	0		; MSB for 16-bit partial counter (rest in X)

array		.dsb	64000	; likely to clear stack, code, interrupt vectors...
size		=	64000

; ************
; *** CODE ***
; ************
	LDX #0					; reset LOW byte of partial counter (X)
	LDA #>(array+size-1)
	LDY #<(array+size-1)
	STA ptr+1				; make zeropage pointer to LAST array element
	STX ptr
	STX total				; reset 32-bit total counter
	STX total+1
	STX total+2
	STX total+3
	STX partial_h			; reset HIGH byte of partial counter (on zeropage as will change much less frequently)
loop:
		LDA (ptr), Y		; (5) get array element
		BEQ zero			; (2/3) if not zero... [timing shown for (then/else) sections]
			INX				; (2/0) ...increment partial counter
			BNE next		; (3-10/0) check for possible carry! extra cycles only 0.4% of the time
				INC partial_h
			BNE next
zero:
			TXA				; (0/2) ...else take partial counter...
			CLC				; (0/2)
			ADC total		; (0/3) ...and add it to current total
			STA total		; (0/3)
			LDA total+1		; (0/3) ditto for 2nd byte
			ADC partial_h	; (0/3) note partial MSB origin
			STA total+1		; (0/3)
			LDA total+2		; (0/3)
			ADC #0			; (0/2) partial is 16-bit, but carry may propagate
			STA total+2		; (0/3)
			LDA total+3		; (0/3)
			ADC #0			; (0/2) ditto for last byte, but...
			CMP #60			; (0/2) ...have we reached the limit?
				BEQ over	; (0/2) yes? no more iterations! if this jump executes, no more iterations
			STA total+3		; (0/3) no? just update value
next:
		DEY					; (2) go for next byte
		CPY #$FF			; (2) wraparound?
		BNE loop			; (3-15) if not, just iterate; extra cycles only ~0.4% of the time
			DEC ptr+1		; otherwise, modify pointer MSB...
			LDA ptr+1
			CMP #>array		; ...until we went below array start address
		BCS loop
	BCC end					; array is done, just exit
over:
		LDA #$FF			; in case of overflow, set total to -1
		STA total
		STA total+1
		STA total+2
		STA total+3
end:
; ************
; 84 bytes, 19 or 54 clock cycles per iteration
; assuming all variables in zeropage
