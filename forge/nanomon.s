; minimOS nano-monitor
; v0.1a1
; (c) 2018 Carlos J. Santisteban
; last modified 20180415-0907

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
		LDY #0				; reset index
nm_eval:
			LDA buff, Y			; one char
				BEQ nm_main			; EOL
			CMP #' '			; whitespace?
				BCC nm_next			; ignore
			CMP #'0'			; not even number?
			BCC nm_pun			; is command
				JSR nm_num			; or push value into stack

nm_pun:
			ASL				; convert to index
			TAX
			_JMPX(nm_cmds)			; execute command
nm_next:
			INY				; go for next
			BNE nm_eval			; no need for BRA


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
	.word	nm_popa			; dd.	show in ASCII
	.word	nm_poph			; dd/	show in hex

; *** command routines ***
nm_poke:
	JSR nm_pop
	STA z_dat
	JSR nm_pop
	STA z_adr+1
	JSR nm_pop
	STA z_adr
	LDA z_dat
	_STAY(z_adr)

nm_asc:
nm_acc:
nm_hex:
nm_regs:
nm_jsr:
	JSR nm_jmp
nm_psr:
nm_ix:
nm_iy:
nm_jmp:
nm_dump:
nm_peek:
nm_admp:
nm_popa:
nm_poph:

;************
			CMP #'9'+1			; decimal number?
				BCC nm_dec			; 0...9, no hex
; here must be hex number, carry is set
			SBC #65-58			; A...F turns into 10...15, +C
nm_dec:
			SEC
			SBC #'0'			; convert decimal char into value

