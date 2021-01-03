; SDd SRAM-tester (up to 512Kx8)
; (c) 2013-2021 Carlos J. Santisteban
; version 1.0, 65C02
; last modified 20130202

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

* = $FF80		; last 128 bytes
start:
; initialize some stuff

STZ	_VIA+_ddrb	; PB as input, so far
STZ	_VIA+_iora	; first byte, don't pulse out the 4040
LDA	#$FF	; all bits output
STA	_VIA+_ddra	; PA as address output
STA	_VIA+_pcr	; $FF here is CA2=CB2=1, CA1 & CB1 as positive edge
STZ	_VIA+_acr	; no PB7, no SR, no handshake

; the algorithm itself

STA	_VIA+_t1ll	; counter LSB, currently $FF
LDA	#7		; counter MSB for 512 KB 
STA	_VIA+_t1lh	; but don't start counting...
LDA	#$AA		; initial pattern

pat:
STA	_VIA+_iorb	; set data bus
DEC	_VIA+_ddrb	; output byte
LDX	#%11011111	; CB2 goes 0
STX	_VIA+_pcr	; CB2 = ¬WE
LDX	#$FF		; back to 1
STX	_VIA+_pcr	; ¬WE has been pulsed low
STZ	_VIA+_ddrb	; prepare to read
LDX	#%11111101	; CA2 goes 0
STX	_VIA+_pcr	; CA2 = ¬OE
CMP	_VIA+_iorb	; compare stored byte with pattern
BNE	error		; something went wrong!
LDX	#$FF		; back to 1
STX	_VIA+_pcr	; negate OE, no longer reads
EOR	#$FF		; shift pattern
BPL	pat		; try once more

INC	_VIA+_iora	; next byte
BNE	pat		; do check if no boundary crossed
DEC	_VIA+_t1ll	; another page
BNE	pat
DEC	_VIA+_t1lh	; MSB
BNE	pat		; until the end (512 KiB)

lock:
BRA	lock		; test ended OK, LED at Q12 shoud be lit

error:
LDX	#$FF		; let's disable RAM, just in case
STX	_VIA+_pcr	; CB2 = ¬WE, CA2 = ¬OE

flash:
STZ	_VIA+_iora	; zeroes
NOP			; not a very short pulse
DEC	_VIA+_iora	; pulse out PA7
LDX	#0		; 256 loops
delay:
DEX
BNE	delay
BRA	flash		; blinking forever

; emergency interrupt routine...
return:	RTI		; return from non-existing ISR

; 6502 vectors
* = $FFFA

.word	return		; no NMI
.word	start		; code address
.word	return		; no IRQ/BRK
