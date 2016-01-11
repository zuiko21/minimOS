; minimOS 0.4a2 MACRO definitions
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.26

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
	#define _INC		CLC: ADC #1	; unused this far
	#define _DEC		SEC: SBC #1	; unused this far
#else
	#define _JMPX(a)	JMP a, X
	#define _PHX		PHX
	#define _PHY		PHY
	#define _PLX		PLX
	#define _PLY		PLY
	#define _STAX(a)	STA (a)
	#define _LDAX(a)	LDA (a)
	#define _INC		INC
	#define _DEC		DEC
#endif

; include here the old 'io_dev.h'

; VIA 65(C)22 registers
#ifdef	SDd
	#define	_VIA	$6FF0		; for SDd
#else
	#define _VIA	$DFF0		; SDx, Baja...
#endif

iorb	= _VIA		; all from previously defined base
iora	= _VIA + 1
ddrb	= _VIA + 2
ddra	= _VIA + 3
t1cl	= _VIA + 4
t1ch	= _VIA + 5
t1ll	= _VIA + 6
t1lh	= _VIA + 7
t2cl	= _VIA + 8
t2ch	= _VIA + 9
sr	= _VIA + 10
acr	= _VIA + 11
pcr	= _VIA + 12
ifr	= _VIA + 13
ier	= _VIA + 14
nhra	= _VIA + 15	; IRA/ORA without handshake
