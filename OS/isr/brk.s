; minimOS BRK panic handler
; v0.6.1a1
; (c) 2016-2021 Carlos J. Santisteban
; last modified 20190213-0848

#include "../usual.h"

; this is currently a panic/crash routine!
; expected to end in RTS anyway

; first of all, send a CR to default device
	JSR brk_cr			; worth it
; let us get the original return address, where the panic string begins
	TSX					; current stack pointer
	LDY $010B, X		; get MSB (note offset below)
	LDA $010A, X		; get LSB+1
	BNE brk_nw			; will not wrap upon decrement!
		DEY					; otherwise correct MSB
brk_nw:
	_DEC				; back to signature address
; Y/A points to beginning of string
	STY sysptr+1		; prepare internal pointer, should it be saved for reentrancy?
	STA sysptr
	LDY #0				; eeeeeeeeeeeeeeeeeek
brk_ploop:
		_PHY				; save cursor
		LDA (sysptr), Y		; get current char
			BEQ brk_term		; if ended, finish printed line
		JSR brk_out			; send out character! saves 6 bytes
		_PLY				; restore counter
		INY					; next in string
		BNE brk_ploop		; this version will not print over 256 chars!
#ifdef	SAFE
	DEY					; will turn to $FF, max length
	_PHY				; string too long, should never arrive, but try to crop it!
#endif
brk_term:
	JSR brk_cr			; another newline
	PLA					; retrieve saved counter
; we are done, should call debugger if desired, otherwise we will just lock
;	JMP lock			; let the system DIE
; if needed to return after BRK, skip panic message on stacked PC
	SEC					; Y is in A, get ready for addition, skipping NUL!
	ADC sysptr			; LSB...
	TAY					; ...is ready in Y
	LDA sysptr+1		; get MSB
	ADC #0				; fix MSB if needed, now in A
	TSX					; current stack pointer
	STA $010B, X		; set MSB eeeeeeeeeeeeeeek
	TYA					; as no STY abs,X...
	STA $010A, X		; ...set LSB eeeeeeeeeeeek
	JMP std_nmi			; testing, will return to BRK handler *** needs NMI_SF option ***
;	RTS					; *** otherwise let it finish the ISR

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
