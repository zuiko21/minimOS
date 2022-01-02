; firmware module for minimOS·65
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20220102-1414

; *** generic BRK handler for 65(C)02 ***
; NMOS-savvy

; unlike the 65816 or most (if not all) other architectures, this must be handled
; as a special case, as it will NEVER be called directly, but from IRQ ISR instead!
; it will be assumed that the whole status (including sysptr & systmp) is pushed
; into stack for ease of debuggers, and the kernel or app supplied BRK routine will
; end in RTS anyway.
; *** this should be responsible to complete the stack frame, NOT the IRQ ISR

-brk_hndl:
.(
	LDA systmp			; save extended state (6x3)
	PHA
	LDA sysptr+1
	PHA
	LDA sysptr
	PHA
; must use some new indirect jump, as set by new SET_BRK
	JSR brk_call		; indirect jump will return here
;	JMP brk_end			; standard firmware label, usually nmi_end
	PLA					; just in case, get down to regular ISR SF and return there
	STA sysptr
	PLA
	STA sysptr+1
	PLA
	STA systmp
	JMP non_brk			; should do it in firmware, and make IRQ-ISR callers specific if needed
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return
.)
