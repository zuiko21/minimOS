; startup nanoBoot for 6502
; (c) 2018 Carlos J. Santisteban
; last modified 20180816-1816

; *** needed zeropage variables ***
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be consecutive
; nb_ex (word) keeps initial address
; nb_rcv, received byte (must be reset to 1)
; nb_flag, sets bit 7 when a byte is ready (autoreset, or bit 7 clear)

nb_init:
	SEI					; make sure interrupts are off
	LDY #1				; initial value
	STY nb_rcv			; preset received value
	STY nb_flag			; reset reception flag
; *** set interrupt handlers ***
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
		BIT nb_flag			; received something?
		BPL nb_wait
	LDA nb_rcv			; check received
	CMP #$4B			; valid nanoBoot link?
	BNE nb_exit			; no, abort
; *** get nanoBoot header ***
		LDX #0				; counter for bytes of header
		STY nb_rcv			; preset value
		STY nb_flag			; reset reception flag
nb_loop:
				BIT nb_flag			; received something?
				BPL nb_loop
			LDA nb_rcv			; check received
			STA nb_ptr, X			; store in variable
			STY nb_rcv			; reset value
			STY nb_flag			; clear bit 7
			INX
			CPX #4				; all of header done?
			BNE nb_loop
; prepare variables for transfer
		LDX #1				; resetting value
		LDY nb_ptr			; make a copy of initial address
		LDA nb_ptr+1
		STY nb_ex			; Y is offset already
		STA nb_ex+1
		_STZA nb_ptr			; ready for indirect-indexed
; *** execute transfer ***
nb_get:
				BIT nb_flag			; received something?
				BPL nb_get
			LDA nb_rcv			; check received
			STA (nb_ptr), Y		; store at destination
			STX nb_rcv			; preset value
			STX nb_flag			; clear bit 7
			INY					; next
			BNE nbg_nw			; check MSB too
				INC nb_ptr+1
nbg_nw:
			CPY nb_fin			; check whether ended
			BNE nb_get			; no, continue
				LDA nb_ptr+1			; check MSB too
				CMP nb_fin+1
			BNE nb_get			; no, continue
; *** transfer ended, execute loaded code! ***
		JMP (nb_ex)			; go!
nb_exit:
	JMP ($FFFC)			; reset, hopefully will go elsewhere
