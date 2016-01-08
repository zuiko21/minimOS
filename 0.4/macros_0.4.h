; minimOS 0.4b3 MACRO definitions
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.05.04

; initial macros dec-05-2012
; ***** NO COMMENTS AFTER #DEFINES *****
#define _EXIT_OK	CLC: RTS
#define _ERR(a)		LDY #a: SEC: RTS
#define _KERNEL(a)	LDX #a: JSR k_call

; *** this _JMPX is OK for CBM64/6510, changed may-04 ***
; STZs are new 20130218, at last
#ifdef	NMOS
#define _JMPX(a)	LDA a, X: STA sysptr: LDA a+1, X: STA sysptr+1: JMP (sysptr)
#define _PHX		TXA: PHA
#define _PHY		TYA: PHA
#define _PLX		PHA: TAX
#define _PLY		PHA: TAY
#define _STAX(a)	LDX #0: STA (a, X)
#define _LDAX(a)	LDX #0: LDA (a, X)
#define _INC		CLC: ADC #1
#define _DEC		SEC: SBC #1
#define _BRA		CLV:BVC
#define _STZX		LDX #0: STX
#define _STZY		LDY #0: STY
#define _STZA		LDA #0: STA
#else
#define _JMPX(a)	JMP (a, X)
#define _PHX		PHX
#define _PHY		PHY
#define _PLX		PLX
#define _PLY		PLY
#define _STAX(a)	STA (a)
#define _LDAX(a)	LDA (a)
#define _INC		INC
#define _DEC		DEC
#define _BRA		BRA
#define _STZX		STZ
#define _STZY		STZ
#define _STZA		STZ
#endif

; highest SRAM page, just in case of mirroring/bus error
; MTE needs mirroring for the stack, but it has just 128 bytes!
; SDd has 2 kiB max
; 63 pages (16 kiB) is the general case, OK for SDx too, even without hAck14!
#ifdef	MTE
#define _SRAM	1		
#else
#ifdef	SDd
#define	_SRAM	7
#else
#define _SRAM	63
#endif
#endif

; initial stack pointer, MTE has 128-byte RAM!
; MTE starts at $75 (or two less???), $FF otherwise
#ifdef	MTE
#define _SP	$75
#else
#define _SP	$FF
#endif

; include here the old 'io_dev.h'

; VIA 65(C)22 registers
; base address is $6FF0 for SDd, $DFF0 for most others... and MTE?
; should numeric constants be all caps with no underscore (reserved for macros)?
#ifdef	SDd
#define	_VIA	$6FF0
#else
#define _VIA	$DFF0
#endif

; NEW, offsets from base address (add when using)
; new, all constants begin with underscore... written in HEX and NO COMMENTS after!
; should numeric constants be all caps with no underscore (reserved for macros)?
#define _iorb	$0
#define _iora	$1
#define _ddrb	$2
#define _ddra	$3
#define _t1cl	$4
#define _t1ch	$5
#define _t1ll	$6
#define _t1lh	$7
#define _t2cl	$8
#define _t2ch	$9
#define _sr		$A
#define _acr	$B
#define _pcr	$C
#define _ifr	$D
#define _ier	$E
#define _nhra	$F
; _nhra = IRA/ORA without handshake
