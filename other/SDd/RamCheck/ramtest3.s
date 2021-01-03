; SDd SRAM-tester (up to 512Kx8)
; (c) 2013-2021 Carlos J. Santisteban
; version 1.0b3, 65C02
; last modified 20130205

#define	_VIA	$6FF0

#define	_iorb	0
#define _iora	1
#define	_ddrb	2
#define	_ddra	3
#define	_t1cl	4
#define	_t1ch	5
#define	_t1ll	6
#define	_t1lh	7
#define	_t2cl	8
#define	_t2ch	9
#define	_sr	10
#define	_acr	11
#define	_pcr	12
#define	_ifr	13
#define	_ier	14
#define	_nhra	15

* = $FE00		; next 256 bytes before last
start:
; initialize some stuff

STZ	_VIA+_iora	; first byte, don't pulse out the 4040
LDA	#$FF		; all bits output
STA	_VIA+_ddra	; PA as address output
STZ	_VIA+_ddrb	; PB as input, so far
TAY			; keep $FF somewhere
LDA	#$7F		; disable all interrupt sources
STA	_VIA+_ier
LDA	#%11101110	; CA2=CB2=1, CA1 & CB1 as negative edge
STA	_VIA+_pcr	; no interrupts should be triggered
STZ	_VIA+_acr	; no PB7 toggle, no SR, no handshake

; the algorithm itself

STZ	0	;_VIA+_t1ll	; reset T1 counter latches...
STZ	1	;_VIA+_t1lh	; ...but don't start counting
LDA	#$AA		; initial pattern

pat:
STA	_VIA+_iorb	; set data bus
STY	_VIA+_ddrb	; output byte
LDX	#%11001110	; CB2 goes 0
STX	_VIA+_pcr	; CB2 = ¬WE
JSR	wait		; not so fast... just in case!
LDX	#%11101110	; beware!!! Only CB2 goes back to 1
STX	_VIA+_pcr	; ¬WE has been pulsed low
STZ	_VIA+_ddrb	; prepare to read
LDX	#%11101100	; CA2 goes 0
STX	_VIA+_pcr	; CA2 = ¬OE
JSR	wait		; let the bits settle...
CMP	_VIA+_iorb	; compare stored byte with pattern
BNE	error		; something went wrong!
LDX	#%11101110	; beware!!! Only CA2 goes back to 1
STX	_VIA+_pcr	; negate OE, no longer reads
EOR	#$FF		; shift pattern
BPL	pat		; try once more

INC	_VIA+_iora	; next byte
BNE	pat		; do check if no boundary crossed
INC	0	;_VIA+_t1ll	; another page
BNE	pat
INC	1	;_VIA+_t1lh	; MSB
LDA	#8		; for 512 KiB
CMP	1	;_VIA+_t1lh	; check limit
BNE	pat		; until the end (512 KiB)

lock:
BRA	lock		; test ended OK, LED at Q12 shoud be lit

error:
LDX	#%11101110	; disable RAM
STX	_VIA+_pcr	; CB2 = ¬WE, CA2 = ¬OE

flash:
STZ	_VIA+_iora	; zeroes
JSR	wait		; not a very short pulse
STY	_VIA+_iora	; pulse out PA7
LDX	#63		; delay loops
delay:
DEX
BNE	delay
BRA	flash		; blinking forever

wait:	RTS		; lose some time

; 6502 vectors
* = $FFFA

.word	$FFFF		; no NMI
.word	start		; code address
.word	$FFFF		; no IRQ/BRK
