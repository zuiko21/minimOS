; minimOS·16 BRK handler
; v0.6b1, taken from common 65C02 code
; (c) 2016-2019 Carlos J. Santisteban
; last modified 20181220-1139

#ifndef	HEADERS
#include "../usual.h"
#endif

lda#'B':jsr$c0c2
lda#'R':jsr$c0c2
lda#'K':jsr$c0c2
lda#'!':jsr$c0c2

; this is currently a panic/crash routine!
; first of all, send a CR to default device
	JSR brk_cr		; worth it
; let us get the original return address
; *** think about a padding byte on any BRK call, would make life much simpler!
; should this code depend on the status of E bit instead??
; actually, the 816 bits should get into brk16.s
; 65816 code was 14 bytes (actually 15)
	LDA 17, s		; bank too eeeeeeek^2
	STA systmp		; store after 16b pointer
	LDA 16, s		; get buried MSB
	TAY				; ...no LDY,s!
	LDA 15, s		; get buried LSB eeeeeeeeeeeeeeeek
	BNE brk_nw		; will not wrap upon decrement!
		DEY				; otherwise correct MSB
brk_nw:
	DEC				; back to signature address
; Y/A points to beginning of string
	STY sysptr+1	; prepare internal pointer, should it be saved for reentrancy?
	STA sysptr
	LDY #0			; eeeeeeeeeeeeeeeeeek
brk_ploop:
		PHY				; save cursor
		LDA [sysptr], Y	; get current char
			BEQ brk_term	; if ended, finish printed line
		JSR brk_out		; send out character! saves 6 bytes
		PLY				; restore counter
		INY				; next in string
		BNE brk_ploop	; this version will not print over 256 chars!
#ifdef	SAFE
		BRA brk_end		; string too long, should never arrive
#endif
brk_term:
	PLA				; discard saved counter
brk_end:
	JSR brk_cr		; another newline
; we are done, should call debugger if desired, otherwise we will just lock
	JMP lock		; let the system DIE
;	RTL				; *** otherwise let it finish the ISR

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
