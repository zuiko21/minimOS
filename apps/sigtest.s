; SIGTERM test app for minimOS!
; v0.9a1
; (c) 2016 Carlos J. Santisteban
; last modified 20161025-1243

; for standalone assembly, set path to OS/
#include "usual.h"

; *** first some executable header ***
sts_header:
	.asc 0, "mN", 13						; standard system file wrapper
	.asc "SIGtest", 0						; filename
	.asc "Test app for SIGTERM handling", 0	; description as comment
	.dsb sts_header + $100 - *, $FF			; generate padding including end of linked list

; *** actual app code starts here ***
sts_start:


; ** code for each launched thread **
sts_thread:
	LDA #1				; number of needed bytes
	STA z_used			; uses just one
	JSR sts_pid			; print PID...
	LDY #<stx_intro		; ...and start info string
	LDA #>stx_intro
	STY str_pt			; store as parameter
	STA str_pt+1
	LDY #0				; default device
	STY uz				; reset the only byte used (SIGTERM flag)
	_KERNEL(STRING)		; print string
sts_loop:
			BIT uz				; check flag
				BMI sts_rcv			; received SIGTERM! go away
			INX					; one counter
			BNE sts_loop
		INY					; and another one
		BNE sts_loop
; loops completed in less than 0.8s @ 1 MHz
		JSR sts_pid			; print PID...
		LDY #<stx_alive		; ...and alive message
		LDA #>stx_alive
		STY str_pt			; set parameter
		STA str_pt+1
		LDY #0				; default device
		_KERNEL(STRING)		; print
		BCC sts_loop		; stay forever until SIGTERM arrives (or a strange error)
sts_rcv:
	JSR sts_pid			; print PID...
	LDY #<stx_termrc	; ...and final string
	LDA #>stx_termrc
	STY str_pt			; set parameter
	STA str_pt+1
	LDY #0				; default print
	_KERNEL(STRING)
	_FINISH				; all done

; ** the supplied SIGTERM handler **
sts_sigterm:
	DEC uz				; just turn zeropage flag into all ones
; better do NOT print anything as kernel is NOT really reentrant within the same context
	RTI					; new end!

; *** useful routines ***
; print X.A as two decimal ciphers (both below 10)
sts_pr100:
	PHA					; save LSD for a moment
	TXA					; get MSD
	BEQ sts_units		; only one cipher
	JSR sts_prdig		; print as ASCII
sts_units:
	PLA					; retrieve LSD
sts_prdig:
	CLC
	ADC #'0'			; should be less than 10
	STA io_c			; character to be printed
	LDY #0				; default device
	_KERNEL(COUT)		; print it
	RTS

; convert value in A into decimal LSB, put decimal MSB in X, then print them!
sts_bin2dec:
	LDX #0				; reset MSD
sts_dl:
		CMP #10				; over ten?
			BCC sts_b2d			; nothing else to do
		INX					; add another ten
		SBC #10				; subtract to LSD (borrow was set)
		BCS sts_dl			; as guaranteed to be at least 10, BRA is not needed
sts_b2d:
	JMP sts_pr100		; ** print as decimal ciphers, will return as appropriate **

; get PID and print it in decimal (uses all of the above)
sts_pid:
	_KERNEL(GET_PID)	; get actual braid number
	TYA					; into A
	JMP sts_bin2dec		; convert to decimal and print PID, return to whatever caller

; *** common strings ***
stx_intro:
	.asc	" started...", 13, 0		; begin-of-thread message
stx_alive:
	.asc	" alive", 13, 0				; message while running
stx_termrc:
	.asc	" received SIGTERM!", 13, 0	; SIGTERM received
