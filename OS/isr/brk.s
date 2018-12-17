; minimOS BRK handler
; v0.6a2, bumped as per 816 version
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20181217-0934

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
	TSX				; current stack pointer
	LDY $0109, X	; get MSB (note offset below)
	LDA $0108, X	; get LSB+1
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
		LDA (sysptr), Y	; get current char
			BEQ brk_term	; if ended, finish printed line
		JSR brk_out		; send out character! saves 6 bytes
		_PLY			; restore counter
		INY				; next in string
		BNE brk_ploop	; this version will not print over 256 chars!
#ifdef	SAFE
		BEQ brk_end		; string too long, should never arrive
#endif
brk_term:
	PLA				; discard saved counter
brk_end:
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
;	LDY #0			; default
;	STA io_c		; kernel parameter
;	KERNEL(COUT)	; system call
;	RTS
