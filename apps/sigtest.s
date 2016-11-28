; SIGTERM test app for minimOS!
; v1.0b2
; (c) 2016 Carlos J. Santisteban
; last modified 20161128-1339

; for standalone assembly, set path to OS/
#include "usual.h"

; *** first some executable header ***
sts_header:
	.asc 0, "m", CPU_TYPE, 13				; standard system file wrapper
sts_title:
	.asc "SIGtest", 0						; filename
	.asc "Test app for SIGTERM handling", 0	; description as comment
	.dsb sts_header + $FC - *, $FF			; generate padding
sts_length = sts_end - sts_header			; *** compute actual file size INCLUDING HEADER ***
	.asc <sts_length, >sts_length, 0, 0		; 32-bit relative offset to next header
; *** en of minimOS executable header ***

; *** actual app code starts here ***
sts_start:
	LDA #0				; do not bother with STZ
	STA z_used			; no threads launched this far
	STA w_rect			; no window size, regular terminal
	STA w_rect+1
	LDY #<sts_title		; pointer of title string (filename)
	LDA #>sts_title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; get device
; hope default parameters are kept!
	STY def_io			; set defaults (hope they remain!!!)
	STY def_io+1
	LDX #CPU_TYPE		; from options.h
	STX cpu_ll			; set parameter
	LDY #<sts_thread	; get thread pointer
	LDA #>sts_thread
	STY ex_pt			; store parameter
	STA ex_pt+1
sts_launch:
		_KERNEL(B_FORK)		; reserve braid
		TYA					; check result
			BEQ sts_run			; no more free... or running on a single-task system!
		INC z_used			; launch counter
		LDX z_used			; as index
		STY z_used, X		; store in list, correct ZP opcode
; hopefully defaults are respected!
		_KERNEL(B_EXEC)		; launch thread!
	BCC sts_launch		; go for next
; this an error condition!
; * might free up that reserved braid via SIGKILL *
		LDX z_used			; retrieve index eeeeeeeeeek
		LDY z_used, X		; supposedly reserved PID
		LDA #SIGKILL		; this one should be freed
		STA b_sig			; store signal type
		_KERNEL(B_SIGNAL)	; send that SIGKILL!
; * braid is free, note error and continue execution of remaining threads *
		DEC z_used			; this was not successful eeeeeeeeek
		LDX #<stx_err		; get error pointer
		LDA #>stx_err
		LDY def_io			; retrieve parent device
		JSR sts_print		; print it
		JMP sts_timeout		; do not wait any longer!!!
; wait a few seconds with the threads running...
sts_run:
	LDA z_used			; check number of threads
	BNE sts_mm			; some of them, multitasking is active
		LDX #<stx_sts		; single-task system error pointer
		LDA #>stx_sts
		LDY def_io			; retrieve parent device
		JSR sts_print		; print error message
		JMP sts_clw			; clean up and we are done
sts_mm:
	_KERNEL(UPTIME)		; otherwise check time
	LDA up_sec			; get current second
	CLC
	ADC #3				; up to three seconds more
sts_wait:
		PHA					; keep destiny!
		_KERNEL(B_YIELD)	; give CPU time
		_KERNEL(UPTIME)		; check time again
		PLA					; retrieve deadline
		CMP up_sec			; arrived?
		BNE sts_wait		; keep waiting
; now send SIGTERM to every thread launched!
sts_timeout:
	LDX z_used			; get index
sts_terms:
		_PHX				; keep it!
		LDY z_used, X		; take PID from list
		LDA #SIGTERM		; will ask to terminate
		STA b_sig			; store as parameter
		_KERNEL(B_SIGNAL)	; send signal!
		_PLX				; retrieve index
		DEX					; one less to go
		BNE sts_terms		; until all done
; now keep giving CPU time until all finished
sts_shut:
	_KERNEL(B_YIELD)	; give away CPU time! eeeeeeeeek
	LDX z_used			; get task list index
sts_cont:
		LDY z_used, X		; get its PID
		_PHX				; push X
; here was a stray PHA eeeeeeeeeeeek
		_KERNEL(B_STATUS)	; check running state
		_PLX				; retrieve X
		CPY #BR_RUN			; is it running?
