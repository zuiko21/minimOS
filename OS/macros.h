; minimOS 0.5a7 MACRO definitions
; (c) 2012-2015 Carlos J. Santisteban
; last modified 20151015-1111

; redefined as labels 20150603
; standard addresses, new 20150220
admin_call	=	$FFA0	; watch out for '816, maybe a wrapper at $FFA8
bankswitch	=	$FFB0	; TBD, deprecated '02 bankswitching!
kernel_call	=	$FFC0
; *** warm_start deprecated 20150602
; new definition 20150326, relocated 20150603 for adequate room
nmi_end		=	$FFD0

; unified address (will lock at $FFEE-F anyway) for CMOS and NMOS, new 20150410
panic		=	$FFED

; device numbers for optional pseudo-driver modules, TBD
; renamed as labels 20150603
TASK_DEV	=	128
WIN_DEV		=	129
FILE_DEV	=	130

; common function calls
#define		_EXIT_OK	CLC: RTS
; new exit for asynchronous driver routines when not satisfied 20150320, renamed 20150929
#define		_NEXT_ISR	SEC: RTS
#define		_ERR(a)		LDY #a: SEC: RTS
#define		_KERNEL(a)	LDX #a: JSR kernel_call
; *** C816 version should be something like		_KERN16(a)		LDX #a	COP #0
; *** C02 wrapper then should be like							COP #0	RTS
; new primitive for administrative meta-kernel in firmware 20150118
#define		_ADMIN(a)	LDX #a: JSR admin_call
; *** C816 might need a wrapper... or place a NOP after the above for automated change to JSL
; new standardised NMI exit 20150409
#define		_NMI_END	JMP nmi_end
; *** C816 might need JML
#define		_PANIC		JMP panic
; new macro for filesystem calling, no specific kernel entries! 20150305, new offset 20150603
#define		_FILESYS(a)	STY locals+11: LDA #a: STA zpar: LDY #FILE_DEV: _KERNEL(COUT)

; interrupt enable/disable calls, just in case
#define		_SEI		SEI
; otherwise call SU_SEI function
#define		_CLI		CLI
; otherwise call SU_CLI function, not really needed on 65xx 

; conditional assembly
#ifdef	NMOS
#define		_JMPX(a)	LDA a+1, X: PHA: LDA a, X: PHA: PHP: RTI
; other emulation, 20 clocks instead of 23 but 13 bytes instead of 10 and takes sysptr
;#define		_JMPX(a)	LDA a, X: STA sysptr: LDA a+1, X: STA sysptr+1: JMP (sysptr)
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
; faster than CLC:BVC and the very same size, but no longer position-independent
#define		_STZX		LDX #0: STX
#define		_STZY		LDY #0: STY
#define		_STZA		LDA #0: STA
; new instructions 20150606, implemented from <http://www.6502.org/tutorials/65c02opcodes.html>
; ...but they aren't ATOMIC!!!
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

