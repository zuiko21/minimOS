; minimOS·16 BRK handler
; v0.6b4
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20190225-1407

#ifndef	HEADERS
#include "../usual.h"
#endif
; this is currently a panic/crash routine!
; first of all, send a CR to default device
	JSR brk_cr			; worth it
; let us get the original return address
; *** think about a padding byte on any BRK call, would make life much simpler!
; should this code depend on the status of E bit instead??
; actually, the 816 bits should get into brk16.s
; 65816 code was 14 bytes (actually 15)
	LDA 17, s			; bank too eeeeeeek^2
	STA systmp			; store after 16b pointer
	LDA 16, s			; get buried MSB
	TAY					; ...no LDY,s!
	LDA 15, s			; get buried LSB eeeeeeeeeeeeeeeek
	BNE brk_nw			; will not wrap upon decrement!
		DEY					; otherwise correct MSB
brk_nw:
	DEC					; back to signature address
; Y/A points to beginning of string
	STY sysptr+1		; prepare internal pointer, should it be saved for reentrancy?
	STA sysptr
	LDY #0				; eeeeeeeeeeeeeeeeeek
brk_ploop:
		PHY					; save cursor
		LDA [sysptr], Y		; get current char
			BEQ brk_term		; if ended, finish printed line
		JSR brk_out			; send out character! saves 6 bytes
		PLY					; restore counter
		INY					; next in string
		BNE brk_ploop		; this version will not print over 256 chars!
#ifdef	SAFE
	DEY					; will turn to $FF, max length
	PHY					; string too long, should never arrive, but try to crop it!
#endif
brk_term:
	JSR brk_cr			; another newline
	PLY					; retrieve saved counter
; we are done, should call debugger if desired, otherwise we will just lock
;	JMP lock			; let the system DIE
; if needed to return after BRK, skip panic message on stacked PC
	.al: REP #$20
	SEC					; get ready for addition, skipping NUL!
	TYA					; original offset
	ADC sysptr			; adds to return address
	STA 15, S			; modify stacked PC, no need to deal with bank
; return address is ready, but try a debugger first
	.as: SEP #$20		; eeeeeeeeeeeeeek
	JMP @nanomon		; will exit via its own RTL!
;	RTL					; *** otherwise let it finish the ISR

.as:

; send a newline to default device
brk_cr:
	LDA #10;CR
brk_out:
jsr$c0c2
rts
;	LDY #0				; default
;	STA io_c			; kernel parameter
;	KERNEL(COUT)		; system call
;	RTS
