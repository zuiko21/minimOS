; minimOS 0.4b1 SS-22 driver, 6502 SDx
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.01.25

; *** begins with sub-function addresses table ***
	.word	ss_init	; initialize VIA and appropiate sysvars, called by POST only
	.word	ss_rts	; nothing periodic to do
	.word	ss_rcp	; IRQ whenever Tx wants to send (start receiving) OR a character fully arrived (put it into buffer)
	.word	ss_cin	; input from buffer
	.word	ss_cout	; output via SS-22 (unbuffered)
	.word	ss_rts	; NEW, no need for 1-second interrupt
	.word	ss_rts	; NEW, no block input
	.word	ss_rts	; NEW, no block output

; *** output ***
ss_cout:
; check whether free, then put A into appropiate register
	LDA whatever VIA register to check availability
	AND #whatever bit
	BEQ ss_free
	;apply timeout
ss_free:
	LDA z2
	STA whatever register
	; pulse out CA2 and we're done
	; ...or wait until SR is empty?
	_EXIT_OK

; *** input ***
ss_cin:
	LDX ser_cont	; number of characters in buffer
	BNE ss_some	; not empty
	_ERR(_empty)	; mild error otherwise
ss_some:
	LDX ser_read	; position to be read from buffer
	CPX ser_size	; just past the end?
	BNE ss_no_wrap
	LDX #0		; wrap around
ss_no_wrap:
	LDA ssbuf, X	; gets char stored at buffer
	STA z2		; output value
	INX		; advance to next position
	STX ss_read	; update pointer
	DEC ss_cont	; one less
; there's room for another byte, please clear flag for flow control!
	_EXIT_OK

; *** request ***
ss_rcp:
; check whether the IRQ comes from CA2 (something to receive) or SR (fully shifted-in)
	LDA _VIA+_ifr	; interrupt cause
	;***
	Bxx ss_into	; it was SR, put char into buffer
	; ...or none, if I wait for the shift-in to be complete
	; set VIA for shift-in at adequate T2 rate
	RTS		; do something else in the while... or not
ss_into: 
; get received character
; ... LDA whatever SR the VIA has
; store it into buffer
	LDX ss_cont	; number of characters in buffer
	CPX ss_size	; already full?
	BEQ ss_full
	LDX ss_write	; position to be written on buffer
	CPX ss_size	; just past the end?
	BNE ssr_no_wrap
	LDX #0		; wrap around
ssr_no_wrap:
	STA ssbuf, X	; store char from A into buffer
	INX		; advance to next position
	STX ss_write	; update pointer
	INC ss_cont	; one more
	_EXIT_OK
acrc_full:
	; ...and set a flag for flow control, please!
	_ERR(_full)	; no room

; *** initialise ***
acia_init:
; hardware init...
	LDA #16		; like a 16c550!
	STA ss_size
	LDA #0		; NMOS, only for subsequent STZs
	STA ss_write	; init ACIA buffer variables
	STA ss_read
	STA ss_cont
	LDA #%01110000	; no poll, by request, I/O, no 1-sec nor block transfers
	STA sysvec	; authorize interrupts (not yet implemented)
	_EXIT_OK
