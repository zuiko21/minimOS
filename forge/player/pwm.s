; PWM player for Durango-X!
; (c) 2021 Carlos J. Santisteban
; last modified 20211007-1708

; *** required variables (not necessarily in ZP) ***

	.zero

	* = 3					; minimOS-savvy ZP address

ptr		.word	0			; indirect pointer
zlimit	.byt	0			; end of sample page (not immediate for timing reasons)
zdelay	.byt	0			; spare byte

	.text

; *** hardware definitions ***
	IOBeep = $DFB0			; previously $Bxxx, only D0 checked

; *** player code ***

	* = $400				; downloadable version

	SEI						; standard init
	CLD
	LDX #$FF
	TXS
; won't bother with video mode settings

; must play sample at 12.8 kByte/sec rate, shifting bits at 8x that (102400 kbps)
; at 1.536 MHz that's a shift every 15 clocks! and reload every 120
	LDA #>end				; preload limit
	STA zlimit
	LDX #>audio				; base address
	LDY #0					; reset pointer, must be page aligned in order to avoid timing issues
	STY ptr					; set whole pointer
	STX ptr+1				; cannot put into loop for timing reasons
loop:
	LDA (ptr), Y			; get chunk of data (5 before counting, deduct from end anyway)
	STA IOBeep				; loaded D0 is out, order is actually irrelevant (4, 11 to go)
	INY						; *** get ready for next byte! (2, 9 to go)
	BNE nd1					; no page change? (3 if no, else 2) (6 or 7 to go)
		INX					; next page! (2, 5 to go in this case)
		BNE d1				; could be BRA, but skip balancing NOP (3, 2 to go)
nd1:
	NOP						; timing adjustment (2+2, 2 to go after both)
	NOP
d1:
	LSR						; checking D1 now (2, we're on time)
	STA IOBeep				; output on time (4, 11 to go)
	STX ptr+1				; update in the meanwhile, needed for delay anyway (3, 8 to go)
	NOP						; (3x2)
	NOP
	NOP
	LSR						; checking D2 now (2)
	STA IOBeep				; output on time (4)
	STA zdelay				; (3, 8 to go)
	NOP						; (3x2)
	NOP
	NOP
	LSR						; checking D3 now (2)
	STA IOBeep				; output on time (4)
	STA zdelay				; (3, 8 to go)
	NOP						; (3x2)
	NOP
	NOP
	LSR						; checking D4 now (2)
	STA IOBeep				; output on time (4)
	STA zdelay				; (3, 8 to go)
	NOP						; (3x2)
	NOP
	NOP
	LSR						; checking D5 now (2)
	STA IOBeep				; output on time (4)
	STA zdelay				; (3, 8 to go)
	NOP						; (3x2)
	NOP
	NOP
	LSR						; checking D6 now (2)
	STA IOBeep				; output on time (4)
	STA zdelay				; (3, 8 to go)
	NOP						; (3x2)
	NOP
	NOP
	LSR						; checking D7 now (2)
	STA IOBeep				; output on time (4, 11 to go)
	CPX zlimit				; are we done? (3, note extra cycle, 8 to go)
	BNE loop				; get another byte! (3, 5 to go... which loads A!)
; done
	STY IOBeep				; turn beeper off, just in case (Y known to be zero)
lock:
	BEQ lock				; no need for BRA

	.dsb	$500-*, $FF		; padding

* = $500

audio:
	.bin	0, 12335, "hello.pwm"	; get sample

	.dsb	12544-*, 0		; end padding for page-alignment, not sure about best value
end:
