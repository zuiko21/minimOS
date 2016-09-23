; minimOS 0.5a11 MACRO definitions
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160923

; *** standard addresses ***
; redefined as labels 20150603
; revamped 20160308
; proper 816 support 20160919, revamped 0922

kernel_call	=	$FFC0	; ending in RTS, 816 will use COP handler and a COP,RTS wrapper for 02
admin_call	=	$FFD8	; ending in RTS, no way to use a PHK wrapper eeeeeeek! JSL adm16_call & RTS instead
adm16_call	=	$FFD0 	; ending in RTL, routines should push P for mode preservation in case is needed

; unified address (will lock at $FFEE-F anyway) for CMOS and NMOS, new 20150410
panic		=	$FFE0	; more-or-less 816 savvy address, new 20160308

; *** device numbers for optional pseudo-driver modules, TBD ***
; renamed as labels 20150603
TASK_DEV	=	128
WIN_DEV		=	129
FILE_DEV	=	130

; *** common function calls ***

; system calling interface *** unified ·65 and ·16 macros
; new primitive for administrative meta-kernel in firmware 20150118

#ifndef	C816
#define		_KERNEL(a)		LDX #a: JSR kernel_call
#define		_ADMIN(a)		LDX #a: JSR admin_call
#else
#define		_KERNEL(a)		LDX #a: CLC: COP #$FF
#define		_ADMIN(a)		LDX #a:	JSL adm16_call
#endif

; * C816 routines ending in RTI and redefined EXIT_OK and ERR endings!
; * C02 wrapper then should be like			COP #$FF	RTS
; * C816 firmware routines ending in RTL, see wrapper for 02 tasks above!

; new macro for filesystem calling, no specific kernel entries! 20150305, new offset 20150603
; ** revise for 816 systems ****
#define		_FILESYS(a)		STY locals+11: LDA #a: STA zpar: LDY #FILE_DEV: _KERNEL(COUT)

; *** function endings ***
; * due to implicit PHP on COP, these should be heavily revised for 65816
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

; new exit for asynchronous driver routines when not satisfied 20150320, renamed 20150929
#define		_NEXT_ISR	SEC: RTS
#define		_ISR_DONE	CLC: RTS
; can no longer use EXIT_OK because of 65816 reimplementation!!! check drivers!

; new macros for critical sections, do not just rely on SEI/CLI 20160119
#define		_ENTER_CS	PHP: SEI
#define		_EXIT_CS	PLP

; ** interrupt enable/disable calls, just in case **
#define		_SEI		SEI
; otherwise call SU_SEI function
#define		_CLI		CLI
; otherwise call SU_CLI function, not really needed on 65xx 

; ** panic call, pretty much the same jump to standard address, could be far in case of 65816 **
#ifndef	C816
#define		_PANIC		JMP panic
#else
#define		_PANIC		JML panic
#endif

; *** conditional opcode assembly ***
#ifdef	NMOS
#define		_JMPX(a)	LDA a+1, X: PHA: LDA a, X: PHA: PHP: RTI
; other emulation, 20 clocks instead of 23 but 13 bytes instead of 10 and takes sysptr
; LDA a, X	STA sysptr	LDA a+1, X	STA sysptr+1	JMP (sysptr)
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
; new instructions 20150606, implemented from www.6502.org/tutorials/65c02opcodes.html
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
