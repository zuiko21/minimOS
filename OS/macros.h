; minimOS 0.5a11 MACRO definitions
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160919

; *** standard addresses ***
; redefined as labels 20150603
; revamped 20160308
; proper 816 support 20160919

kernel_call	=	$FFC0	; ending in RTS, 816 will use COP handler and a COP,RTS wrapper for 02
admin_call	=	$FFD8	; ending in RTS, no way to use a PHK wrapper eeeeeeek! JSL adm16_call & RTS instead
adm16_call	=	$FFD0 ; ending in RTL, might push P for mode preservation

; unified address (will lock at $FFEE-F anyway) for CMOS and NMOS, new 20150410
panic		=	$FFE0	; more-or-less 816 savvy address, new 20160308

; *** device numbers for optional pseudo-driver modules, TBD ***
; renamed as labels 20150603
TASK_DEV	=	128
WIN_DEV		=	129
FILE_DEV	=	130

; *** common function calls ***

; system calling interface
#define		_KERNEL(a)		LDX #a: JSR kernel_call
#define		_KERN16(a)		LDX #a: COP #0
; * C816 routines ending in RTI and redefined EXIT_OK and ERR endings!
; * C02 wrapper then should be like			KERNEL(a)		COP #0	RTS

; new primitive for administrative meta-kernel in firmware 20150118
#define		_ADMIN(a)		LDX #a: JSR admin_call
#define		_ADM16(a)		LDX #a	JSL adm16_call
; * C816 routines ending in RTL, see wrapper for 02 tasks above!

; new macro for filesystem calling, no specific kernel entries! 20150305, new offset 20150603
#define		_FILESYS(a)		STY locals+11: LDA #a: STA zpar: LDY #FILE_DEV: _KERNEL(COUT)

; *** function endings ***
; * due to implicit PHP on COP, these should be heavily revised for C816
#define		_EXIT_OK	CLC: RTS
#define		_ERR(a)		LDY #a: SEC: RTS

; makeshift 816 versions
#define		_OK_16		PLP: CLC: PHP: RTI
#define		_ERR16(a)	LDY #a: PLP: SEC: PHP: RTI

; new exit for asynchronous driver routines when not satisfied 20150320, renamed 20150929
#define		_NEXT_ISR	SEC: RTS

; new macros for critical sections, do not just rely on SEI/CLI 20160119
#define		_ENTER_CS	PHP: SEI
#define		_EXIT_CS	PLP

; ** interrupt enable/disable calls, just in case **
#define		_SEI		SEI
; otherwise call SU_SEI function
#define		_CLI		CLI
; otherwise call SU_CLI function, not really needed on 65xx 

#define		_PANIC		JMP panic
#define		_PANIC16	JMP panic

; standardised NMI exit 20150409 *** DEPRECATED 20160308

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
