; ejecucion drivers
; escrito el 20141001
; (c) 2014-2020 Carlos J. Santisteban
	LDX #0
bucle:
		PHX
		JSR salto
		PLX
		INX
		INX
		CPX #limite
		BMI bucle
	
	
salto:
	LDA #>vector
	ROL
	BCS no_neg
		EOR #$80
no_neg:
	BPL user		;ejecución en espacio usuario
	
; menos robusto pero más rápido
	LDA #>vector
	ROL
	BCC kernel
	BPL user
kernel:
	JMP (tabla,X)
user:
; bankswitch***


; *** escrito 20141006 ***

	LDX n_dr2
	BEQ end
loop:
		DEX
		PHX
		JSR salto
		PLX
		DEX
		BNE loop
end:
; ***
salto:
	LDA tabla, X	; corrección 20150124?
	ROL
	BCC kern
	BPL usr
kern:
	DEX
	JMP (tabla, X)
; ...


; *** fork
	LDY #max_braid
_1:
	LDA flags,X
	CMP #free
	BEQ _2
	DEX
	BPL _1
	SEC
	LDY #not_enough
	RTS
_2:
	LDA #pause
	STA flags,X
	STX zpar	;?
	CLC
	RTS

; *** version 141006
	LDX #2
	LDY pid
	SEI
_1	INY
	CPY #max_braid+1
	BNE _2
	LDY #0
	DEX
	BEQ _3
_2	LDA flags, Y
	CMP #free
	BNE _1
	LDA #pause
	STA flags, Y
	CLI
	STY zpar ;?
	CLC
	RTS
_3	LDY #not_avail
	SEC
	RTS

; *** exec ???
; *** escrito 141015
;	JSR...
	LDX #0
	PLA
	STA (sp), Y
; (abarca un * aquí)
	CLC
	DEC sp
	BCC _1
	DEC sp+1
; (fin *)
_1	PLA
	STA (sp).Y
; * asterisco *
	JMP (z_ptr)
	
;	"RTS"
; (otro * empieza)
	CLC
	INC sp
	BCC _2
	INC sp+1
; (fin *)
_2	LDA (sp)
	PHA
; * asterisco *
	LDA (sp)
	PHa
	RTS
	
