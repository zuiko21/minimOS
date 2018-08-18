; startup nanoBoot for 6502
; (c) 2018 Carlos J. Santisteban
; last modified 20180818-1032

; *** needed zeropage variables ***
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be consecutive
; nb_ex (word) keeps initial address
; nb_rcv, received byte (must be reset to 1)
; nb_flag, sets bit 7 when a byte is ready (autoreset, or bit 7 clear)

nb_init:
	SEI					; make sure interrupts are off (2)
	LDY #1				; initial value (2)
	STY nb_rcv			; preset received value (3)
	STY nb_flag			; reset reception flag (3)
; *** set interrupt handlers *** (total 24)
	LDX #<nb_irq
	LDA #>nb_irq
	STX fw_isr
	STA fw_isr+1
	LDX #<nb_nmi
	LDA #>nb_nmi
	STX fw_nmi
	STA fw_nmi+1
; *** wait for a valid nanoBoot link *** $4B, [start], [end]
nb_wait:
		BIT nb_flag			; received something? (3)
		BPL nb_wait			; (3/2)
	LDA nb_rcv			; check received (3)
	CMP #$4B			; valid nanoBoot link? (2)
	BNE nb_exit			; no, abort (2...)
; *** get nanoBoot header ***
		LDX #0				; counter for bytes of header (2)
		STY nb_rcv			; preset value (3)
		STY nb_flag			; reset reception flag (3)
nb_loop:
				BIT nb_flag			; received something? (3)
				BPL nb_loop			; (3/2)
			LDA nb_rcv			; check received (3)
			STA nb_ptr, X			; store in variable (4)
			STY nb_rcv			; reset value (3)
			STY nb_flag			; clear bit 7 (3)
			INX
			CPX #4				; all of header done? (2+2)
			BNE nb_loop			; (3/2)
; prepare variables for transfer
		LDX #1				; resetting value (2)
		LDY nb_ptr			; make a copy of initial address (3+3)
		LDA nb_ptr+1
		STY nb_ex			; Y is offset already (3+3)
		STA nb_ex+1
		_STZA nb_ptr			; ready for indirect-indexed (3 for CMOS)
; *** execute transfer ***
nb_get:
				BIT nb_flag			; received something? (3)
				BPL nb_get			; (3/2)
			LDA nb_rcv			; check received (3)
			STA (nb_ptr), Y		; store at destination (5 or 6)
			STX nb_rcv			; preset value (3)
			STX nb_flag			; clear bit 7 (3)
			INY					; next (2)
			BNE nbg_nw			; check MSB too (3/7)
				INC nb_ptr+1
nbg_nw:
			CPY nb_fin			; check whether ended (3)
			BNE nb_get			; no, continue (3/11/10)
				LDA nb_ptr+1			; check MSB too
				CMP nb_fin+1
			BNE nb_get			; no, continue
; *** transfer ended, execute loaded code! ***
		JMP (nb_ex)			; go!
nb_exit:
	JMP ($FFFC)			; reset, hopefully will go elsewhere
