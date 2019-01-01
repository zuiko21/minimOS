; startup nanoBoot for 6502
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180824-2114

; *** needed zeropage variables ***
; nb_rcv, received byte (must be reset to 1)
; nb_flag, sets bit 7 when a byte is ready (autoreset, or bit 7 clear)
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be consecutive
; nb_ex (word) keeps initial address, should be consecutive
; *** will temporarily use 3 more bytes, the last one for checking valid header ***

nb_init:
	SEI					; make sure interrupts are off (2)
	LDX #1				; must keep this initial value (2)
	STX nb_rcv			; preset received value (3)
	STX nb_flag			; reset reception flag (3)
; *** set interrupt handlers ***
; a loop plus table is 15b 53t, but needs consecutive fw vars
; old code was 20b 24t
#ifndef	SETOVER
	LDY #3				; copy bytes 0...3 (2)
nb_svec:
		LDA nb_tab, Y			; get origin from table (4)
		STA fw_isr, Y			; and write for FW (4)
		DEY					; next (2+3)
		BPL nb_svec
#else
	LDY #<nb_nmi			; copy routine address...
	LDA #>nb_nmi
	STY fw_nmi			; ...and store it into firmware
	STA fw_nmi+1
#endif
; *** wait for a valid nanoBoot link *** $4B, end.H, end.L, start.H, start.L
; note big-endian for simpler memory filling!
; the magic byte ($4B) could be ignored as well
; *** get nanoBoot header ***
		LDY #4				; will receive bytes 0...4 (2)
nb_loop:
			JSR nb_grc			; wait for reception and reset flags (26+)
			STA nb_ptr, Y			; store in variable (4)
			STA nb_ex, Y			; simpler way, nb_ex should be after both pointers (4)
			DEY					; next (2)
			BPL nb_loop			; until done (3/2)
; may check here for a valid header
#ifdef	SAFE
		LDY nb_ex+4			; this holds the magic byte (3)
		CPY #$4B			; valid nanoBoot link? (2)
			BNE nb_exit			; no, abort (2/3)
#endif
; prepare variables for transfer
		TAY					; last byte loaded is the index! (2)
		_STZA nb_ptr			; ready for indirect-indexed (3 for CMOS)
; *** execute transfer *** worst case 55 clocks per byte plus both interrupts
nb_get:
			JSR nb_grc			; wait for byte (26+)
			STA (nb_ptr), Y		; store at destination (5 or 6)
; *** performance when using NMI/IRQ ***
; as the interrupt cycle takes 68 clocks plus the longest opcode of 6 clocks,
; maximum speed is one bit every 74 clocks, which is about 13.5 kbps @ 1 MHz
; after each 8 bits, up to 55 clocks delay would total 129 clocks, 7.75 kbps
; *** performance when using SO (no IRQ) ***
; interrupt cycle becomes at worst 24+7+6 = 37 clocks (27 kbps @ 1 MHz)
; including delay for each received byte is 92 clocks, 10.87 kbps
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

; *************************************
; *** table with interrupt pointers ***
; *************************************
nb_tab:
#ifndef	SETOVER
	.word	nb_irq
	.word	nb_nmi
#endif

; **********************************************************************
; *** routine waits for a fully received byte (in A) and clear flags ***
; **********************************************************************
; X must be 1!!! takes at least 20t (+6n)
nb_grc:
		BIT nb_flag			; received something? (3)
		BPL nb_grc			; (3/2)
	LDA nb_rcv			; check received (3)
	STX nb_rcv			; preset value (3)
	STX nb_flag			; clear bit 7 (3)
	RTS

; **********************************************************************
; *** in case nonvalid header is detected, reset or continue booting ***
; **********************************************************************
#ifdef	SAFE
nb_exit:
	JMP ($FFFC)			; reset, hopefully will go elsewhere
#endif
