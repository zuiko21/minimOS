; 65(C)51 ACIA firmware driver for minimOS
; v0.5a1
; (c) 2012-2018 Carlos J. Santisteban
; last modified 20180201-1330
; revised 20160115 for commit with new filenames

; in case of standalone assembly via 'xa firmware/modules/fd_6551.s'
#ifndef		NETBOOT
#include "usual.h"
#endif

.(
; *** constants for 65(C)51 registers ***
; get ACIA from options.h

F_ACIA_RD	= ACIA		; receive data
F_ACIA_TD	= ACIA		; transmit data
F_ACIA_SR 	= ACIA + 1	; status
F_ACIA_RES	= ACIA + 1	; reset
F_ACIA_CMD	= ACIA + 2	; command
F_ACIA_CTL	= ACIA + 3	; control

; some labels
fd_buf	= locals		; single byte buffer
fd_cont	= fd_buf+1		; contents

#ifndef		FINAL
	.asc	"<f_acia>"	; *** just for easier debugging ***
#endif

; *** initialise ***
fwn_init:
; hardware init
	STA F_ACIA_RES	; software reset, data is irrelevant
	LDA #%00011110	; 1 stop bit, 8-bit word, internal baud rate 9600
	STA F_ACIA_CTL	; control set
	LDA #%11001001	; parity disabled, no echo, Tx interrupt disabled?, Rx IRQ enabled, DTReady
	STA F_ACIA_CMD	; command sent
; anything else???
; single byte buffer setting
	_STZA fd_cont	; ACIA buffer is empty
	LDA #<fd_isr	; get ISR LSB
	STA zpar		; store parameter
	LDA #>fd_isr	; same for MSB
	STA zpar+1
	_ADMIN(SET_ISR)	; set ISR
	CLI				; enable interrupts!
	RTS

; *** output ***
fwn_cout:
	STA fd_buf		; store temporarily
	LDX #0			; reset timeout counters
	LDY #0
; check whether free, then put A into appropriate register
fd_ochk:
		LDA F_ACIA_SR		; check availability
		AND #%00010000	; TDRE bit
	BNE fd_free		; ready to send
;apply timeout
		INY				; increase LSB, very poor busy-wait (~0.85s @ 1 MHz)
	BNE fd_ochk		; continue checking
		INX				; increase MSB, could compare for shorter wait
	BNE fd_ochk
		_ERR(TIMEOUT)	; no timely reply
fd_free:
	LDA fd_buf		; get char to be sent
	STA F_ACIA_TD		; send it
	_EXIT_OK

; *** input ***
fwn_cin:
	LDX fd_cont	; number of characters in buffer
	BNE fd_some	; not empty
		_ERR(EMPTY)	; mild error otherwise
fd_some:
; could send XON here instead
	LDA F_ACIA_CMD	; current state
	AND #%11110011	; clear bit 2, just in case
	ORA #%00001000	; set bit 3 (/RTS goes low)
	STA F_ACIA_CMD	; allow sender to continue
; get byte from buffer
	LDA fd_buf		; gets char stored at buffer
	_STZA fd_cont	; no longer exists
	_EXIT_OK

; *** request ***
; ** this is the ISR for firmware driver **
fd_isr:
; ISR stuff
	PHA				; save registers
	_PHX
	_PHY
; assume ACIA is connected to /IRQ
; get received character
	LDA F_ACIA_SR		; check whether the ACIA was the source of IRQ
		BPL fd_rti	; not the ACIA
	ASL
	ASL				; get bit 6 on C, /DSR
		BCS fdr_err	; unexpected error
	ASL				; get bit 5 on C, /DCD
		BCS fdr_err
	ASL				; discard bit 4, TDRE
	ASL				; get bit 3 on C, RDRF
	BCS fdr_rcv		; a character arrived!
; most likely /CTS went up...
		_BRA fd_rti		; really don't know what to do here
fdr_rcv:
	BEQ fdr_ok		; no errors, go store it
		_ERR(CORRUPT)	; some framing errors*******************
fdr_ok:
; store it into buffer
	LDA F_ACIA_RD		; get the received character, relocated 20150211
	STA fd_buf		; store char from A into buffer
	INC fd_cont		; one more
; could send XOFF here instead
	LDA F_ACIA_CMD	; current state
	AND #%11110011	; clear bits 3-2 (/RTS goes high)
	STA F_ACIA_CMD	; ask sender to stop
fd_rti:
	_PLY			; restore registers
	_PLX
	PLA
	RTI				; go away
fdr_err:
	_ERR(N_FOUND)	; unexpected broken link**************
.)
