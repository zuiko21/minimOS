; DEBUG nanoBoot for 6502, v0.4a2
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20210219-1005

; *** needed zeropage variables ***
; nb_rcv, received byte (no longer need to be reset!)
; nb_flag, counter of shifted bits, goes zero when a byte is received
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be right after nb_ptr
; nb_ex (word) keeps initial address, should be consecutive
; *** will temporarily use 3 more bytes, the last one for checking valid header ***

; note new NBEXTRA for enhanced feedback, may impair performance
#define	NBEXTRA	_NBEXTRA

nb_init:
	SEI						; make sure interrupts are off (2)
; ******************************
; *** set interrupt handlers ***
; ******************************
; regular NMI/IRQ version full install
	LDX #3					; copy 4 bytes (2)
nb_svec:
		LDA nb_tab, X		; get origin from table (4)
		STA fw_isr, X		; and write for FW (5)
		LDA nb_boot, X		; while we are on it, prepare display message (4+4)
		STA nb_disp, X
		DEX					; next (2)
		BPL nb_svec			; no need to preset X (3)

nb_rec:
; **********************************************************
; *** receive byte on A, without any feedback or timeout *** simpler and faster
; **********************************************************
	LDX #8					; number of bits per byte (2)
	STX nb_flag				; preset bit counter (3)
; not really using timeout, as a valid server was detected
nb_gbit:
; feedback, if any, is updated after each received byte
		LDX nb_flag			; received something? (3)
		BNE nb_gbit			; no, keep trying (3/2)
	LDA nb_rcv				; get received (3)
#ifndef	SETOVER
;	EOR #$FF				; NOPE***must invert byte, as now works the opposite (2) NO LONGER, but check SO option
#endif
; **************************
; *** byte received in A ***
; **************************
		STA (nb_ptr), Y		; store at destination (5 or 6)
#ifdef	DISPLAY
		JSR ltc_up			; now adds 32t per BYTE, likely irrelevant
#endif
		INY					; next (2)
		BNE nbg_nw			; check MSB too (3/7)
			INC nb_ptr+1
; *** page has changed, may be reflected on display ***
#ifdef	DISPLAY
		JSR show_pg			; adds 12t + routine length every 256 bytes
#endif
nbg_nw:
		CPY nb_fin			; check whether ended (3)
		BNE nb_rec			; no, continue (3/11/10)
			LDA nb_ptr+1	; check MSB too
			CMP nb_fin+1
		BNE nb_rec			; no, continue
; ********************************************
; *** transfer ended, execute loaded code! ***
; ********************************************
#ifdef	DISPLAY
	LDA #$FF				; in case a TTL latch is used!
	STA $FFF0				; nice to turn off display!
#endif
#ifdef	SAFE
; should I reset NMI/IRQ vectors?
#endif
	JMP (nb_ex)				; go!

; **********************************************************************
; *** in case nonvalid header is detected, reset or continue booting ***
; **********************************************************************
nb_err:
#ifdef	DISPLAY
	LDA #%11100101			; dash on BOTH digits means ERROR
	BNE ltc_ab				; if no display, same as error
#endif
nb_exit:
#ifdef	DISPLAY
	LDA #$FF				; will clear display in case of timeout
							; might show '..' instead (%11101010)
ltc_ab:
	STA $FFF0				; put it on port
#endif
	JMP abort				; get out of here, just in case

; *************************************
; *** table with interrupt pointers *** and diverse data
; *************************************
#ifndef	SETOVER
nb_tab:
	.word	nb_irq
	.word	nb_nmi
#endif
#ifdef	DISPLAY
nb_boot:
	.byt	%11010010, %10100001, %11011000, %00000100	; patterns to show 'nb' on LTC display (integrated anodes)
nb_pat:						; segment patterns for hex numbers
	.byt	%00010001		; 0
	.byt	%10011111		; 1
	.byt	%00110010		; 2
	.byt	%00010110		; 3
	.byt	%10011100		; 4
	.byt	%01010100		; 5
	.byt	%01010000		; 6
	.byt	%00011111		; 7
	.byt	%00010000		; 8
	.byt	%00011100		; 9
	.byt	%00011000		; A
	.byt	%11010000		; B
	.byt	%01110001		; C
	.byt	%10010010		; D
	.byt	%01110000		; E
	.byt	%01111000		; F
; *******************************************************
; ** LTC display update routine, 20t plus 12t overhead **
ltc_up:
	LDX nb_cur			; current position (3)
	LDA nb_disp, X		; get pattern (4)
	STA $FFF0			; put on display (4)
	INX					; next anode (2+2)
	TXA
	AND #3				; four anodes on a single LTC4622 display (2)
	STA nb_cur			; update for next round (3)
	RTS
; ****************************************
; ** LTC page display, no longer inline **
show_pg:
#ifdef	NBEXTRA
; show page MSN, takes 41t  more each 256 bytes
	LDA nb_ptr+1	; get new page number (3)
	LSR				; MSN only (4x2)
	LSR
	LSR
	LSR
	TAX				; as index (2)
	LDA nb_pat, X	; low pattern first (4)
	AND #240		; MSN as cathodes (2)
	ORA #%0010		; enable first anode of first digit (2+3)
	STA nb_disp
	LDA nb_pat, X	; load again full pattern (4)
	ASL				; keep LSN only (2+2+2+2)
	ASL
	ASL
	ASL
	ORA #%0001		; enable second anode of first digit (2+3)
	STA nb_disp+1
#endif
; show page LSN, takes 35t each 256 bytes
	LDA nb_ptr+1	; get new page number (3)
	AND #15			; LSN only (2)
	TAX				; as index (2)
	LDA nb_pat, X	; low pattern first (4)
	AND #240		; MSN as cathodes (2)
	ORA #%1000		; enable first anode of second digit (2+3)
	STA nb_disp+2
	LDA nb_pat, X	; load again full pattern (4)
	ASL				; keep LSN only (2+2+2+2)
	ASL
	ASL
	ASL
	ORA #%0100		; enable second anode of second digit (2+3)
	STA nb_disp+3
	RTS
#endif
; *** all finished, continue execution if unsuccessful ***
abort:
