; firmware module for minimOS·65
; (c)2018 Carlos J. Santisteban
; last modified 20180129-1428

; *** generic BRK handler for 65(C)02 ***
; **** preliminary, 65816-like  code ****

-brk_hndl:				; label from vector list
.(
; much like the ISR start
	PHA					; save registers (3x3)
	_PHX
	_PHY
; this only accepts routines ending in RTS
; thus no need to save S in sys_sp
; must use some new indirect jump, as set by new SET_BRK
	JSR brk_call		; indirectg jump will return here
; cannot reset SP to previous value...
; restore full status and exit
	_PLY				; restore status and return (3x4)
	_PLX
	_PLA
	RTI
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return
.)
