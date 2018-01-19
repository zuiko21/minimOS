; firmware module for minimOS·16
; (c)2017-2018 Carlos J. Santisteban
; last modified 20180119-0852

; *** basic initialisation ***
; assumed to start at 'reset' label (in template file)
; 65816 version, pretty much the same as 6502!
; no interface needed

-reset:
	SEI				; cold boot, best assume nothing (2)
	CLD				; just in case, a must for NMOS (2)
; reset the 65816 to emulation mode, just in case
	SEC					; would set back emulation mode on C816
	XCE					; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA 0				; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
; now we are surely into emulation mode, initialise basic stack at $1FF
	LDX #SPTR			; initial stack pointer, must be done in emulation for '816 (2)
	TXS					; initialise stack (2)
