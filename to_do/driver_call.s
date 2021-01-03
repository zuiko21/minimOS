; (c) 2020-2021 Carlos J. Santisteban
; Y = device ID
	TYA
	BPL log_dev		; it's a logical device, don't check any drivers yet
	ASL				; twice the number for address, forget the leading 1
	TAX				; indexed addressing, table in ROM (see alternative below)
	LDA dr_tab, X	; get driver block LSB
	STA sysptr		; get ready for indirect post-indexed addressing
	INX
	LDA dr_tab, X	; get driver block MSB
	STA sysptr+1
;	TAY					; indirect post-indexed addressing, in case the table is in RAM
;	LDA (dr_t_ptr), Y	; get driver block LSB
;	STA sysptr			; get ready for indirect post-indexed addressing
;	INY
;	LDA (dr_t_ptr), Y	; get driver block MSB
;	STA sysptr+1
	LDY #D_COUT+1	; get whatever routine MSB first! (2)
	LDA (sysptr), Y	; (5) if static address, could be LDX, Y with no TAX after, saving 3 cycles
	TAX				; store it for a moment (2)
	DEY				; down to LSB (2)
	LDA (sysptr), Y	; (5)
	PHX				; (3) put pseudo-return address on the stack, MSB first, hard to make with NMOS! (TAY:TXA:PHA:TYA)
	PHA				; (3) put pseudo-return address on the stack, LSB last
	PHP				; (3) much easier to use RTI
	RTI				; (6) jump there! TOTAL = 31 cycles, 12 bytes
;	LDY #D_COUT+1	; get whatever routine MSB first! (2) WORSE ALTERNATIVE, SEE ABOVE
;	LDA (sysptr), Y	; (5)
;	TAX				; store it for a moment (2)
;	DEY				; down to LSB (2)
;	LDA (sysptr), Y	; (5)
;	DEC				; RTS expects address-1 (2)
;	CMP #$FF		; unfortunately, no C affected by DEC (2)
;	BNE	ret_no_b	; nothing to correct (3/2)
;	DEX				; in case of page boundary crossing (2)
ret_no_b:
;	PHX				; (3) put pseudo-return address on the stack, MSB first, hard to make with NMOS! (TAY:TXA:PHA:TYA)
;	PHA				; (3) put pseudo-return address on the stack, LSB last
;	RTS				; (6) jump there! This version is 35/36 cycles, 17 bytes
log_dev:
; *** code for logical devices ***
