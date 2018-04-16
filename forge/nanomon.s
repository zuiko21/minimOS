; minimOS nano-monitor
; v0.1a2
; (c) 2018 Carlos J. Santisteban
; last modified 20180416-1008

; *** stub as NMI handler ***
; (aaaa=4 hex char on stack, dd=2 hex char on stack)
; aaaa,		read byte into stack
; ddaaaa!	write byte
; aaaa$		hex dump
; +		continue hex dump
; aaaa"		ASCII dump
; -		continue ASCII dump
; dd/		pop and show in hex
; dd.		pop and show in ASCII
; aaaa&		call address
; aaaa*		jump to address
; %		show regs
; dd(		set X
; dd)		set Y
; dd#		set A
; dd'		set P

#ifndef	HEADERS
#include "../OS/options.h"
#include "../OS/macros.h"
#include "../OS/abi.h"
#include "../OS/zeropage.h"
.text
* = $8000
#endif

; **********************
; *** zeropage usage ***
; **********************
	z_acc	= locals	; try to use kernel parameter space
	z_x		= z_acc+1	; must respect register order
	z_y		= z_x+1
	z_psr	= z_y+1		; if a loop is needed, put z_addr immediately after this
	z_cur	= z_psr+1
	z_sp	= z_cur+1
	z_addr	= z_sp+1
	z_dat	= z_addr+2
	z_tmp	= z_dat+1
	buff	= z_tmp+1
	stack	= $100

; ******************
; *** init stuff ***
; ******************

	JSR njs_regs		; keep current state, is PSR ok?
; ** procedure for storing PC & PSR values at interrupt time ** 16b, not worth going 15b with a loop
	TSX
	LDA $101, X			; get stacked PSR
	STA z_psr			; update value
	LDY $102, X			; get stacked PC
	LDA $103, X
	STY z_addr			; update current pointer
	STA z_addr+1
; ** remove code above if not needed **
	_STZA z_sp			; reset data stack pointer
; main loop
nm_main:
		JSR nm_read			; get line
nm_eval:
			LDX z_cur
			LDA buff, X			; get one char
				BEQ nm_main			; if EOL, ask again
; current nm_read rejects whitespace altogether
;			CMP #' '			; whitespace?
;				BCC nm_next			; ignore
			CMP #'0'			; is it a number?
			BCS nm_num			; push its value
				JSR nm_exe			; otherwise it is a command
				_BRA nm_next		; do not process number in this case
; ** pick a hex number and push it into stack**
nm_num:
			JSR nm_hx2n			; convert from hex and keep nibble in z_dat
			INC z_cur
			LDX z_cur			; eeeeeeeeeeeeeeeeeeeeeeeeeek
			LDA buff, X			; pick next hex
;				BEQ nm_main			; must be in pairs! would be catastrophic at the very end!
			JSR nm_hx2n			; convert another nibble (over the previous one)
;			LDA z_dat			; get fully converted byte... (already in A)
			JSR nm_push			; ...pushed into data stack
nm_next:
; read next char in input and proceed
			INC z_cur			; go for next
			BNE nm_eval			; no need for BRA

; ** indexed jump to command routine (must be called from main loop) **
nm_exe:
	ASL					; convert to index
	TAX
	_JMPX(nm_cmds)		; *** execute command ***


; **************************
; *** command jump table ***
; **************************
nm_cmds:
	.word	nm_poke			; ddaaaa!	write byte
	.word	nm_asc			; aaaa"		ASCII dump
	.word	nm_acc			; dd#		set A
	.word	nm_hex			; aaaa$		hex dump
	.word	nm_regs			; %		view regs
	.word	nm_jsr			; aaaa&		call
	.word	nm_psr			; dd'		set P
	.word	nm_ix			; dd(		set X
	.word	nm_iy			; dd)		set Y
	.word	nm_jmp			; aaaa*		jump
	.word	nm_dump			; +		continue hex dump
	.word	nm_peek			; aaaa,		read byte and push
	.word	nm_admp			; -		continue ASCII dump
	.word	nm_apop			; dd.		show in ASCII
	.word	nm_hpop			; dd/		show in hex

