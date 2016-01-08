; minimOS 0.4a2 I/O devices - SDx, 6502
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.05

; VIA 65(C)22 registers
#define	_VIA	$DFF0		; $6FF0 for SDd

iorb	= _VIA	; all from previously defined base
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
