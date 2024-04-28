; ROM video signal generation
; d0 = /SYNC
; d1 = VIDEO/ENABLE
; d2 = RESET (@ 9984)
; d3...d7 = 1
; 500 kHz clock (32 bytes/line)
; using 50µs window (8µs back porch, 2µs front porch)
; normal sync is 2 bytes (4 µs), short is one

#define	S	%11111000
#define	P	%11111001
#define	E	%11111011
#define	R	%11111101

* = 0

; COMPOUND VERTICAL SYNC
	.byt	S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P
	.byt	S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P
	.byt	S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P,S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P
	.byt	S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P
	.byt	S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P
; ONE BLANK LINE (6)
	.byt	S,S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P
; ONE PARTIAL LINE (7)
	.byt	S,S,P,P,P,P,E,E,P,P,P,P,P,P,P,P,P,P,E,P,P,P,P,P,P,P,P,P,P,E,E,P
; ACTIVE LINE (8-9)
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 10-19
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 20-29
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 30-39
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 40-49
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 50-59
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 60-69
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 70-79
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 80-89
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 90-99
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 100-109
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 110-119
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 120-129
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 130-139
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 140-149
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 150-159
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 160-169
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 170-179
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 180-189
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 190-199
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 200-209
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 210-219
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 220-229
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 230-239
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 240-249
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 250-259
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 260-269
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 270-279
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 280-289
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 290-299
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; REPEAT ABOVE 300-307
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
	.byt	S,S,P,P,P,P,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,E,P
; ONE PARTIAL LINE (308)
	.byt	S,S,P,P,P,P,E,E,P,P,P,P,P,P,P,P,P,P,E,P,P,P,P,P,P,P,P,P,P,E,E,P
; ONE BLANK LINE (309)
	.byt	S,S,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P
; EQUALISATION PULSES (310-312)
	.byt	S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P
	.byt	S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P
	.byt	S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,P
; RESET PULSE
	.byt	R
