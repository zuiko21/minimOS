; firmware module for minimOS
; nanoBoot loader
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20220322-1009

.(
fb_pos	= $5440				; 10 lines + 1 raster below

	LDX #0					; reset index
nb_prn:
		LDA text, X
	BEQ wait				; end of string
		_PHX
		TAY					; print A
		JSR conio
		_PLX
		INX
		BNE nb_prn			; no need for BRA
wait:						; *** OLD placeholder, wait for a couple of seconds ***
;	LDA #15					; about 3s wait
;loop:
;			INY
;			BNE loop
;		INX
;		BNE loop
;	_DEC
;	BNE loop
; *** end of OLD placeholder   ***

; *** *** *** ******** *** *** ***
; *** *** *** NANOBOOT *** *** ***
; *** *** *** ******** *** *** ***

; *** needed zeropage variables ***
; nb_rcv, received byte (no longer need to be reset!)
; nb_flag, counter of shifted bits, goes zero when a byte is received
; nb_ptr (word) for initial address, will use as pointer
; nb_fin (word) is final address, MUST be right after nb_ptr
; nb_ex (word) keeps initial address, should be consecutive
; *** will temporarily use 3 more bytes, the last one for checking valid header ***

	SEI						; make sure interrupts are off (2)
; ******************************
; *** set interrupt handlers *** SET OVERFLOW no longer supported
; ******************************
	LDX #3					; copy 4 bytes (2)
nb_svec:
		LDA nb_tab, X		; get origin from table (4)
		STA fw_isr, X		; and write for FW (5)
; final Durango-X has no debug display
		DEX					; next (2)
		BPL nb_svec			; no need to preset X (3)

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
#endif
			LDX nb_flag			; received something? (3)
			BNE nb_lbit			; no, keep trying (3/2)
		LDA nb_rcv			; get received (3)
; note NMI gets inverted bytes, is this OK for neg_server.c?
;		EOR #$FF			; NOPE***must invert byte, as now works the opposite (2)

; *********************************
; *** header byte received in A ***
; *********************************
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

; optionally display colour dot at end of feedback line
	LDX nb_fin+1			; get last page (or is it first page after transfer?)
	LDA #$05				; green rightmost pixel
	STA fb_pos, X
; prepare variables for transfer
	LDX #0					; will be used later, remove if STZ is available
	STX nb_ptr				; ready for indirect-indexed (X known to be zero, or use STZ)
	TAY						; last byte loaded is the index! (2)
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
;	EOR #$FF				; NOPE***must invert byte, as now works the opposite (2) NO LONGER, but check neg_server

; **************************
; *** byte received in A ***
; **************************
		STA (nb_ptr), Y		; store at destination (5 or 6)
		INY					; next (2)
		BNE nbg_nw			; check MSB too (3/7)
			INC nb_ptr+1
; *** page has changed, may be reflected on display ***
; new, display progress as dots on Durango-X screen! ***
			LDX nb_ptr+1	; get page number as index (3)
			LDA #$0F		; white rightmost pixel (2)
			STA fb_pos, X	; store sequentially (4)
nbg_nw:
		CPY nb_fin			; check whether ended (3)
		BNE nb_rec			; no, continue (3/11/10)
			LDA nb_ptr+1	; check MSB too
			CMP nb_fin+1
		BNE nb_rec			; no, continue
; ********************************************
; *** transfer ended, execute loaded code! ***
; ********************************************
#ifdef	SAFE
; should I reset NMI/IRQ vectors?
#endif
	JMP (nb_ex)				; go!

; ***********************************************
; *** otherwise, it failed one way or another ***
; ***********************************************
nb_err:
; *** might display something to tell error from timeout *** may unify routines
	LDX #0					; reset index
err_prn:
		LDA nberr_tx, X
	BEQ nb_pexit			; end of string
		_PHX
		TAY					; print A
		JSR conio
		_PLX
		INX
		BNE err_prn			; no need for BRA
nb_pexit:
; delay with buzzer to display error condition
			JSR subdly		; standard extra cycles!
			INY				; delay loop
			BNE nb_pexit	; up to 4351t ~2832 uS
		STX IOBeep			; make it buzz at ~353 Hz
		INX
		BNE nb_pexit		; total time up to ~0.7 s
; *** *** *** ************************************************ *** *** ***
; *** *** *** if nanoboot code did timeout, resume normal boot *** *** ***
; *** *** *** ************************************************ *** *** ***
nb_exit:
	LDX #0					; reset index
to_prn:
		LDA delete, X
	BEQ continue			; end of string
		_PHX
		TAY					; print A
		JSR conio
		_PLX
		INX
		BNE to_prn			; no need for BRA

; ***************
; *** strings ***
; ***************
text:
	.asc	"nanoBoot?", 0
delete:
	.asc	2, 18, 2, '*', 18, STD_INK, 13, 0
nberr_tx:
	.asc	18, 2, "ERROR!", 0
subdly:
	RTS						; could be elsewhere
continue:
.)
