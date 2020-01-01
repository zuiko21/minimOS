; (c) 2013-2020 Carlos J. Santisteban
* = 2
; zero-page variables
user	.byt 0	; minimOS compatibility
t_sec	.byt 0	; seconds counter
n_cnt	.byt 0	; recursive NMIs called; NOT really needed because we'll just check BNE anyway
n_par	.byt 0	; flag set by NMI pressing
i_cnt	.byt 0	; remaining IRQs for triggering

* = $200
irq_vec	.word isr	; minimOS-like ISR vector

* = $6FF0
; VIA registers
iorb	.byt 0
iora	.byt 0
ddrb	.byt 0
ddra	.byt 0
t1cl	.byt 0
t1ch	.byt 0
t1ll	.byt 0
t1lh	.byt 0
t2cl	.byt 0
t2ch	.byt 0
sr		.byt 0
acr		.byt 0
pcr		.byt 0
ifr		.byt 0
ier		.byt 0
nhra	.byt 0

* = $FD00
reset:	SEI			; usual init code
		CLD
		LDX #$FF	; set stack pointer
		TXS
		STX iora	; VIA init
		STX iorb
		STX ddra
		STX ddrb
		LDA #$7F	; disable all interrupt sources for a moment
		STA ier
		LDA #$C0
		STA ier		; enable T1 interrupt only
		STA pcr		; CB2 low, rest as input
		LDA #$40	; T1 continuous interrupts
		STA acr
		LDA #$4E	; T1-counter and latches = 50000 (-2)
		STA t1ll
		LDA #$C3
		STA t1lh	; just in case
		STA t1ch
		LDA #<preisr	; set preliminary IRQ vector
		STA irq_vec
		LDA #>preisr
		STA irq_vec+1
		CLI			; start timing

; application code
		LDA #4		; number of zero-page bytes used
		STA user	; for minimOS compatibility
		STX n_cnt	; set NMI debouncing ($FF)
		JSR set		; set time via NMI
		
		LDA #10
		STA i_cnt	; set initial delay
		SEI			; hold interrupts for a moment!
		LDA #<isr	; set IRQ vector
		STA irq_vec
		LDA #>isr
		STA irq_vec+1
		CLI			; start working!
		
; main loop
again:	SED			; BCD mode
		STZ n_par	; just in case
loop:	LDA n_par
		BEQ loop	; wait for NMI to be pressed
		
		LDA t_sec
		CMP #$30	; first half-minute?
		BMI adjust
;		INC iora	; next minute
		LDA iora
		CLC
		ADC #1
		STA iora
		CMP #$60	; wrap around?
		BMI adjust	; continue
		STZ iora	; reset minute
;		INC iorb	; next hour
		LDA iorb
		CLC
		ADC #1
		STA iorb
		CMP #$24	; wrap around?
		BMI adjust
		STZ iorb	; reset hour -- NOT minute!!!!
adjust:	STZ t_sec	; reset seconds
		CLD			; binary mode
		LDA #10
		STA i_cnt	; reset fraction
		LDA pcr		; set CB2
		AND #%11011111
		STA pcr		; turn on dots
		BRA again	; loop forever
		
; initial adjust
set:	SED			; decimal mode
		LDX #0		; cursor at hours
s_dig:	STZ iorb, X	; set to zero
s_res:	STZ n_par
s_chk:	LDA n_par
		BEQ tim		; nothing pressed?

		LDY #0		; debouncing timeout
s_deb:	CPY #2		; wait for a tenth of a second
		BMI s_deb
		
;		INC iorb, X	; increase digit
		LDA iorb, X
		CLC
		ADC #1
		STA iorb, X
		CPX #1		; minute setting?
		BEQ min
		CMP #$24	; hours wrapped?
		BMI s_res
		BRA s_dig	; return to zero
min:	CMP #$60	; minutes wrapped?
		BMI s_res	; not yet
		BRA s_dig	; return to zero

tim:	CPY #40		; two-seconds timeout, not $15
		BMI s_chk	; not yet
		INX			; next setting
		CPX #2		; all done?
		BMI s_dig
		STZ t_sec	; reset seconds
		CLD			; go away
		RTS

; increase time by 1 second
tick:	SED			; decimal mode
;		INC t_sec	; one more second
		LDA t_sec
		CLC
		ADC #1
		STA t_sec
		CMP #$60
		BMI ticked	; stay within same minute
		STZ t_sec	; reset seconds
;		INC iora	; one more minute
		LDA iora
		CLC
		ADC #1
		STA iora
		CMP #$60
		BMI ticked	; stay within same hour
		STZ iora	; reset minutes
;		INC iorb	; one more hour
		LDA iorb
		CLC
		ADC #1
		STA iorb
		CMP #$24
		BMI ticked	; stay within same day
		STZ iorb	; reset hour
ticked:	RTS

; temporary interrupt task (while setting)
preisr:	 LDA t1cl ; reset IFR bit ASAP!
     INY			; a 20th of a second has passed
		RTI
		
; regular interrupt task	
isr:	LDA t1cl ; reset IFR bit ASAP!
     CLD
		DEC i_cnt	; one less to go
		BNE i_exit	; time to go?
		PHA			; save register		
		LDA #10		; reset counter
		STA i_cnt
		LDA pcr		; toggle CB2
		EOR #%00100000
		STA pcr		; turn on/off dots
		AND #%00100000	; check whether off or on
		BNE i_done	; don't tick yet
		JSR tick	; one more second
i_done:	PLA			; restore register
i_exit:	RTI

; NMI, button pressed
nmi:
;		INC n_cnt	; how many NMIs? NOT really needed because we'll just check BNE anyway
;		BNE n_exit	; if not the first one, do nothing
		INC n_par	; set flag
;n_exit:	DEC n_cnt	; we're finished
		RTI

; ID string, pad with $FFs after that
        .asc " Clock for SDd/CHIHUAHUA with Porculete display, 1.0b3 ", 0

; 65C02 vectors
* = $FFF7
irq:	JMP (irq_vec)	; vectored ISR

		.word nmi	; NMI vector
		.word reset	; boot code
		.word irq	; IRQ vector
