; RickRolling for Acapulco!
; (c) 2019 Carlos J. Santisteban
; last modified 20190512-1745

.(
; *** minimOS header to be done ***

; *** zeropage declarations ***
	vptr	= local1	; 16-bit indirect pointer
	frames	= local1+2	; 8-bit frame counter, enough for ~8s

; *** initial code ***
#ifdef	SAFE
	_STZA ex_pt			; get standard ISR
	_STZA ex_pt+1
	_ADMIN(SET_ISR)
	LDA ex_pt+1			; and save it for later
	PHA
	LDA ex_pt			; LSB too
	PHA
#endif
; ** set audio interrupt handler **
	SEI					; audio disabled by default
	LDY #<au_isr			; ISR address
	LDA #>au_isr
	STY ex_pt			; set new ISR
	STA ex_pt+1
	_ADMIN(SET_ISR)
; ** set 125 uS sampling rate ** TO DO **** TO DO **** TO DO ****
	LDY #0				; reset counter...
	STY vptr			; ...and indirect pointer
; ** must fill bitmap with checkered pattern **
	LDA #$60			; start of VRAM
	STA vptr+1
; new code is faster and takes 20b, was 26b
	LDA #%01010101			; display pattern
vi_pat:
	LDX #4					; pages per pattern change
vi_fill:
		STA (vptr), Y			; write to screen
		INY					; next
		BNE vi_fill			; until page is done
			INC vptr+1			; next page
				BMI vi_pb			; VRAM full
			DEX					; should I change pattern?
		BNE vi_fill			; no, continue
			EOR #$FF			; ...or invert it
		BNE vi_pat			; no need for BRA
vi_pb:
; ** VIA setup **
; must set T1 continuous interrupt (ACR, IER)
; every 192 pulses (T1CL, T1CH)
; PA all input, no latching (DDRA, ACR)
; PB all output (DDRB)
; PB7 first high (for reset) and then all PB to zero (IORB)
; SR free run (ACR, T2CL)
#ifdef	SAFE
; save previous setup
; T1 interrupt is likely to be enabled
	LDA #%01111111			; disable previous interrupts
	STA VIA_U+IER
	LDA #%11000000			; enable T1 only
	STA VIA_U+IER
#endif
	LDA #%10010000			; no latch, free SR, T1 cont int.
	STA VIA_U+ACR
	LDX #$FF			; all output
	STX VIA_U+DDRB
	STA VIA_U+IORB			; set PB7 high for reset (PB4 irrelevant)
	INX				; 0 => all input
	STX VIA_U+DDRA
	STX VIA_U+IORB			; PB is ready to be used
	STX VIA_U+T2CL			; maximum shift rate
	LDA #190			; 125 uS sampling rate (minus 2)
	STA VIA_U+T1CL			; latch this speed...
	STX VIA_U+T1CH			; ...and start counting!
; ** prepare for video play **
	LDA #$5C			; start page of attribute area
	STA vptr+1
	LDA #240			; 8 seconds at 30fps
	STA frames			; prepare counter, zero may be acceptable
	JSR vsync			; * wait for frame start *
	CLI					; enable audio and start playing!
; *** main loop *** usually 34t per byte, nearly 21 ms per frame, almost 28 incl overhead :-(
vi_loop:
		LDA VIA_U+IORA			; get video data... (4)
		STA (vptr), Y			; ...into attribute area (5)
		INY					; next byte (2)
		BNE nx_vi			; check wrap or continue (3/15...)
			INC vptr+1			; next page (5)
			LDA vptr+1			; check attribute end (3+2)
			CMP #$60
			BNE nx_vi			; check end of frame (3...)
				LDA #$5C			; (2+3) reset pointer
				STA vptr+1
				JSR vsync			; one frame already passed, wait for next one
				DEC frames			; (5) fastest way up to 8s ~240 frames)
				BEQ ra_end			; (2) until video is finished
vi_nx:
		LDA VIA_U+IORB			; get port status (4)
; 6 lowest bits from PB1-6, rest on inboard counter pulsed by PB6 (total 7/8t)
		CLC
		ADC #2					; increase count on PB1-6 (2+2)
		BPL vi_plus			; PB7 did not change (3/4)
			AND #$7F			; clear it otherwise
vi_plus:
		STA VIA_U+IORB			; set updated value (4)
		JMP vi_loop			; continue until aborted (3)
; *** clean up and finish ***
ra_end:
#ifdef	SAFE
; restore previous VIA configuration
; restore previous ISR!
	PLA
	STA ex_pt
	PLA
	STA ex_pt+1
	_ADMIN(SET_ISR)
#endif

; *****************
; *** audio ISR *** max. overhead is 43t+cur. opcode (not 37t because of vectored IRQ)
; *****************
; at 1.536 MHz and 8 kHz sampling rate, overhead is ~30 uS/125 uS ~24%
au_isr:
	PHA					; only affected register (3)
	LDA VIA_U+T1CL			; muat acknowledge interrupt eeeeek (4)
	INC VIA_U+IORB			; put PB0 high (selects audio ROM) (6)
	LDA VIA_U+IORA			; get audio PWM pattern... (4)
	STA VIA_U+VSR			; ...into shift register (4)
	DEC VIA_U+IORB			; put back PB0 low (advances audio counter and selects video ROM)
	PLA					; restore register and finish (4+6)
	RTI
.)
