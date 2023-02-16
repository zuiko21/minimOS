; startup nanoBoot for 6502, v0.5b2
; (c) 2018-2023 Carlos J. Santisteban
; last modified 20230216-2319

; *** needed zeropage variables ***
; nb_rcv, received byte (no longer need to be reset!)
; nb_flag, counter of shifted bits, goes zero when a byte is received
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be right after nb_ptr
; nb_ex (word) keeps initial address, should be consecutive
; *** will temporarily use 3 more bytes, the last one for checking valid header ***

; note new NBEXTRA for enhanced feedback, may impair performance
;#define	NBEXTRA	_NBEXTRA

nb_init:
	SEI						; make sure interrupts are off (2)
; ******************************
; *** set interrupt handlers ***
; ******************************
#ifndef	SETOVER
; regular NMI/IRQ version full install
	LDX #3					; copy 4 bytes (2)
nb_svec:
		LDA nb_tab, X		; get origin from table (4)
		STA fw_isr, X		; and write for FW (5)
#ifdef	DISPLAY
#ifdef	LTC4622
		LDA nb_boot, X		; while we are on it, prepare display message (4+4)
		STA nb_disp, X
#endif
#endif
		DEX					; next (2)
		BPL nb_svec			; no need to preset X (3)
#else
; *** alternate code in case /SO is used, no ISR is set ***
	CLV						; reset this ASAP!
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
nb_lnk:
; ************************************************************
; *** receive byte on A, perhaps with feedback and timeout *** affects X
; ************************************************************

; *** standard overhead per byte is 16t, or 24t with timeout ***
		LDX #8				; number of bits per byte (2)
		STX nb_flag			; preset bit counter (3)
#ifdef	TIMEBOOT
		LDX #0				; or use STZs (2)
		STX timeout			; preset timeout counter for ~0.92 s @ 1 MHz, more if display is used (3+3)
		STX timeout+1
nb_lbit:
; *** optional timeout adds typically 8 or 15 (0.4% of times) cycles to loop ***
			DEC timeout			; one less to go (5)
			BNE nb_cont			; if still within time, continue waiting after 8 extra cycles (3/2)
				DEC timeout+1	; update MSB too otherwise (5)
			BNE nb_cont			; not yet expired, continue after 15 extra cycles (3/2)
				PLA				; discard return address otherwise... (4+4)
				PLA
				JMP nb_exit		; ...and proceed with standard boot!
nb_cont:
#else
nb_lbit:
; *** base loop w/o feedback is 6 cycles, plus interrupts => 64t/bit => 512t/byte ***
; make that 84t/bit and 672t/byte if LTC display is enabled 
#endif
#ifdef	DISPLAY
#ifdef	LTC4622
			JSR ltc_up			; mux display, total 32t per bit
#endif
#endif
			LDX nb_flag			; received something? (3)
			BNE nb_lbit			; no, keep trying (3/2)
#ifdef	DISPLAY
#ifdef	LTC4622
#ifdef		NBEXTRA
	LDA #%11101000			; dot on second digit (will show .. during header, adds a lot of overhead but transmission is slow anyway)
	STA nb_disp+2
	LDA #%11100010			; dot on first digit
	STA nb_disp
	STX nb_disp+1			; clear remaining segments (known to be zero)
	STX nb_disp+3
#endif
#endif
#endif
		LDA nb_rcv			; get received (3)
; note regular NMI get inverted bytes, while SO version does not
#ifndef	SETOVER
		EOR #$FF			; NOPE***must invert byte, as now works the opposite (2)
#endif
; **************************
; *** byte received in A ***
; **************************
		STA nb_ptr, Y		; store in variable (4)
		STA nb_ex, Y		; simpler way, nb_ex should be after both pointers (4)
		DEY					; next (2)
		BPL nb_lnk			; until done (3/2)
; *** may check here for a valid header ***
#ifdef	SAFE
	LDX nb_ex+4				; this holds the magic byte (3)
	CPX #$4B				; valid nanoBoot link? (2)
		BNE nb_err			; no, abort (2/3)
; could check for valid addresses as well
;	LDX nb_ptr+1
;	CPX nb_fin+1			; does it end before it starts?
;		BCC nb_ok			; no, proceed
;		BNE nb_err			; yes, abort
;	CMP nb_fin				; if equal MSB, check LSB (A known to have nb_ptr)
;		BCS nb_err			; nb_ptr cannot be higher neither equal than nb_fin
nb_ok:
; might also check for boundaries (system dependant)
#endif
; prepare variables for transfer
	LDX #0					; will be used later, remove if STZ is available
	STX nb_ptr				; ready for indirect-indexed (X known to be zero, or use STZ)
	TAY						; last byte loaded is the index! (2)
#ifdef	DISPLAY
; create acknowledge message while loading first page (12t + routine length)
#ifdef	LTC4622
	JSR show_pg
#else
; Durango-X may place a green dot on the last page position!
	LDX nb_fin+1			; finish page
	BEQ nb_rec				; show nothing for ROM images
		LDA #$55			; bright green eeeeek
		STA $7EFF, X		; indicate actual last page
#endif
#endif
; **************************************
; *** header is OK, execute transfer ***
; **************************************
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
	EOR #$FF				; NOPE***must invert byte, as now works the opposite (2) NO LONGER, but check SO option
#endif
; **************************
; *** byte received in A ***
; **************************
		STA (nb_ptr), Y		; store at destination (5 or 6)
#ifdef	DISPLAY
#ifdef	LTC4622
		JSR ltc_up			; now adds 32t per BYTE, likely irrelevant
#endif
#endif
		INY					; next (2)
		BNE nbg_nw			; check MSB too (3/7)
			INC nb_ptr+1
; *** page has changed, may be reflected on display ***
		LDX nb_ptr+1		; check current page
		CPX #$DF			; is it IO page?
		BNE no_io
			INC nb_ptr+1	; skip it EEEEEEK
no_io:
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
#ifdef	LTC4622
	LDA #$FF				; in case a TTL latch is used!
	STA $FFF0				; nice to turn off display!
#else
	LDX #0
	TXA
bot_clr:
		STA $7F00, X		; clear screen bottom
		INX
		BNE bot_clr
#endif
#endif
#ifdef	SAFE
; should I reset NMI/IRQ vectors?
#endif
;	JMP (nb_ex)				; go!
	JMP switch				; disable ROM and run from devCart RAM!

; **********************************************************************
; *** in case nonvalid header is detected, reset or continue booting ***
; **********************************************************************
nb_err:
#ifdef	DISPLAY
#ifdef	LTC4622
	LDA #%11100101			; dash on BOTH digits means ERROR
	BNE ltc_ab				; if no display, same as error
#endif
#endif
nb_exit:
#ifdef	DISPLAY
#ifdef	LTC4622
	LDA #$FF				; will clear display in case of timeout
							; might show '..' instead (%11101010)
ltc_ab:
	STA $FFF0				; put it on port
#endif
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
#ifdef	LTC4622
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
#else
; page display on Durango-X
show_pg:
	LDX nb_ptr+1			; current page (after switching)
	LDA #$FF				; elongated white dot
	STA $7EFF, X			; display on screen (finished page)
	RTS
#endif
#endif
; *** all finished, continue execution if unsuccessful ***
abort:
