; minimOS BRK handler
; v0.5.1rc4
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20181214-1640

#ifndef	HEADERS
#include "../usual.h"
#endif

; this is currently a panic/crash routine!
; expected to end in RTS anyway
lda#'B':jsr$c0c2
lda#'R':jsr$c0c2
lda#'K':jsr$c0c2

; first of all, send a CR to default device
	JSR brk_cr		; worth it
; let us get the original return address
; *** think about a padding byte on any BRK call, would make life much simpler!
; should this code depend on the status of E bit instead??
#ifndef	C816
; regular 6502 code
	TSX				; current stack pointer
	LDY $0109, X	; get MSB (note offset below)
	LDA $0108, X	; get LSB+1
#else
; 65816 code was 14 bytes (actually 15)
	LDA 16, s		; bank too eeeeeeek^2
	STA systmp		; store after 16b pointer
	LDA 15, s		; get buried MSB
	TAY				; ...no LDX,s!
	LDA 14, s		; get buried LSB eeeeeeeeeeeeeeeek
#endif
	BNE brk_nw		; will not wrap upon decrement!
		DEY				; otherwise correct MSB
brk_nw:
	_DEC				; back to signature address
; Y/A points to beginning of string
	STY sysptr+1	; prepare internal pointer, should it be saved for reentrancy?
	STA sysptr
	LDY #0			; eeeeeeeeeeeeeeeeeek
brk_ploop:
		_PHY			; save cursor
#ifdef	C816
		LDA [sysptr], Y	; get current char
#else
		LDA (sysptr), Y	; get current char
#endif
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
lda#'D':jsr$c0c2
lda#'i':jsr$c0c2
lda#'e':jsr$c0c2
lda#'!':jsr$c0c2

	JMP lock		; let the system DIE
;	RTS				; *** otherwise let it finish the ISR

; send a newline to default device
brk_cr:
lda#'c':jsr$c0c2
lda#'r':jsr$c0c2
	LDA #CR
brk_out:
jsr$c0c2
rts
	LDY #0			; default
	STA io_c		; kernel parameter
	_KERNEL(COUT)	; system call
	RTS
