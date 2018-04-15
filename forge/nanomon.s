; minimOS nano-monitor
; v0.1a1
; (c) 2018 Carlos J. Santisteban
; last modified 20180415-1330

; *** stub as NMI handler ***
; aaaa,		read byte into stack
; ddaaaa!	write byte
; aaaa$		hex dump
; +		continue hex dump
; aaaa"		ASCII dump
; -		continue ASCII dump
; /		pop and show in hex
; .		pop and show in ASCII
; aaaa&		call address
; aaaa*		jump to address
; %		show regs
; dd(		set X
; dd)		set Y
; dd#		set A
; dd'		set P

; init stuff...

; main loop
nm_main:
		JSR nm_read			; get line
nm_eval:
			LDX z_cur
			LDA buff, X			; one char
				BEQ nm_main			; EOL
			CMP #' '			; whitespace?
				BCC nm_next			; ignore
			CMP #'0'			; not even number?
			BCC nm_pun			; is command
				JSR nm_num			; or push value into stack

nm_pun:
			ASL				; convert to index
			TAX
			JSR nm_exe
nm_next:
; read next char in input and proceed
			INC z_cur			; go for next
			BNE nm_eval			; no need for BRA

nm_exe:
	_JMPX(nm_cmds)			; execute command

; *** command jump table ***
nm_cmds:
	.word	nm_poke			; ddaaaa!	write byte
	.word	nm_asc			; aaaa"	ASCII dump
	.word	nm_acc			; dd#	set A
	.word	nm_hex			; aaaa$	hex dump
	.word	nm_regs			; %	view regs
	.word	nm_jsr			; aaaa&	call
	.word	nm_psr			; dd'	set P
	.word	nm_ix			; dd(	set X
	.word	nm_iy			; dd)	set Y
	.word	nm_jmp			; aaaa*	jump
	.word	nm_dump			; +	continue hex dump
	.word	nm_peek			; aaaa,	read byte and push
	.word	nm_admp			; -	continue ASCII dump
	.word	nm_apop			; dd.	show in ASCII
	.word	nm_hpop			; dd/	show in hex

; *** command routines ***
nm_poke:
; * poke value in memory *
	JSR nm_pop
	STA z_dat
	JSR nm_gaddr
	LDA z_dat
	_STAY(z_addr)
	RTS

nm_asc:
; * 16-char ASCII dump from address on stack *
	JSR nm_gaddr

	RTS

nm_acc:
; * set A *
	JSR nm_pop
	STA z_acc
	RTS

nm_hex:
; * 8-byte hex dump from address on stack *
	JSR nm_gaddr

	RTS

nm_regs:
; * show register values *
; format a$$ X$$ Y$$ P$$
; alternate attempt is 23+1b (instead of 55+1) if nm_out respects X!
; added 6b as X saved in z_dat
	LDX #0
nmv_loop:
		STX z_dat				; just in case
		LDA nm_lab, X
		JSR nm_out
		LDX z_dat				; just in case
		LDA z_acc, X
		JSR nm_shex
		LDA #' '
		JSR nm_out
		LDX z_dat				; just in case
		INX
		CPX #4
		BNE nmv_loop
	RTS
nm_lab:
	.asc	"aXYP"

nm_jsr:
; * call address on stack *
	JSR nm_jmp
; restore register values
	PHP
	STA z_acc
	STX z_x
	STY z_y
	PLA
	STA z_psr
	RTS

nm_psr:
; * set P *
	JSR nm_pop
	STA z_psr
	RTS

nm_ix:
; * set X *
	JSR nm_pop
	STA z_x
	RTS

nm_iy:
; * set Y *
	JSR nm_pop
	STA z_y
	RTS

nm_jmp:
; * jump to address on stack *
	JSR nm_gaddr
; preload registers
	LDA z_psr
	PHA
	LDA z_acc
	LDX z_x
	LDY z_y
	PLP
	JMP (z_addr)

nm_dump:
; * continue hex dump *

	RTS

nm_peek:
; * peek value from memory and put it on stack *
	JSR nm_gaddr
	_LDAY(z_addr)
	RTS

nm_admp:
; * continue ASCII dump *

	RTS

nm_apop:
; * pop value and show in ASCII *
	JSR nm_pop
	JMP nm_out				; print... and return

nm_hpop:
; * pop value and show in hex *
	JSR nm_pop
	JMP nm_shex				; print hex... and return

; *** useful routines ***
nm_gaddr:
; * pop 16-bit address in z_addr *
	JSR nm_pop
	STA z_addr+1
	JSR nm_pop
	STA z_addr
	RTS

nm_pop:
; * pop 8-bit data in A *
	DEC nm_sp
	LDX nm_sp
	LDA z_stack, X
	RTS

nm_shex:
; * show A value in hex *
	PHA
; extract MSNibble
	LSR
	LSR
	LSR
	LSR
	JSR nm_hprn
; now retrieve LSNibble
	PLA
	AND #$0F
nm_hprn:
; print A value as a hex digit
	CMP #10
	BCC nm_sdec
		ADC #6					; C was set
nm_sdec:
; convert to ASCII
	ADC #'0'					; C is clear
	JSR nm_out					; print it
	RTS

nm_pop:
nm_pop:
nm_pop:
nm_pop:
;************
			CMP #'9'+1			; decimal number?
				BCC nm_dec			; 0...9, no hex
; here must be hex number, carry is set
			SBC #65-58			; A...F turns into 10...15, +C
nm_dec:
			SEC
			SBC #'0'			; convert decimal char into value

