; minimOS BRK handler
; v0.5.1a1
; (c) Carlos J. Santisteban
; last modified 20161010-1311

#include "usual.h"
; this is currently a panic/crash routine!
; expected to end in RTS anyway

; first of all, send a CR to default device
	JSR brk_cr		; worth it
; let us get the original return address
; *** think about a padding byte on any BRK call, would make life much simpler!
#ifndef	C816
; regular 6502 code
	TSX				; current stack pointer
	LDA $0108, X	; get MSB (note offset below)
	LDY $0107, X	; get LSB+1
	BNE brk_nw		; will not wrap upon decrement!
		_DEC			; otherwise correct MSB
#else
; 65816 code saves... one byte
	LDA 7, s		; get buried LSB
	TAX				; hold it
	LDA 8, s		; get buried MSB
	TXY				; prepare for later
	BNE brk_nw		; will not wrap upon decrement!
		DEC				; otherwise correct MSB
#endif
brk_nw:
	DEY				; back to signature address
; A/Y points to beginning of string
	STA sysptr+1	; prepare internal pointer, should it be saved for reentrancy?
	STY sysptr
brk_ploop:
		_PHY			; save cursor
		LDA (sysptr), Y	; get current char
		BNE brk_prn		; more text to show, unfortunately NMOS macro needs this instead of BEQ brk_term
			PLA				; otherwise discard saved counter
			_BRA brk_term	; and finish printed line
brk_prn:
		LDY #0			; default device
		STA io_c		; eeeeeeek
		_KERNEL(COUT)	; print it
		_PLY			; restore counter
		INY				; next in string
		_BRA brk_ploop
brk_term:
	JSR brk_cr		; another newline
; we are done, should call debugger if desired, otherwise we will just lock
	JMP lock		; let the system DIE
;	RTS				; *** otherwise let it finish the ISR

; send a newline to default device
brk_cr:
	LDY #0			; default
	LDA #13			; CR
	STA io_c		; kernel parameter
	_KERNEL(COUT)	; system call
	RTS
