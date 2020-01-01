; 65(C)51 ACIA driver for minimOS
; v0.5b3
; (c) 2012-2020 Carlos J. Santisteban
; last modified 20150929-0944
; revised 20160928 FOR NEW INTERFACE

; *** constants for 65(C)51 registers ***
; get ACIA from options.h

; in case of standalone assembly via 'xa drivers/drv_acia.s'
#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"	; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
; specific header for this driver
#include "drivers/drv_acia.h"
.text
#endif


; some labels
ACIA_RD		= ACIA		; receive data
ACIA_TD		= ACIA		; transmit data
ACIA_SR 	= ACIA + 1	; status
ACIA_RES	= ACIA + 1	; reset
ACIA_CMD	= ACIA + 2	; command
ACIA_CTL	= ACIA + 3	; control

; *** begins with sub-function addresses table, new format 20150323 ***
	.byt	DEV_ACIA					; physical driver number D_ID (TBD)
	.byt	A_REQ + A_CIN + A_COUT		; no poll, by request, I/O, no 1-sec nor block transfers, non-relocatable (NEW format 20150323)
	.word	acia_init	; initialize device and appropiate sysvars, called by POST only
	.word	acia_rts	; nothing periodic to do
	.word	acia_rcvd	; D_REQ IRQ whenever a character arrives, put it into buffer
	.word	acia_cin	; input from buffer
	.word	acia_cout	; output to serial port (unbuffered)
	.word	acia_rts	; NEW, no need for 1-second interrupt
	.word	acia_rts	; NEW, no block input
	.word	acia_rts	; NEW, no block output
	.word	acia_bye	; NEW, shutdown procedure
	.word	acia_info	; NEW, points to descriptor string
	.byt	0			; reserved, D_MEM

; *** driver description, NEW 20150323 ***
acia_info:
	.asc	"ACIA 65(C)51 v0.5b3", 0
	
; *** initialise ***
acia_init:
; hardware init
	STA ACIA_RES	; software reset, data is irrelevant
	LDA #%00011110	; 1 stop bit, 8-bit word, internal baud rate 9600
	STA ACIA_CTL	; control set
	LDA #%11001001	; parity disabled, no echo, Tx interrupt disabled?, Rx IRQ enabled, DTReady
	STA ACIA_CMD	; command sent
; anything else???
; 16-byte buffer setting
	LDA #0			; NMOS savvy, only for subsequent STZs
	STA ser_write	; init ACIA buffer variables
	STA ser_read
	STA ser_cont
acia_rts:
	_DR_OK		; needed instead of RTS with the new strict kernel

; *** output ***
acia_cout:
	LDX #0			; reset timeout counters
	LDY #0
; check whether free, then put A into appropriate register
acia_ochk:
		LDA ACIA_SR		; check availability *** will not work on buggy WDC's ACIAs ***
		AND #%00010000	; TDRE bit *** will not work on buggy WDC's ACIAs ***
	BNE acia_free	; ready to send
;apply timeout
		INY			; increase LSB, very poor busy-wait (~0.85s @ 1 MHz)
	BNE acia_ochk	; continue checking
		INX			; increase MSB, could compare for shorter wait
	BNE acia_ochk
		_DR_ERR(TIMEOUT)	; no timely reply
acia_free:
	LDA zpar		; get char to be sent, revised 150205
	STA ACIA_TD		; send it
	_DR_OK

; *** input ***
acia_cin:
	LDX ser_cont	; number of characters in buffer
	BNE acin_some	; not empty
		_DR_ERR(EMPTY)	; mild error otherwise
acin_some:
	CMP #16			; buffer was full? maybe a lower number, see below
	BNE acin_noen	; nope, no need to restore Tx
; could send XON here instead
		LDA ACIA_CMD	; current state
		AND #%11110011	; clear bit 2, just in case
		ORA #%00001000	; set bit 3 (/RTS goes low)
		STA ACIA_CMD	; allow sender to continue
acin_noen:
	LDA ser_read	; position to be read from buffer
	AND #$0F		; modulo-16, new 20150211
	TAX				; used as index
	LDA ser_buf, X	; gets char stored at buffer
	STA zpar		; output value, revised name 150205
	INX				; advance to next position
	STX ser_read	; update pointer
	DEC ser_cont	; one less
	_DR_OK

; *** request ***
acia_rcvd:
; get received character
	LDA ACIA_SR		; check whether the ACIA was the source of IRQ
	BMI acia_do		; it was the ACIA
		_NEXT_ISR			; go away otherwise
acia_do:
	ASL
	ASL				; get bit 6 on C, /DSR
		BCS acrc_err	; unexpected error
	ASL				; get bit 5 on C, /DCD
		BCS acrc_err
	ASL				; discard bit 4, TDRE
	ASL				; get bit 3 on C, RDRF
	BCS acrc_rcv	; a character arrived!
; most likely /CTS went up...
		_DR_OK	; really don't know what to do here
acrc_rcv:
	BEQ acrc_ok		; no errors, go store it
		_DR_ERR(CORRUPT)	; some framing errors
acrc_ok:
; store it into buffer
	LDX ser_cont	; number of characters in buffer
	CPX #16			; already full?
		BEQ acrc_full
	LDA ser_write	; position to be written on buffer
	AND #$0F		; modulo-16, new 20150211
	TAX				; used as index
	LDA ACIA_RD		; get the received character, relocated 20150211
	STA ser_buf, X	; store char from A into buffer
	INX				; advance to next position
	STX ser_write	; update pointer
	INC ser_cont	; one more
	LDA ser_cont
	CMP #16			; check whether it's full now, could use a lower number to prevent overruns
	BMI acrc_room	; not yet
; could send XOFF here instead
		LDA ACIA_CMD	; current state
		AND #%11110011	; clear bits 3-2 (/RTS goes high)
		STA ACIA_CMD	; ask sender to stop
acrc_room:
	_DR_OK			; all done
acrc_full:
	_DR_ERR(FULL)	; there was no room
acrc_err:
	_DR_ERR(N_FOUND)	; unexpected broken link

; *** NEW shutdown procedure 150204 ***
acia_bye:
	LDA #%11000010	; /RTS hi -> Tx disabled, no ints, DT not ready
	STA ACIA_CMD	; command sent
	_DR_OK			; maybe RTS will suffice?


