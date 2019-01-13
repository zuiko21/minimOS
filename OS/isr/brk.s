; minimOS BRK panic handler
; v0.6b4
; (c) 2016-2019 Carlos J. Santisteban
; last modified 20190113-2057

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
	LDY $0111, X	; get MSB (note offset below)
	LDA $0110, X	; get LSB+1
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
lda#10:jsr$c0c2
lda#'D':jsr$c0c2
lda#'i':jsr$c0c2
lda#'e':jsr$c0c2
lda#'!':jsr$c0c2

	JMP lock		; let the system DIE
; if needed to return after BRK, skip panic message on stacked PC
;	SEC				; Y is in A, get ready for addition, skipping NUL!
;	ADC sysptr		; LSB...
;	TAY				; ...is ready in Y
;	LDA sysptr+1		; get MSB
;	ADC #0			; fix MSB if needed, now in A
;	TSX				; current stack pointer
;	STA $0110, X		; set LSB+1
;	TYA				; as no STY abs,X...
;	STA $0111, X		; ...set MSB
;	RTS				; *** otherwise let it finish the ISR

; send a newline to default device
brk_cr:
	LDA #10;CR
brk_out:
jsr$c0c2
rts
;	LDY #0			; default
;	STA io_c		; kernel parameter
;	KERNEL(COUT)	; system call
;	RTS
