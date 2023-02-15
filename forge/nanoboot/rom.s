; minimal nanoBoot firmware *** now with devCart support on Durango-X
; v0.5b1
; (c) 2018-2023 Carlos J. Santisteban
; last modified 20230215-2138

; already NMOS-savvy

; *********************
; *** configuration ***
; *********************
; extra header checking
#define	SAFE	_SAFE

; timeout routines, will abort in ~0.9s @ 1 MHz
;#define	TIMEBOOT	_TIMEBOOT

; alternate version using /SO pin
;#define	SETOVER	_SETOVER

; progress display
#define	DISPLAY	_DISPLAY
; use LTC4622, otherwise Durango-X built-in display
;#define	LTC4622

; *************************************
; *** includes and system variables ***
; *************************************
#include "../../OS/macros.h"
#include "nanoboot.h"

; mimimal firmware variables!
; these should NOT go into zeropage, even if saving a few bytes
fw_isr	= $0200
fw_nmi	= $0202

; *************************
; *** boot ROM contents ***
; *************************
#ifndef	DISPLAY
* = $FF80					; 128 bytes will suffice, even with timeout!
#else
;* = $FF00					; display routines need much more space, but one page seems enough
* = $C000					; 16K ROM ready!
#endif

reset:
; standard 6502 init... NOT NEEDED
; * no adds or subtractions, thus decimal mode irrelevant
; * stack can be anywhere into page 1
;	CLD
;	LDX #$FF
;	TXS
#ifdef	DISPLAY
#ifndef	LTC4622
	SEI						; just in case of NMOS
; clear screen (Durango-X display only)
	LDA #$38				; lowres, RGB, usual screen 3
	STA $DF80				; set video mode
	LDY #0
	LDX #$60				; screen 3 start
	STX nb_ptr+1
	STY nb_ptr				; set ZP pointer
	TYA
dx_clr:
		STA (nb_ptr), Y		; clear screen byte (black)
		INY
		BNE dx_clr
	INC nb_ptr+1
	BPL dx_clr				; all pages
; Durango-X will set a blue strip at the bottom (ROM space)
	LDA #$CC				; azur
dx_blue:
		STA $7F80, Y		; last 128 bytes of screen (Y was known to be 0)
		INY
		BPL dx_blue
#endif
#endif

; ...followed by code chunks
#include "init.s"

; as this simple bootloader has nothing else to do, just lock (show red strip)
#ifdef	DISPLAY
#ifndef	LTC4622
	LDA #$22				; red as error
	LDY #0
dx_red:
		STA $7F00, Y		; last page of screen
		INY
		BNE dx_red
#endif
#endif
	BEQ *					; just lockout


; *** nanoBoot interrupt service routines ***
#ifndef	SETOVER
; regular version
#include "nmi.s"
#include "isr.s"
#else
; /SO version
#include "so_nmi.s"
#endif

; *** vectored interrupt handlers ***
nmi:
	JMP (fw_nmi)
irq:
	JMP (fw_isr)

; *** filling for ROM-ready files *** now with devCart support
	.dsb	$FFDC-*, $FF

switch:
	LDA #%01100000			; ROM disabled, protected RAM
	STA $DFC0
; * = $FFE1
	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
	.dsb	$FFFA-*, $FF

; *****************************
; *** standard 6502 vectors ***
; *****************************
* = $FFFA
	.word	nmi
	.word	reset
	.word	irq
