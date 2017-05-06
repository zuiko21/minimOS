; 6809 code snippet in order to tell a 6800 CPU!
; (C) 2017 Carlos J. Santisteban
; last modified 20170506-1030

	LDA A #2			; clears V
	ROR $1				; 6800 sees TAP, NOP* which sets V
; *) note that address $1 is NOT safe on microcontrollers (P2DDR)
;    TAP, TAP is OK for external mode (rotates P3IO)
;    TAP, TSX is even safer (rotates $30)
;    note that CLR B ($5F) canNOT be used as clears V bit!!!
	BVC ok_6809			; ROR on 6809 keeps V clear
		JMP lock			; extended jump, same in 6800
ok_6809:
; *** safe to assume a 6809 if arrived here ***

; hex dump for this...
	; 86 02
	; 06 01* (06/30 is safer)
	; 28 03
	; 7E FF EE jumps to specified lock routine

; *** typical locking routine ***
; likely to be at $FFEE or similarly obvious address
lock:
	BRA lock			; 20 FE, will work on both CPUs

; **************************************************************************************
; the opposite situation (6800 code checking whether a 6809 is installed) goes like this
; **************************************************************************************

	LDA A #2		; 86 02
	TAP				; 06
	TSX				; 30		; safer than NOP
	BVS ok_6800		; 29 03
		JMP lock		; 7E FF EE
ok_6800:
; continue telling improvements over the original 6800?
	LSRD			; 04		; only on 6801/6301 will halve A
	CMP A #2		; 81 02		; regular 6800?
		BEQ set_cpu		; 27 04		; detected 6800/6802/6808 (A=2)
; microcontrollers have A halved at 1
	LDX #$0			; CE 00 00	; will clear A on Hitachi
	XGDX			; 18		; A takes X on Hitachi only
set_cpu:
; *** here A=0 for 6301/6303, A=1 for 6801/6803 and A=2 for 6800/6802/6808 ***

