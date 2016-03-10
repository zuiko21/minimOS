; NMI module for minimOS
; v0.5a3
; (c) 2015-2016 Carlos J. Santisteban
; originally issued 20130512 ???
; last modified 20160310

#ifndef 	KERNEL
#define		KERNEL	_NMI
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
#include "drivers/config/DRIVER_PACK.h"
#include "drivers/config/DRIVER_PACK.s"
.text
#endif

; *** non-maskable interrupt (debugger) ***
; registers already saved in handler!
; ***********revise...
	JSR nled_reset	; reset output device LED keypad, just in case
	LDA #<nmi_txt	; string address load
	STA sysptr
	LDA #>nmi_txt
	STA sysptr+1
debug:			; entry point for BRK
	LDA z2		; save possible kernel function in progress
	PHA
;	LDY default_out	; default device
deb_str:
		_LDAX(sysptr)	; get character
			BEQ deb_wait	; NUL at end of string
		STA z2			; get the character ready...
		JSR nled_cout	; somewhat ugly
		INC sysptr		; next character
		BNE deb_str
	INC sysptr+1	; boundary crossing
		_BRA deb_str

; ***** simulate interrupts calling led_poll!
deb_wait:
LDX #4		; 4 is about 195 Hz @ 1 MHz, no need to set the LSB
deb_dly:
DEY
BNE deb_dly	; delay loop, 1280 clocks
DEX		; one iteration less
BNE deb_dly
JSR nled_get	; simulate interrupt!

; ***** read key and wait until OK is pressed
JSR nled_cin	; read keypad buffer
BCS deb_wait	; nothing pressed
LDA z2		; the ASCII code
CMP #13		; is it OK?
BNE deb_wait	; keep waiting otherwise
LDA #12		; load FF code
STA z2		; print form feed, clears screen
JSR nled_cout

PLA		; retrieve old parameter
STA z2		; nothing has changed!

; return to process
RTS	; new standard ending 20160310

nmi_txt:		; splash text string
.asc "NMI>", 0

; *** better driver calls, 20150125
nled_reset:
	JMP (drv_led+D_INIT)
nled_cout:
	JMP (drv_led+D_COUT)
nled_get:
	JMP (drv_led+D_POLL)
nled_cin:
	JMP (drv_led+D_CIN)
