; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180124-0855

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
;		INPUT
; irq_hz	= PERIOD in uS (0 means READ current)
;		OUTPUT
; irq_hz	= actually set period (in case of error or no change)
; C			= could not set
; takes several local vars...

-jiffy:
.(
; if could not change, then just set return parameter and C
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** 8-bit indexes ** (3)
	LDA irq_hz			; get input value
	BNE fj_set			; not just checking
		LDA irq_freq		; get current frequency
		STA irq_hz			; set return values
		_NO_CRIT			; eeeeeeeeek
		_DR_OK
fj_set:
; *** compute and set VIA counters accordingly!!!!! ***
;	LDA #IRQ_PER*PHI2/1000000-2	; compute value***placeholder
; multiply irq_hz (already in C) by SPD_CODE/4096
	STA local1			; this copy will shift left...
	STZ local1+2		; ...thus clear MSBs
	LDA #SPD_CODE		; hardware speed (might take from FW var)
	STA local2			; this shifts right until clear
	STZ local3			; clear 32-bit result
	STZ local3+2
fj_mul:
		LSR local2			; get 2nd factor lsb
		BCC fj_next			; if was 0, do not add
			CLC
			LDA local1			; otherwise take 1st factor...
			ADC local3			; ...and add to result (C was clear!)
			STA local3			; update!
			LDA local1+2		; same for MSW
			ADC local3+2
			STA local3+2
fj_next:
;			BCS fw_over			; if C is set... error! is it possible?
		ASL local1			; shift 1st factor left
		ROL local1+2
		LDA local2			; check next factor...
		BNE fj_mul			; ...until no more bits
; now local3 holds the full result, must be shifted right 12 bits
; just discard the LSB, shift 4 bits and simply keep the middle two!
	LDX #4				; bits to shift
fj_shft:
		LSR local3+2		; shift amount RIGHT eeeeek
		ROR local3
		DEX					; until done
		BNE fj_shft
; should subtract 2 for proper VIA T1 value, but only 1 if C!
	LDA local3+1		; note offset
; do not preset carry...
	SBC #1				; ...minus 2 if C was clear
; MSB must be zero, otherwise overflow!
	LDY local3+3		; is MSB zero?
	BNE fj_over			; no, outside range
; accumulator has the proper 16-bit value for VIA T1
		STA VIA_J+T1CL		; start running!
; all succeeded, just take note of asked value and exit
		LDA irq_hz			; get asked value
		STA irq_freq		; set current frequency
		_NO_CRIT			; eeeeeeeeek
		_DR_OK
; otherwise, there was an error
fj_over:
	_NO_CRIT			; eeeeeeeek
	_DR_ERR(INVALID)
.)
	.as: .xs			; just in case...
