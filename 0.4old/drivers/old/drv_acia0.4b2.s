; minimOS 0.4b2 65(C)51 driver, 6502 SDx
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.14

; ACIA address on SDx (change if required)
#define	_ACIA	$DFE0

; *** begins with sub-function addresses table ***
	.word	acia_init	; initialize device and appropiate sysvars, called by POST only
	.word	acia_rts	; nothing periodic to do
	.word	acia_rcvd	; IRQ whenever a character arrived, put it into buffer
	.word	acia_cin	; input from buffer
	.word	acia_cout	; output to serial port (unbuffered)
	.word	acia_rts	; NEW, no need for 1-second interrupt
	.word	acia_rts	; NEW, no block input
	.word	acia_rts	; NEW, no block output
	.word	acia_rts	; NEW, no shutdown procedure
	.byt	%01110000	; no poll, by request, I/O, no 1-sec nor block transfers, non-relocatable (NEW)
	.byt	0		; reserved for 20-byte block align

; *** output ***
acia_cout:
; check whether free, then put A into appropiate register
	LDA _ACIA+	; whatever ACIA register to check availability
	AND #whatever bit
	BEQ acia_free
	;apply timeout
acia_free:
	LDA z2
	STA _ACIA+	; whatever register
	_EXIT_OK

; *** input ***
acia_cin:
	LDX ser_cont	; number of characters in buffer
	BNE acin_some	; not empty
	_ERR(_empty)	; mild error otherwise
acin_some:
	LDX ser_read	; position to be read from buffer
	CPX ser_size	; just past the end?
	BNE acin_no_wrap
	LDX #0		; wrap around
acin_no_wrap:
	LDA ser_buf, X	; gets char stored at buffer
	STA z2		; output value
	INX		; advance to next position
	STX ser_read	; update pointer
	DEC ser_cont	; one less
	_EXIT_OK

; *** request ***
acia_rcvd:
; get received character
	LDA _ACIA+	; whatever register the ACIA has
; store it into buffer
	LDX ser_cont	; number of characters in buffer
	CPX ser_size	; already full?
	BEQ acrc_full
	LDX ser_write	; position to be written on buffer
	CPX ser_size	; just past the end?
	BNE acrc_no_wrap
	LDX #0		; wrap around
acrc_no_wrap:
	STA ser_buf, X	; store char from A into buffer
	INX		; advance to next position
	STX ser_write	; update pointer
	INC ser_cont	; one more
	_EXIT_OK
acrc_full:
	_ERR(_full)	; no room

; *** initialise ***
acia_init:
; hardware init...
	LDA #16		; like a 16c550!
	STA ser_size
	LDA #0		; NMOS, only for subsequent STZs
	STA ser_write	; init ACIA buffer variables
	STA ser_read
	STA ser_cont
	_EXIT_OK
