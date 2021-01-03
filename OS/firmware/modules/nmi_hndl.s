; firmware module for minimOS·65
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20190119-1209

; *** generic NMI handler for 6502/65C02 ***
; expected to be fully re-entrant
; NMOS savvy

.(
#ifdef	NMOS
	CLD					; eeeeeeeeek! 20150316
#endif
; save registers AND system pointers
	PHA					; save registers (3x3)
	_PHX
	_PHY
; have to save systmp and sysptr, new faster (18 vs 41t) way, just one more byte!
	LDA systmp				; new order
	PHA					; eeeeeeeeek
	LDA sysptr+1
	PHA
	LDA sysptr
	PHA
#ifdef	SAFE
; check whether user NMI pointer is valid
; alternative faster way 39b, 58t (was 29b, 89t)
	LDY fw_nmi			; copy vector to zeropage (corrected 20150118) (4+4+3+3)
	LDA fw_nmi+1
	STY sysptr			; nicer way 20160407
	STA sysptr+1
	LDY #0				; offset for NMI code pointer (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'U'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'N'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'j'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'*'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
#endif
	JSR nmi_call		; will do indirect call (6...)
; **************************************************************
; *** here goes the former nmi_end routine, restore and exit ***
; **************************************************************
+nmi_end:
; restore temporary vars, faster way is 9b, 24t (vs. 8b/40t)
	PLA					; get byte from stack, new order (4)
	STA sysptr			; restore it (4)
	PLA					; get byte from stack (4)
	STA sysptr+1		; restore it (4)
	PLA					; get byte from stack (4)
	STA systmp			; restore it (4)
; restore registers
	_PLY				; restore regular registers (3x4)
	_PLX
	PLA
	RTI					; resume normal execution, hopefully (6)

; *** execute installed NMI handler ***
nmi_call:
	JMP (fw_nmi)		; call actual code, ending in RTS, DUH (5/6...)

; *** execute standard NMI handler ***
rst_nmi:
	JSR std_nmi			; call standard handler
	_BRA nmi_end		; and finish as usual

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
+std_nmi:
#include STD_NMI
.)
