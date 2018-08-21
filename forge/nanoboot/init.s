; startup nanoBoot for 6502
; (c) 2018 Carlos J. Santisteban
; last modified 20180821-2158

; *** needed zeropage variables ***
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be consecutive
; nb_ex (word) keeps initial address
; nb_rcv, received byte (must be reset to 1)
; nb_flag, sets bit 7 when a byte is ready (autoreset, or bit 7 clear)

nb_init:
	SEI					; make sure interrupts are off (2)
	LDX #1				; initial value (2)
	STX nb_rcv			; preset received value (3)
	STX nb_flag			; reset reception flag (3)
; *** set interrupt handlers ***
; a loop plus table is 15b 53t, but needs consecutive fw vars
; old code was 20b 24t
	LDY #3				; copy bytes 0...3 (2)
nb_svec:
		LDA nv_tab, Y			; get origin from table (4)
		STA fw_isr, Y			; and write for FW (4)
		DEY					; next (2+3)
		BPL nb_svec
; *** wait for a valid nanoBoot link *** $4B, [start], [end]
; the wait loop, get rcv and reset flags are 30b
; a subroutine can be 20b plus 2b saving, at some performance expense
	JSR nb_grc			; wait for reception and reset flags ()
	CMP #$4B			; valid nanoBoot link? (2)
	BNE nb_exit			; no, abort (2...)
; *** get nanoBoot header ***
		LDY #0				; counter for bytes of header (2) X for savvyness if needed
nb_loop:
			JSR nb_grc			; wait for reception and reset flags ()
			STA nb_ptr, Y			; store in variable (4)
			INY
			CPY #4				; all of header done? (2+2)
			BNE nb_loop			; (3/2)
; prepare variables for transfer ************ continue here
		LDX #1				; resetting value (2)
		LDY nb_ptr			; make a copy of initial address (3+3)
		LDA nb_ptr+1
		STY nb_ex			; Y is offset already (3+3)
		STA nb_ex+1
		_STZA nb_ptr			; ready for indirect-indexed (3 for CMOS)
; *** execute transfer *** worst case 43 clocks per byte plus both interrupts
nb_get:
				BIT nb_flag			; received something? (3)
				BPL nb_get			; (3/2)
			LDA nb_rcv			; check received (3)
			STA (nb_ptr), Y		; store at destination (5 or 6)
			STX nb_rcv			; preset value (3)
			STX nb_flag			; clear bit 7 (3)
; NMI could happen from this point on
; as the interrupt cycle takes 68 clocks plus the longest opcode of 3 clocks,
; maximum speed is one bit every 71 clocks, which is about 14 kbps @ 1 MHz
; after each 8 bits, up to 43 clocks delay would total 114 clocks, 8.77 kbps
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
