; cold boot firmware module for minimOS
; v0.5a2
; (c) 2015-2016 Carlos J. Santisteban
; placeholder, but C816 and NMOS savvy!
; last modified 20160309-0945

	SEC					; would set back emulation mode on C816
	.byt	$FB			; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA $0				; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
; machines with ROM-on-RAM should switch on ROM
	JMP ($FFFC)			; cold reset as placeholder
