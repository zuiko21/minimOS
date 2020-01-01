; firmware module for minimOS·16
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20190226-1001

; *** generic BRK handler for 65816 ***
-brk_hndl:				; label from vector list
.(
; much like the ISR start
	.al: .xl: REP #$38	; status already saved, but save register contents in full, decimal off just in case (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeek (3)
; *** new NMI-like stack frame, easier on debuggers ***
	.xs: SEP #$10		; *** back to 8-bit indexes ***
	LDA sysptr			; get whole 16 bits
	LDX systmp			; do not mess with sys_sp
	PHX
	PHA
; in case an unaware 6502 app installs a handler ending in RTS,
; stack imbalance will happen, best keep SP and compare afterwards
#ifdef	SUPPORT
	TSX					; get stack pointer LSB
	STX sys_sp			; best place as will not switch
#endif
	.as: SEP #$20		; now all in 8-bit
; must use some new indirect jump, as set by new SET_BRK
; arrives in 8-bit, DBR=0 (no need to save it)
	JSR @brk_call		; JSL new indirect
	JMP nmi_end			; reusing standard code
; 6502 handlers will end in RTS causing stack imbalance, nmi_end will correct

; as no long-indirect call is available, long-call here and return to handler
brk_call:
	JMP [fw_dbg]		; will return
.)
	.as: .xs:			; otherwise might prevent code after ROM!
