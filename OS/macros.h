; minimOS 0.5.1a2 MACRO definitions
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20161010-0946

; *** standard addresses ***

kernel_call	=	$FFC0	; ending in RTS, 816 will use COP handler and a COP,RTS wrapper for 02
admin_call	=	$FFD0	; ending in RTS, intended for kernel/drivers ONLY ** back to original address 20161010

; unified address (will lock at $FFEE-F anyway) for CMOS and NMOS ** new name 20161010
lock		=	$FFE0	; more-or-less 816 savvy address

; *** device numbers for optional pseudo-driver modules, TBD ***
TASK_DEV	=	128
WIN_DEV		=	129
FILE_DEV	=	130

; *** considerations for minimOS·16 ***
; kernel return is via RTI (note CLC trick)
; kernel functions are expected to be in bank zero!
; 6502 apps might work bank-agnostic, binaries should use wrapper JSR pointer, RTL
; driver routines are expected to be in bank zero too... standard JSR/RTS, must return to kernel!

; *** common function calls ***

; system calling interface *** unified ·65 and ·16 macros

#ifndef	C816
#define		_KERNEL(a)		LDX #a: JSR kernel_call
#else
#define		_KERNEL(a)		LDX #a: CLC: COP #$FF
#endif

; * C816 API functions ending in RTI and redefined EXIT_OK and ERR endings!
; * C02 wrapper then should be like			COP #$FF	RTS

; administrative calls unified for 6502 and 65816, all ending in RTS (use DR_OK and DR_ERR macros)
#define		_ADMIN(a)		LDX #a: JSR admin_call


; new macro for filesystem calling, no specific kernel entries!
; ** revise for 816 systems ****
#define		_FILESYS(a)		STY locals+11: LDA #a: STA zpar: LDY #FILE_DEV: _KERNEL(COUT)

; *** function endings ***
; new FINISH and ABORT macros for app exit to shell, using RTL for 65816
; firmware interface can no longer use EXIT_OK and ERR, now reserved for the kernel API

#ifndef	C816
#define		_FINISH		CLC: RTS
#define		_EXIT_OK	CLC: RTS
#define		_ABORT(a)	LDY #a: SEC: RTS
#define		_ERR(a)		LDY #a: SEC: RTS
#else
#define		_FINISH		CLC: RTL
#define		_EXIT_OK	RTI
#define		_ABORT(a)	LDY #a: SEC: RTL
#define		_ERR(a)		LDY #a: PLP: SEC: PHP: RTI

; ***** alternative preCLC makes error handling 2 clocks slower, so what? *****

; most code endings (except kernel API and apps) for both 6502 and 816 (expected to be in bank zero anyway)
; such code without error signaling (eg. shutdown, jiffy interrupt) may just end on RTS no matter the CPU
#define		_DR_OK		CLC: RTS
#define		_DR_ERR(a)	LDY #a: SEC: RTS

; new exit for asynchronous driver routines when not satisfied
#define		_NEXT_ISR	SEC: RTS
#define		_ISR_DONE	CLC: RTS
; can no longer use EXIT_OK because of 65816 reimplementation!!! check drivers!

; new macros for critical sections, do not just rely on SEI/CLI
#define		_ENTER_CS	PHP: SEI
#define		_EXIT_CS	PLP

; ** interrupt enable/disable macros deprecated 20161003 and replaced by the above macros **

; ** panic call, now using BRK in case of error display ** new BRK handled 20161010
#define		_PANIC(a)	BRK: .asc a, 0

; *** conditional opcode assembly ***
#ifdef	NMOS
#define		_JMPX(a)	LDA a+1, X: PHA: LDA a, X: PHA: PHP: RTI
#define		_PHX		TXA: PHA
#define		_PHY		TYA: PHA
#define		_PLX		PLA: TAX
#define		_PLY		PLA: TAY
#define		_STAX(a)	LDX #0: STA (a, X)
; STAY/LDAY macros new 20150225 for faster emulation
#define		_STAY(a)	LDY #0: STA (a), Y
#define		_LDAX(a)	LDX #0: LDA (a, X)
#define		_LDAY(a)	LDY #0: LDA (a), Y
#define		_INC		CLC: ADC #1
#define		_DEC		SEC: SBC #1
#define		_BRA		JMP
; faster than CLC-BVC and the very same size, but no longer position-independent
#define		_STZX		LDX #0: STX
#define		_STZY		LDY #0: STY
#define		_STZA		LDA #0: STA
; new instructions implemented from www.6502.org/tutorials/65c02opcodes.html
; ...but they are not ATOMIC!!!
#define		_TRB(a)		BIT a: PHP: PHA: EOR #$FF: AND a: STA a: PLA: PHP
#define		_TSB(a)		BIT a: PHP: PHA: ORA a: STA a: PLA: PLP
#else
; standard CMOS opcodes
#define		_JMPX(a)	JMP (a, X)
#define		_PHX		PHX
#define		_PHY		PHY
#define		_PLX		PLX
#define		_PLY		PLY
#define		_STAX(a)	STA (a)
#define		_STAY(a)	STA (a)
#define		_LDAX(a)	LDA (a)
#define		_LDAY(a)	LDA (a)
#define		_INC		INC
#define		_DEC		DEC
#define		_BRA		BRA
#define		_STZX		STZ
#define		_STZY		STZ
#define		_STZA		STZ
#define		_TRB(a)		TRB a
#define		_TSB(a)		TSB a
#endif

; *** include here the syntax conversion of RMB/SMB/BBR/BBS for xa65 ***
#define		RMB0	RMB #0,
#define		RMB1	RMB #1,
#define		RMB2	RMB #2,
#define 	RMB3	RMB #3,
#define		RMB4	RMB #4,
#define		RMB5	RMB #5,
#define		RMB6	RMB #6,
#define		RMB7	RMB #7,
#define		SMB0	SMB #0,
#define		SMB1	SMB #1,
#define		SMB2	SMB #2,
#define		SMB3	SMB #3,
#define		SMB4	SMB #4,
#define		SMB5	SMB #5,
#define		SMB6	SMB #6,
#define		SMB7	SMB #7,
#define		BBR0	BBR #0,
#define		BBR1	BBR #1,
#define		BBR2	BBR #2,
#define		BBR3	BBR #3,
#define		BBR4	BBR #4,
#define		BBR5	BBR #5,
#define		BBR6	BBR #6,
#define		BBR7	BBR #7,
#define		BBS0	BBS #0,
#define		BBS1	BBS #1,
#define		BBS2	BBS #2,
#define		BBS3	BBS #3,
#define		BBS4	BBS #4,
#define		BBS5	BBS #5,
#define		BBS6	BBS #6,
#define		BBS7	BBS #7,
