; startup nanoBoot for 6502, v0.3a2
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20201227-0111

; *** needed zeropage variables ***
; nb_rcv, received byte (No longer need to be reset!)
; nb_flag, sets bit 7 when a byte is ready (autoreset!)
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be consecutive
; nb_ex (word) keeps initial address, should be consecutive
; *** will temporarily use 3 more bytes, the last one for checking valid header ***

nb_init:
	SEI						; make sure interrupts are off (2)
; *** set interrupt handlers ***
#ifndef	SETOVER
	LDX #3					; copy 4 bytes (2)
nb_svec:
		LDA nb_tab, X		; get origin from table (4)
		STA fw_isr, X		; and write for FW (4)
		DEX					; next (2)
		BPL nb_svec			; no need to preset X (3)
#else
; *** alternate code in case /SO is used, no ISR is set ***
	LDY #<nb_nmi			; copy routine address...
	LDA #>nb_nmi
	STY fw_nmi				; ...and store it into firmware
	STA fw_nmi+1
#endif
; *** wait for a valid nanoBoot link *** $4B, end.H, end.L, start.H, start.L
; 'end' is actually first free address after code
; note big-endian for simpler memory filling!
; the magic byte ($4B) could be ignored as well
; *** get nanoBoot header ***
	LDY #4					; will receive five bytes 0...4 (2)
nb_loop:
		JSR nb_rec			; get one byte ()
		STA nb_ptr, Y		; store in variable (4)
		STA nb_ex, Y		; simpler way, nb_ex should be after both pointers (4)
		DEY					; next (2)
		BPL nb_loop			; until done (3/2)
; *** may check here for a valid header ***
#ifdef	SAFE
	LDY nb_ex+4				; this holds the magic byte (3)
	CPY #$4B				; valid nanoBoot link? (2)
		BNE nb_exit			; no, abort (2/3)
; could check for address boundaries as well
#endif
; prepare variables for transfer
	TAY						; last byte loaded is the index! (2)
	LDX #0
	STX nb_ptr				; ready for indirect-indexed (X known to be zero, or use STZ)
; *** execute transfer ***
; *** performance when using NMI/IRQ ***
; total overhead per byte (over nb_rec execution) is typically 17t
; *** performance when using SO (no IRQ) ***
nb_get:
		JSR nb_rec			; wait for byte in A, affects X (6+...)
		STA (nb_ptr), Y		; store at destination (5 or 6)
		INY					; next (2)
		BNE nbg_nw			; check MSB too (3/7)
			INC nb_ptr+1
nbg_nw:
		CPY nb_fin			; check whether ended (3) *** MUST REVISE *** may not stop outside page boundaries
		BNE nb_get			; no, continue (3/11/10)
			LDA nb_ptr+1	; check MSB too
			CMP nb_fin+1
		BNE nb_get			; no, continue
; *** transfer ended, execute loaded code! ***
	JMP (nb_ex)				; go!

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
; affects X
; whole byte takes at least 528t, or 600 w/TO (656 worst case)
; with display these times become 752, 824 or 880t, no less than 1136 B/s
nb_rec:
; *** standard overhead per byte is 16t, or 24t with timeout ***
	LDX #8					; number of bits per byte (2)
	STX nb_flag				; preset bit counter (3)
#ifdef	TIMEBOOT
	LDX #0					; or use STZs (2)
	STX timeout				; preset timeout counter for ~0.92 s @ 1 MHz (3+3)
	STX timeout+1
nb_gbit:
; *** optional timeout adds typically 8 cycles to loop, plus 7t sometimes ***
		DEC timeout			; one less to go (5)
		BNE nb_cont			; if still within time, continue waiting after 8 extra cycles (3/2)
			DEC timeout+1	; update MSB too otherwise (5)
		BNE nb_cont			; not yet expired, continue after 15 extra cycles (3/2)
			PLA				; discard return address otherwise... (4+4)
			PLA
			BNE nb_exit		; ...and proceed with standard boot!
nb_cont:
#else
nb_gbit:
; *** base loop is 6 cycles, plus interrupts => 64t/bit => 512t/byte ***
#endif
; sample code for LED display, constant 28t overhead (224 per byte)
;		LDX nb_cur			; current position (3)
;		LDA nb_disp, X		; get pattern (4)
;		STA via_pb			; put on anodes (4)
;		LDA nb_col, X		; get selected common cathode (4)
;		STA via_pa			; set it (4)
;		INX					; next char (2+2)
;		TXA
;		AND #3				; on a four digit display (2)
;		STA nb_cur			; update for next round (3)
		LDX nb_flag			; received something? (3)
		BNE nb_gbit			; no, keep trying (3/2)
	LDA nb_rcv				; get received (3)
	EOR #$FF				; must invert byte, as now works the opposite (2)
	RTS
; might include a second routine, without display updating nor timeout

; **********************************************************************
; *** in case nonvalid header is detected, reset or continue booting ***
; **********************************************************************
nb_exit:
#ifndef	TIMEBOOT
	JMP ($FFFC)				; reset, hopefully will go elsewhere
#endif
