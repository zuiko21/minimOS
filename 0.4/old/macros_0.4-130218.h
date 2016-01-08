; minimOS 0.4b2 MACRO definitions
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.18

; initial macros dec-05-2012
#define _EXIT_OK	CLC: RTS
#define _ERR(a)		LDY #a: SEC: RTS
#define _KERNEL(a)	LDX #a: JSR k_call

; *** this _JMPX is NOT for CBM64/6510, changed dec-26 ***
#ifdef	NMOS
#define _JMPX(a)	LDA a, X: STA 0: LDA a+1, X: STA 1: JMP (0)
#define _PHX		TXA: PHA
#define _PHY		TYA: PHA
#define _PLX		PHA: TAX
#define _PLY		PHA: TAY
#define _STAX(a)	LDX #0: STA (a, X)
#define _LDAX(a)	LDX #0: LDA (a, X)
#define _INC		CLC: ADC #1
#define _DEC		SEC: SBC #1	; unused this far
#define _BRA		CLV:BVC
#define _STZX		LDX #0: STX	; new 20130218, at last
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
#ifdef	MTE
#define _SRAM	1		; need mirroring for the stack, but has 128 bytes only!
#else
#ifdef	SDd
#define	_SRAM	7		; 2 kiB max
#else
#define _SRAM	63		; general case, OK for SDx too, even without hAck14!
#endif
#endif

; initial stack pointer, MTE has 128-byte RAM!
#ifdef	MTE
#define _SP	$75		; for MTE
#else
#define _SP	$FF		; standard value
#endif

; include here the old 'io_dev.h'

; VIA 65(C)22 registers
#ifdef	SDd
#define	_VIA	$6FF0		; for SDd
#else
#define _VIA	$DFF0		; SDx, Baja... but not sure about MTE!
#endif

; new, all constants begin with underscore
#define _iorb	0		; NEW, offsets from base address (add when using)
#define _iora	1
#define _ddrb	2
#define _ddra	3
#define _t1cl	4
#define _t1ch	5
#define _t1ll	6
#define _t1lh	7
#define _t2cl	8
#define _t2ch	9
#define _sr	10
#define _acr	11
#define _pcr	12
#define _ifr	13
#define _ier	14
#define _nhra	15		; IRA/ORA without handshake