; might print some progress, including X value for reference...
			BEQ sts_shut		; still some running
		DEX					; otherwise check next in list
		BNE sts_cont		; until the list is exhausted
	LDX #<stx_bye		; end-of-app message
	LDA #>stx_bye
	LDY def_io			; retrieve parent device
	JSR sts_print		; print it
	JMP sts_clw			; clean up and finish

; ***********************************
; ** code for each launched thread **
; ***********************************
sts_thread:
	LDA #1				; number of needed bytes
	STA z_used			; uses just one
	_STZA uz			; reset the only flag
	JSR sts_pid			; print PID...
	LDX #<stx_intro		; ...and start info string
	LDA #>stx_intro
	JSR sts_axstr		; print it
	LDY #<sts_sigterm	; supply pointer routine
	LDA #>sts_sigterm
	STY ex_pt			; set parameter
	STA ex_pt+1
	_KERNEL(GET_PID)	; to myself *** this might be simplified to PID=0, but asking for it will not harm anyway
	_KERNEL(SET_HNDL)	; set it!
; might tell about successful installation
sts_timer:
	LDA #SPEED_CODE		; ** kludge, but makes it speed-independent **
sts_ext:
			LDY #12				; should take about 0.5 seconds
			LDX #0				; for guaranteed execution time
sts_loop:
				BIT uz				; check flag
					BMI sts_rcv			; received SIGTERM! go away
				INX					; internal counter, 256 times*10 clocks
				BNE sts_loop
			DEY					; and another one, 12 iterations
			BNE sts_loop		; will take about 30.7 ms
		SEC
		SBC #1				; decrement speed index
		BEQ sts_ext			; until all done
; loops completed, should take 0.5 seconds regardless of CPU speed!
		JSR sts_pid			; print PID...
		LDX #<stx_alive		; ...and alive message
		LDA #>stx_alive
		JSR sts_axstr		; print it
		BCC sts_timer		; stay forever until SIGTERM arrives (or a strange I/O error)
	_PANIC("{I/O}")		; something went VERY wrong
sts_rcv:
	JSR sts_pid			; print PID...
	LDX #<stx_termrc	; ...and final string
	LDA #>stx_termrc
	JSR sts_axstr		; print it
	_FINISH				; all done

; ** the supplied SIGTERM handler **
sts_sigterm:
	DEC uz				; just turn zeropage flag into all ones
; better do NOT print anything as kernel is NOT really reentrant within the same context
	RTI					; new end!

; *** useful routines ***
; * print string pointed by A.X *
sts_axstr:
; this will print at default (parent) device
	LDY #0				; default device
sts_print:
; this will assume own device in Y
	STX str_pt			; set parameter
	STA str_pt+1
	_KERNEL(STRING)		; print
	RTS

; * get PID and print it in decimal *
sts_pid:
	_KERNEL(GET_PID)	; get actual braid number
	TYA					; into A
; ...continue to convert to decimal and print PID, return to whatever caller

; * convert value in A into decimal LSB, put decimal MSB in X, then print them! *
sts_bin2dec:
	LDX #0				; reset MSD
sts_dl:
		CMP #10				; over ten?
			BCC sts_pr100		; nothing else to do, go print it
		INX					; add another ten
		SBC #10				; subtract to LSD (borrow was set)
		BCS sts_dl			; as guaranteed to be at least 10, BRA is not needed
; ...continue to print as decimal ciphers, will return as appropriate

; * print X.A as two decimal ciphers (both below 10) *
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

; * clean up window and finish * NO RETURN
sts_clw:
	LDY def_io			; hope this device number remains!
	_KERNEL(FREE_W)		; no need to close in full
	_FINISH

; *** common strings ***
stx_intro:
	.asc	" started...", 13, 0		; begin-of-thread message
stx_alive:
	.asc	" alive", 13, 0				; message while running
stx_termrc:
	.asc	" received SIGTERM", 13, 0	; SIGTERM received
stx_err:
	.asc	"B_EXEC error!", 13, 0		; error at launch
stx_sts:
	.asc	"No multitasking!", 13, 0	; could not launch anything
stx_bye:
	.asc	"All done!", 13, 0			; no threads remain

sts_end:				; *** END OF FILE for size computation ***
