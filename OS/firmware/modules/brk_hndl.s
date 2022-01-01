; firmware module for minimOS·65
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20181224-1540

; *** generic BRK handler for 65(C)02 ***
; NMOS-savvy

; unlike the 65816 or most (if not all) other architectures, this must be handled
; as a special case, as it will NEVER be called directly, but from IRQ ISR instead!
; it will be assumed that the whole status (including sysptr & systmp) is pushed
; into stack for ease of debuggers, and the kernel or app supplied BRK routine will
; end in RTS anyway.

-brk_hndl:
.(
; must use some new indirect jump, as set by new SET_BRK
	JSR brk_call		; indirect jump will return here
	JMP nmi_end			; standard firmware label
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return
.)