; ************************
; *** command routines ***
; ************************
nm_poke:
; * poke value in memory *
	JSR nm_gaddr
	JSR nm_pop
	_STAY(z_addr)
	RTS

nm_peek:
; * peek value from memory and put it on stack *
	JSR nm_gaddr
	_LDAY(z_addr)
	JMP nm_push				; push... and return

nm_asc:
; * 16-char ASCII dump from address on stack *
; note common code with hex dump
	JSR nm_gaddr
nm_admp:
; * continue ASCII dump *
	LDY #16				; number of bytes
	LDA #255			; this (negative) means ASCII dump
	BNE nd_reset		; common routine, was not zero anyway, no need for BRA

nm_hex:
; * 8-byte hex dump from address on stack *
; alternate version 35+9b (was 30+21b)
	JSR nm_gaddr
nm_dump:
; * continue hex dump *
	LDY #8				; number of bytes
	TYA					; this (positive) means HEX dump
nd_reset:
	STY z_tmp			; stored as counter
	STA z_dat			; stored as flag (negative means ASCII dump)
nhd_loop:
		_LDAY(z_addr)		; get byte from mutable pointer
		BIT z_dat			; check dump type
		BPL nhd_do			; positive means HEX dump
			JSR nm_out			; otherwise is ASCII
			_BRA nd_done		; go for next
nhd_do:
		JSR nm_shex
nd_done:
		INC z_addr			; update pointer
		BNE nhd_nc
			INC z_addr+1
nhd_nc:
		DEC z_tmp			; one less to go
		BNE nhd_loop
	RTS

nm_regs:
; * show register values *
; format a$$ X$$ Y$$ P$$
; alternate attempt is 23+1b (instead of 55+1) if nm_out respects X!
; added 6b as X saved in z_dat
; saved 2 bytes going backwards
	LDX #3				; max offset
nmv_loop:
		STX z_dat			; just in case
		LDA nm_lab, X		; get label from list
		JSR nm_out
		LDX z_dat			; just in case
		LDA z_acc, X		; get register value, must match order!
		JSR nm_shex			; show in hex
		LDA #' '			; put a space between registers
		JSR nm_out
		LDX z_dat			; just in case
		DEX					; go back for next
		BPL nmv_loop		; zero will be last
	RTS
nm_lab:
	.asc	"aXYp"		; register labels, will be printed in reverse!

nm_acc:
; * set A *
; alternate 9+3x4=21b (these were 4x6=24b)
	LDY #0
nm_rgst:
	JSR nm_pop
; use this instead of ABSOLUTE Y-indexed, non 65816-savvy! (same bytes, bit slower but 816-compliant)
	TAX
	STX z_acc, Y
	RTS

nm_ix:
; * set X *
	LDY #z_x-z_acc		; non-constant, safe way
	BNE nm_rgst			; common code

nm_iy:
; * set Y *
	LDY #z_y-z_acc		; non-constant, safe way
	BNE nm_rgst			; common code

nm_psr:
; * set P *
	LDY #z_psr-z_acc	; non-constant, safe way
	BNE nm_rgst			; common code

nm_jsr:
; * call address on stack *
	JSR nm_jmp			; jump as usual, hopefully will return here
njs_regs:
; restore register values
	PHP					; flags are delicate and cannot be directly STored
	STA z_acc
	STX z_x
	STY z_y
	PLA					; this was the saved status reg
	STA z_psr
	RTS

nm_jmp:
; * jump to address on stack *
	JSR nm_gaddr		; pick desired address
