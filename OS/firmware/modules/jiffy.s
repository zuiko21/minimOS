; firmware module for minimOS·65
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180131-1005

; **************************
; JIFFY, set/check IRQ speed
; **************************
;		INPUT
; irq_hz	= desired period in uS (0 means no change)
;		OUTPUT
; irq_hz	= actually set period (if error or no change)
; C			= error, did not set

-jiffy:
.(
	_CRITIC		; this is serious
	LDA irq_hz	; check LSB
	ORA irq_hz+1	; any bit set?
	BNE fj_set	; will adjust new value
		LDY irq_freq	; otherwise get current
		LDA irq_freq+1
		STY irq_hz	; set output
		STA irq_hz+1
fj_end:
; if successful must set final variable from parameter
		LDY irq_hz	; get parameter
		LDA irq_hz+1
		STY irq_freq	; set value, will not harm
		STA irq_freq+1
		_NO_CRIT	; all safe now
		_DR_OK		; will work always on this machine!
fj_set:
; *** compute VIA T1 values from uS at parameter ***
; ** multiply 16x16=32 bits, A.Y x SPD_CODE **
; * will return 16b, result is shifted 12b right *
	STY local1		; set local copy of 1st factor
	STA local1+1
	_STZA local1+2		; clear excess as will shift left
	_STZA local1+3
; local copy of 2nd factor, not worth inverting
	LDA #<SPD_CODE		; original LSB...
	STA local2		; ...at definitive location
	LDA #>SPD_CODE		; original MSB...
	STA local2+1		; ...at definitive location
; clear result variable, a loop just saves one byte and this is 12t vs 39t
; NMOS would prefer specific code!
	_STZA local3
	_STZA local3+1
	_STZA local3+2
	_STZA local3+3
fj_mul:
		LSR local2+1		; extract lsb from 2nd factor
		ROR local2
		BCC fj_next		; bit was clear, do not add
			LDX #0			; worth a loop for 4-byte addition!
			CLC
fj_add:
				LDA local1, X		; current 1st factor...
				ADC local3, X		; add to result
				STA local3, X		; and update it!
				INX
				CPX #4			; repeat until done
				BNE fj_add
; carry here means overflow, is that possible?
fj_next:
		ASL local1		; double 1st factor for next round
		ROL local1+1
		ROL local1+2
		ROL local1+3
; check remaining bits of 2nd factor
		LDA local2
		ORA local2+1
		BNE fj_mul		; still something to do
; multiply is done, but need to correct fixed point (12 bits right)
	LDX #4			; will shift 4 bits and discard LSB
fj_shift:
		LSR local3+3
		ROR local3+2
		ROR local3+1
		DEX			; one less to go
		BNE fj_shift
; if last shift gets C, should add one for accuracy! or subtract just one
; really must subtract 2 for VIA operation, LSB discarded
	LDA local3+1		; temporary LSB
; will not preset C and subtract just 1
	SBC #1			; minus 2 if C was clear
	TAY			; definitive LSB
	LDA local3+2		; this will be MSB
	SBC #0			; propagate borrow
; as result was in 2 middle bytes, MSB must be zero
	LDX local3+3		; is it clear?
	BNE fj_over		; no, outside range!
; start VIA counter as A.Y
		STY VIA_J+T1CL		; set computed period...
		STA VIA_J+T1CH		; ...and start counting!
		_BRA fj_end		; successful!
fj_over:
	_NO_CRIT
	_DR_ERR(INVALID)	; no changes were made
.)
