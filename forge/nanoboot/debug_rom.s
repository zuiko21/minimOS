; DEBUG nanoBoot for 6502, v0.4a3
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20210219-1903

; *** needed zeropage variables ***
; nb_rcv, received byte (no longer need to be reset!)
; nb_flag, counter of shifted bits, goes zero when a byte is received
; nb_cur, selected anode on LTC4622 display (or digit)
; nb_disp (4 bytes) bitmap patterns (including selected anode)

; assumes NBEXTRA and DISPLAY options
#define	DISPLAY	_DISPLAY
#define	NBEXTRA	_NBEXTRA

#include "nanoboot.h"

	.text

	* =		$FF80

reset:
	SEI						; make sure interrupts are off (2)

; *************
; *** setup ***
; *************
; NMI/IRQ no longer vectored, but create startup display
	LDX #3					; copy 4 bytes (2)
nb_svec:
		LDA nb_boot, X		; while we are on it, prepare display message (4+4)
		STA nb_disp, X
		DEX					; next (2)
		BPL nb_svec			; no need to preset X (3)

nb_rec:
; ********************
; *** receive byte ***
; ********************
	LDX #8					; number of bits per byte (2)
	STX nb_flag				; preset bit counter (3)
; not really using timeout, as a valid server was detected
nb_gbit:
; feedback has to be given on every iteration!
			LDX nb_cur		; current position (3)
			LDA nb_disp, X	; get pattern (4)
			STA $FFF0		; put on display (4)
			INX				; next anode (2+2)
			TXA
			AND #3			; four anodes on a single LTC4622 display (2)
			STA nb_cur		; update for next round (3)
; continue checking for byte reception
			LDX nb_flag		; received something? (3)
			BNE nb_gbit		; no, keep trying (3/2)
; update byte MSN, takes 41t  more each 256 bytes
nb_msn:
		LDA nb_rcv			; get new page number (3)
		LSR					; MSN only (4x2)
		LSR
		LSR
		LSR
		TAX					; as index (2)
		LDA nb_pat, X		; low pattern first (4)
		AND #240			; MSN as cathodes (2)
		ORA #%0010			; enable first anode of first digit (2+3)
		STA nb_disp
		LDA nb_pat, X		; load again full pattern (4)
		ASL					; keep LSN only (2+2+2+2)
		ASL
		ASL
		ASL
		ORA #%0001			; enable second anode of first digit (2+3)
		STA nb_disp+1
; update byte LSN
nb_lsn:
		LDA nb_rcv			; get new page number (3)
		AND #15				; LSN only (2)
		TAX					; as index (2)
		LDA nb_pat, X		; low pattern first (4)
		AND #240			; MSN as cathodes (2)
		ORA #%1000			; enable first anode of second digit (2+3)
		STA nb_disp+2
		LDA nb_pat, X		; load again full pattern (4)
		ASL					; keep LSN only (2+2+2+2)
		ASL
		ASL
		ASL
		ORA #%0100			; enable second anode of second digit (2+3)
		STA nb_disp+3
; ...and loop forever!
		JMP nb_rec

; **************************
; *** interrupt handlers ***
; **************************

#include "nmi.s"
#include "isr.s"

; ********************
; *** diverse data ***
; ********************
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
nb_end:

; *******************
; *** ROM vectors ***
; *******************
	.dsb	$FFFA-*, $FF

	* =		$FFFA

	.word	nb_nmi
	.word	reset
	.word	nb_irq
