; (c) 2023 Carlos J. Santisteban
; A=veces, X=ciclos (idealmente par, X*Y ~constante), Y=período (mejor no demasiado pequeño)
tocar:
	STA temp
	SEI
	TYA
long:
			TAY				; (2)
ciclo:
; posible retardo extra aquí
				DEY			; (2)
				BNE ciclo	; (3) bucle interior, i=5*Y-1
			DEX				; (2)
			STX $DFB0		; (4)
			BNE long		; (3) total bucle exterior, (11+i)*X-1
		DEC temp
		BNE long			; el tiempo de arriba será ~ constante, multiplicado por el valor original de A
	CLI
	RTS

; ejemplo de uso:
	LDY #nota				; índice de escala cromática
	LDA per, Y				; período base de esa nota
	LDX cic, Y				; número de ciclos para duración constante
	TAY
	LDA #duracion			; normalmente potencias de dos
	JSR tocar
; ...resto del código

; *** tablas de notas ***
per:
;			C	C#	D	D#	E	F	F#	G	G#	A	A#	B
	.byt				247,233,220,208,196,185,175,165,155; octava 5
	.byt	147,139,131,123,116,110,104, 98, 92, 87, 82, 78; octava 6
	.byt	 73, 69, 65, 62, 58, 55, 52, 49, 46, 44, 41, 39; octava 7
	.byt	 37, 35, 33, 31, 29, 27, 26, 24, 23, 22, 21, 19; octava 8 (dudosa)

; *** compensación de duraciones *** producto ~4800, cada nota dura ~16 ms
cic:
;			C	C#	D	D#	E	F	F#	G	G#	A	A#	B
	.byt				 19, 21, 22, 23, 24, 26, 27, 29, 31; octava 5
	.byt	 33, 35, 37, 39, 41, 44, 46, 49, 52, 55, 58, 62; octava 6
	.byt	 65, 69, 73, 78, 82, 87, 92, 98,104,110,116,123; octava 7
	.byt	131,139,147,155,165,175,185,196,208,220,223,247; octava 8

; duración notas (para negra~120/minuto)
; redonda	= 128
; blanca	= 64
; negra		= 32
; corchea	= 16
; semicor.	= 8
; fusa		= 4
; semifusa	= 2
