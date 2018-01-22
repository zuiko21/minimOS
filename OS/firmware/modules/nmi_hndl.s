; firmware module for minimOS·65
; (c)2018 Carlos J. Santisteban
; last modified 20180122-1333

; *** generic NMI handler for 6502/65C02 ***
; expected to be fully re-entrant
; NMOS savvy

; save registers AND system pointers
	PHA					; save registers (3x3)
	_PHX
	_PHY
; make NMI reentrant
	LDX sysptr			; get original word  (3+3)
	LDY sysptr+1
	_PHY				; store them in similar order (3+3)
	_PHX
	LDA systmp			; this byte too (3+3)
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
; *** here goes the former nmi_end routine, restore and exit ***
nmi_end:
	PLA					; retrieve saved vars (4+3)
	STA systmp			; only this byte
	_PLX				; sysptr... (4+4)
	_PLY
	STX sysptr			; ...is also restored (3+3)
	STY sysptr+1
; restore registers
	_PLY				; restore regular registers (3x4)
	_PLX
	PLA
	RTI					; resume normal execution, hopefully (6)

nmi_call:
	JMP (fw_nmi)		; call actual code, ending in RTS, DUH (5/6...)

; *** execute standard NMI handler ***
rst_nmi:
	LDA #>nmi_end-1		; prepare return address
	PHA
	LDA #<nmi_end-1		; now LSB (safer than PEA)
	PHA
; ...will continue thru subsequent standard handler, its RTS will get back to ISR exit

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
std_nmi:
#include "firmware/modules/std_nmi.s"
