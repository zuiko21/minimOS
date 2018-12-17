; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180906-1743

; *** generic BRK handler for 65816 ***
-brk_hndl:				; label from vector list
.(
; much like the ISR start
	.al: .xl: REP #$38	; status already saved, but save register contents in full, decimal off just in case (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeek (3)
; make sure we work on bank zero eeeeeeeeek ...but not really needed as JMP[abs] takes pointer from bank zero!
;	PHK					; stack a 0...
;	PLB					; ...for data bank
; *** new NMI-like stack frame, easier on debuggers ***
	.xs: SEP #$10		; *** back to 8-bit indexes ***
	LDA sysptr			; get whole 16 bits
	LDX systmp			; do not mess with sys_sp
	PHA
	PHX
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

; older corrected code for reference, needed to enter in 16-bit index
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
#ifdef	SUPPORT
;	.al:; REP #$20		; ** I think TSC needs to be in 16-bit **
;	TSC					; the whole stack pointer, will not mess with B
;	.as:; SEP #$20		; ** 8-bit memory for a moment **
;	LDA sys_sp			; will replace the LSB with the stored value
;	TCS					; all set!
#else
;	.as:; SEP #$20		; ** 8-bit memory for a moment **
#endif
; *** retrieve reserved vars ***
;	PLA					; this is 8-bit systmp
;	PLX					; this is 16-bit sysptr
;	STA systmp
;	STX sysptr
; restore full status and exit
;	.al:; REP #$20			; all 16-bit (3)
;	PLB					; eeeeeeeeeeeek (4)
;	PLY					; restore status and return (3x5)
;	PLX
;	PLA
;	RTI

; as no long-indirect call is available, long-call here and return to handler
brk_call:
	JMP [fw_dbg]		; will return
.)
	.as: .xs:			; otherwise might prevent code after ROM!
