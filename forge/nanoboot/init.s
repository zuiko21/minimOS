; startup nanoBoot for 6502, v0.2a1
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190112-1559

; *** needed zeropage variables ***
; nb_rcv, received byte (No longer need to be reset!)
; nb_flag, sets bit 7 when a byte is ready (autoreset!)
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be consecutive
; nb_ex (word) keeps initial address, should be consecutive
; *** will temporarily use 3 more bytes, the last one for checking valid header ***

nb_init:
	SEI					; make sure interrupts are off (2)
; *** set interrupt handlers ***
#ifndef	SETOVER
	LDX #4				; copy 4 bytes (2)
nb_svec:
		LDA nb_tab-1, X		; get origin from table (4)
		STA fw_isr-1, X		; and write for FW (4)
		DEX					; next (2+3)
		BNE nb_svec		; ends with X as 0 for optimum performance!
#else
	LDY #<nb_nmi		; copy routine address...
	LDA #>nb_nmi
	STY fw_nmi			; ...and store it into firmware
	STA fw_nmi+1
	LDX #0				; must keep this value for performance (2)
#endif
; *** wait for a valid nanoBoot link *** $4B, end.H, end.L, start.H, start.L
; note big-endian for simpler memory filling!
; the magic byte ($4B) could be ignored as well
; *** get nanoBoot header ***
	LDY #4				; will receive five bytes 0...4 (2)
nb_loop:
		JSR nb_grc			; get one byte ()
		STA nb_ptr, Y		; store in variable (4)
		STA nb_ex, Y		; simpler way, nb_ex should be after both pointers (4)
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
	STX nb_ptr			; ready for indirect-indexed (X known to be zero)
; *** execute transfer *** worst case 55? clocks per byte plus both interrupts
nb_get:
		JSR nb_grc			; wait for byte ()
		STA (nb_ptr), Y		; store at destination (5 or 6)
; *** performance when using NMI/IRQ *** must revise
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
; X must be 0!!! takes at least 20t (+6n)
nb_grc:
	STX nb_flag			; clear flag! (3)
#ifdef	TIMEBOOT
	STX timeout			; preset counter for ~0.92 s @ 1 MHz
	STX timeout+1
nb_grc2:
		DEC timeout			; one less to go (5)
		BNE nb_cont			; if still within time, continue waiting after 8 extra cycles (3/2)
			DEC timeout+1		; update MSB too otherwise (5)
		BNE nb_cont			; not yet expired, continue after 15 extra cycles (3/2)
			PLA					; discard return address otherwise... (4+4)
			PLA
			BNE nb_exit			; ...and proceed with standard boot!
nb_cont:
#else
nb_grc2:
#endif
		BIT nb_flag			; received something? (3)
		BPL nb_grc2			; no, keep trying (3/2)
	LDA nb_rcv			; get received (3)
	RTS

; **********************************************************************
; *** in case nonvalid header is detected, reset or continue booting ***
; **********************************************************************
nb_exit:
#ifndef	TIMEBOOT
	JMP ($FFFC)			; reset, hopefully will go elsewhere
#endif
