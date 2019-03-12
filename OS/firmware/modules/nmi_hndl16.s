; firmware module for minimOS·16
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190312-1007

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
	PHX
	PHA					; why 8-bit systmp was on top? (3+4)
; switch DBR to bank zero!!!! but not really needed as JMP[abs] takes the pointer from bank zero
;	PHK					; push a zero... (3+4)
;	PLB					; ...as current data bank!
; in case an unaware 6502 app installs a handler ending in RTS,
; stack imbalance will happen, best keep SP and reset afterwards
#ifdef	SUPPORT
	TSX					; get stack pointer LSB (2)
	STX sys_sp			; best place as will not switch (3)
#endif
; let us get ready for the return address
;	PHK					; return bank is zero (3)
;	PEA nmi_end-1		; prepare return address (5)
; perhaps not worth, just call routine jump!
#ifdef	SAFE
; check whether user NMI pointer is valid
; first copy vector into zeropage, as per long-indirect requirement
	LDA @fw_nmi+2		; bank too, new (6) will also get a discarded sys_sp
	TAX					; unfortunately, no LDX long! (2)
	LDA @fw_nmi			; copy vector to zeropage, now 24b (6)
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
	JSR @nmi_jmp

; ********************************************
; *** here goes the former nmi_end routine ***
; ********************************************
+nmi_end:
#ifdef	SUPPORT
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
	TSC					; the whole stack pointer, will not mess with B (2)
	.as: SEP #$20		; ** 8-bit memory for a moment ** (3)
	LDA sys_sp			; will replace the LSB with the stored value (3)
	TCS					; all set! (2)
#else
	.as: SEP #$20		; ** 8-bit memory for a moment ** (3)
#endif
; new extended state order needs this new code (10b instead of 8b)
	.xl: REP #$10		; ** 16-bit index for sysptr ** (3)
	PLX					; this gets sysptr (5)
	PLA					; retrieve systmp and restore it, no longer including sys_sp (4)
	STA systmp			; restore values (3+4)
	STX sysptr
	.al: REP #$20		; ** whole register size to restore the rest ** (3)
; as DBR was pushed, time to restore it
	PLB					; eeeeeeeek (4)
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register sizes, hopefully

; *******************************
; *** NMI user-routine caller ***
; *******************************
; return address already set! No need to reset DBR as only DP is accessed afterwards
; MUST respect DP and sys_sp, though
.as:.xs:
nmi_jmp:
	JMP [fw_nmi]		; will return upon RTL... or RTS (8)

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
