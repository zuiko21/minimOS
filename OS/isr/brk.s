; minimOS BRK handler
; v0.5.1rc1
; (c) 2016-2017 Carlos J. Santisteban
; last modified 20170316-1245

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
	LDA 11, s		; get buried LSB eeeeeeeeeeeeeeeek
	TAX				; hold it
	LDA 12, s		; get buried MSB
	TXY				; prepare for later
	BNE brk_nw		; will not wrap upon decrement!
		DEC				; otherwise correct MSB
#endif
brk_nw:
	DEY				; back to signature address
; A/Y points to beginning of string
	STA sysptr+1	; prepare internal pointer, should it be saved for reentrancy?
	STY sysptr
	LDY #0			; eeeeeeeeeeeeeeeeeek
brk_ploop:
		_PHY			; save cursor
		LDA (sysptr), Y	; get current char
		BNE brk_prn		; more text to show, unfortunately NMOS macro needs this instead of BEQ brk_term
			PLA				; otherwise discard saved counter
			_BRA brk_term	; and finish printed line
brk_prn:
		JSR brk_out		; send out character! saves 6 bytes
		_PLY			; restore counter
		INY				; next in string
		BNE brk_ploop	; this version will not print over 256 chars!
brk_term:
	JSR brk_cr		; another newline
; we are done, should call debugger if desired, otherwise we will just lock
	JMP lock		; let the system DIE
;	RTS				; *** otherwise let it finish the ISR

; send a newline to default device
brk_cr:
	LDA #13			; CR
brk_out:
	LDY #0			; default
	STA io_c		; kernel parameter
	_KERNEL(COUT)	; system call
	RTS