; preload registers
	LDA z_psr
	PHA					; P cannot be directly LoaDed, thus push it
	LDA z_acc
	LDX z_x
	LDY z_y
	PLP					; just before jumping, set flags
	JMP (z_addr)		; go! not sure if it will ever return...

nm_apop:
; * pop value and show in ASCII *
	JSR nm_pop
	JMP nm_out			; print... and return

nm_hpop:
; * pop value and show in hex *
	JSR nm_pop
	JMP nm_shex			; print hex... and return

; ***********************
; *** useful routines ***
; ***********************
nm_gaddr:
; * pop 16-bit address in z_addr *
	JSR nm_pop			; will pop LSB first
	STA z_addr
	JSR nm_pop			; then goes MSB
	STA z_addr+1
	RTS

nm_pop:
; * pop 8-bit data in A *
	DEC z_sp			; pre-decrement index
	LDX z_sp
	LDA stack, X
	RTS

nm_push:
; * push A into stack *
	LDX z_sp
	INC z_sp			; post-increment index
	STA stack, X
	RTS

nm_shex:
; * show A value in hex *
	PHA					; keep whole value for later LSNibble
; extract MSNibble
	LSR
	LSR
	LSR
	LSR
	JSR nm_hprn			; print this in hex
; now retrieve LSNibble
	PLA
	AND #$0F			; clear MSNibble bits
nm_hprn:
; print A value as a hex digit
	CMP #10				; should it use a letter?
	BCC nm_sdec
		ADC #6				; as C was set, this will skip ASCII 58 to 65, and so on
nm_sdec:
; convert to ASCII
	ADC #'0'			; C is clear for sure
	JMP nm_out			; print it... and return

nm_out:
; *** standard output ***
; placeholder for run816 emulation
	JSR $c0c2
	RTS

nm_in:
; *** standard input ***
; placeholder for run816 emulation
		JSR $c0bf
		CMP #0				; something arrived?
		BEQ nm_in			; it is locking input
	RTS

nm_read:
; * input command line into buffer *
; good to put some prompt before
	LDA z_addr+1		; PC.MSB
	JSR nm_shex			; as hex
	LDA z_addr			; same for LSB
	JSR nm_shex
	LDA #'>'			; prompt sign
	JSR nm_out
	LDX #0				; reset cursor
nr_loop:
		STX z_cur			; keep in memory, just in case
nl_ign:
		JSR nm_in
		CMP #CR				; is it newline?
			BEQ nl_end			; if so, just end input
		CMP #BS				; was it backspace?
			BEQ nl_bs			; delete then
		CMP #' '			; whitespace?
			BCC nl_ign			; simply ignore it!
		PHA					; save what was received...
		JSR nm_out			; ...in case it gets affected
		PLA
		LDX z_cur			; retrieve cursor
; could check bounds here
		STA buff, X			; store char in buffer
		INX					; go for next (no need for BRA)
		BNE nr_loop
nl_end:
	JSR nm_out			; must echo CR
	LDX z_cur			; retrieve cursor as usual
	_STZA buff, X		; terminate string!
	_STZA z_cur			; and reset cursor too
	RTS
nl_bs:
	JSR nm_out			; will echo BS
	LDX z_cur			; retrieve cursor as usual
		BEQ nr_loop			; do not delete if already at beginning
	DEX					; otherwise go back once
	_BRA nr_loop

nm_hx2n:
; * convert from hex and ADD nibble to z_dat *
	ASL z_dat			; old value times 16 (A will be low nibble now)
	ASL z_dat
	ASL z_dat
	ASL z_dat
	SEC
	SBC #'0'			; convert from ASCII to value (with a skip over 10)
	CMP #10				; was it a letter?
	BCC nm_dec			; no, just store it
		SBC #'A'-'9'-1		; yes, make it 10...15 (C was set)
nm_dec:
	ORA z_dat			; add this nibble to older MSNibble (lower bits are clear)
	STA z_dat			; ready to go (and full result in A, too)
	RTS

