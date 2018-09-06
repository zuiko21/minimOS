; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180831-2347

; *** generic NMI handler for 65816 ***
; expected to be fully re-entrant

.(
; save registers AND system pointers
	.al: .xl: REP #$30	; ** whole register size, just in case ** (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeeeeeeeek (3)
; prepare for following code while memory is still 16-bit!
	.xs: SEP #$10		; *** back to 8-bit indexes *** (3)
; make NMI reentrant, new 65816 specific code
	LDA sysptr			; get original words (4+3)
	LDX systmp			; this will no longer get sys_sp too!
	PHA					; make sure 8-bit systmp is on top (3+4)
	PHX
; switch DBR to bank zero!!!!
	PHK					; push a zero... (3+4)
	PLB					; ...as current data bank!
; in case an unaware 6502 app installs a handler ending in RTS,
; stack imbalance will happen, best keep SP and reset afterwards
#ifdef	SUPPORT
	TSX					; get stack pointer LSB (2)
	STX sys_sp			; best place as will not switch (3)
#endif
; let us get ready for the return address
	PHK					; return bank is zero (3)
	PEA nmi_end-1		; prepare return address (5)

#ifdef	SAFE
; check whether user NMI pointer is valid
; first copy vector into zeropage, as per long-indirect requirement
	LDA fw_nmi			; copy vector to zeropage, now 24b (5)
	LDX fw_nmi+2		; bank too, new (4)
	STA sysptr			; store all (4+3)
	STX sysptr+2		; actually systmp
; look for the magic string
	LDA [sysptr]		; get first word (7)
	CMP #'U'+256*'N'	; correct? (3)
		BNE rst_nmi			; not a valid routine (2/3)
	LDY #2				; point to second word (2)
	LDA [sysptr], Y		; get that (7)
	CMP #'j'+256*'*'	; correct? (3)
		BNE rst_nmi			; not a valid routine (2/3)
#endif

	.as: SEP #$20		; *** code is executed in 8-bit sizes ***
; jump to user-supplied handler!
; return address already set, but DBR is 0! No need to save it as only DP is accessed afterwards
; MUST respect DP and sys_sp, though
	JMP [fw_nmi]		; will return upon RTL... or RTS (8)
+nmi_end:
#ifdef	SUPPORT
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
	.al: REP #$20		; ** I think TSC needs to be in 16-bit ** (3)
	TSC					; the whole stack pointer, will not mess with B (2)
	.as: SEP #$20		; ** 8-bit memory for a moment ** (3)
	LDA sys_sp			; will replace the LSB with the stored value (3)
	TCS					; all set! (2)
#else
	.as: SEP #$20		; ** 8-bit memory for a moment ** (3)
#endif
; *** here goes the former nmi_end routine ***
	PLA					; restrieve systmp and restore it, no longer including sys_sp (4+3)
	STA systmp			; restore values (4+4)
	.al: .xl: REP #$30	; ** whole register size to restore the rest ** (3)
	PLA					; restore saved sysptr (5+5)
	STA sysptr
; as DBR was reset, time to restore it
	PLB					; eeeeeeeek (4)
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register sizes, hopefully

; *** execute standard NMI handler ***
rst_nmi:
	.xs:				; we came from 8-bit indexes
	.as: SEP #$20		; handler is executed in full 8-bit sizes (3)
; return address already set!
; ...will continue thru subsequent standard handler, its RTS/RTL will get back to ISR exit

; *** default code for NMI routine, enters in 8-bit sizes, if not installed or invalid, should end in RTL (RTS if SUPPORT enabled) ***
; note std_nmi MUST be exported as is used by brk_addr module!!!
+std_nmi:
#include STD_NMI

.as: .xs				; just in case
.)
