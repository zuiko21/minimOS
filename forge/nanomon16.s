; minimOS-16 nano-monitor
; v0.1b12
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190225-1343
; 65816-specific version

; *** NMI handler, now valid for BRK ***
; (aaaaaa=6 hex char addr on stack, wwww=4 hex char on stack, dd=2 hex char on stack)
; aaaaaa,	read byte into stack
; ddaaaaaa!	write byte
; aaaaaa$	hex dump
; +			continue hex dump
; aaaaaa"	ASCII dump
; -			continue ASCII dump
; dd.		pop and show in hex (new)
; aaaaaa&	call address
; aaaaaa*	jump to address
; %			show regs
; wwww(		set X
; wwww)		set Y
; wwww#		set A
; dd'		set P
; wwww/		set SP (new)
; NEW exit command is 'colon' character
; special command to set B or D:
; wwwwdd?	set D (16b) & B (last 8b)!

#ifndef	HEADERS
#include "../OS/macros.h"
#include "../OS/abi.h"
.text
* = $8000
#endif

.(
; ***************
; *** options ***
; ***************
; option to pick full status from standard stack frame, comment if handler not available
#define	NMI_SF	_NMI_SF

	BUFFER	= 13		; maximum buffer size, definitely needs more than the 6502 version
	STKSIZ	= 8			; maximum data stack size

; **********************
; *** zeropage usage ***
; **********************
; 16-bit registers
	z_acc	= $D8		; will try to keep within direct page
	z_x		= z_acc+2	; must respect register order
	z_y		= z_x+2
	z_s		= z_y+2		; will store system SP too
	z_d		= z_s+2		; D is 16-bit too! but not stored on NMI stack frame
; 8-bit registers
	z_b		= z_d+2		; B is 8-bit too
	z_psr	= z_b+1		; note new order as PSR is 8-bit only
; 24-bit PC
	z_addr	= z_psr+1	; this is 24-bit (PSR must be just before this!)
; internal vars
	z_cur	= z_addr+3
	z_sp	= z_cur+1	; data SP
	z_dat	= z_sp+1
	z_tmp	= z_dat+1
	buff	= z_tmp+1
	stack	= buff+BUFFER

; ******************
; *** init stuff ***
; ******************
+nanomon:
lda#'5':jsr$c0c2
; status is always saved on stack
	CLC					; make sure it is in NATIVE mode!!!
	XCE
; cannot tinker with X and SP unless saved on stack frame!
;jsr nm_regs
#ifdef	NMI_SF
; ** pick register values from standard stack frame, if needed ** current is 35 bytes
; forget about systmp/sysptr AND caller
	.al: REP #$28		; ** 16-bit memory ** clear D flag too, just in case
	TSC 				; get whole SP, could use X as well
	STA z_s				; store initial SP
; ready to save state, already in 16-bit memory (saved 2 bytes)
	LDA 8, S			; stacked Y
	STA z_y
	LDA 10, S			; stacked X
	STA z_x
	LDA 12, S			; stacked A
	STA z_acc
; should store D too, as the NMI handler does not modify neither stacks it!
	PHD					; will save Direct Page
	PLA
	STA z_d
; minimal status with new offsets (10b, was 16 plus a couple of bytes saved before)
	LDA 14, S			; get stacked PSR + PC.L
	STA z_psr			; update values
	LDA 16, S			; PC.H + K too
	STA z_addr+1
	.as: .xs: SEP #$30	; *** make sure all in 8-bit ***
; should keep stacked Data Bank register
	LDA 7, S			; stacked B
	STA z_b
#else
	JSR nm_ireg			; keep current state, but that PSR is not valid, NOTE wrapper
; time to pick values from stack!
	.al: REP #$28		; ** 16-bit memory ** clear D flag too, just in case
	TSC 				; get whole SP
	STA z_s				; store initial SP
; we are already in 16-bit, just save the bytes in consecutive pairs! (10b instead of 16, plus previous saving)
	LDA 1, S			; get stacked PSR + PC.L
	STA z_psr			; update value
	LDA 3, S			; get stacked PC.H + K
	STA z_addr+1		; update current pointer
	.as: .xs: SEP #$30	; back to 8-bit
	PHB					; saving B is generally a good idea, as will reset it
#endif
	PHK					; eeeeeeeek! must set B as NMI handler does not!
	PLB
	STZ z_sp			; reset data stack pointer
	CLD					; just in case...

; main loop
nm_main:
		JSR nm_read			; get line (could be inlined)
nm_eval:
			CLD					; worth it
			LDX z_cur
			LDA buff, X			; get one char
				BEQ nm_main			; if EOL, ask again
; current nm_read rejects whitespace altogether
; *** check new exit command first ***
			CMP #COLON			; exit command?
			BNE nm_cont			; no, just continue
; perhaps should restore registers as edited?
#ifndef	NMI_SF
				PLB					; if B was pushed, time to restore it!
				RTI					; exit debugger
#else
				RTL					; back to NMI handler eeeeeeeeeek
#endif
; *** end of exit command ***
nm_cont:
; *** check special command '?' then ***
			CMP #'?'			; was set D&B?
			BNE nm_ndb			; no...
				LDA #'0'			; ...or set special index...
				CLC					; nm_exe will subtract, expects borrow!
				BRA nm_spcm			; ...and execute
nm_ndb:
; *** continue with regular commands ***
			CMP #'0'			; is it a number?
			BCS nm_num			; push its value
nm_spcm:
				JSR nm_exe			; otherwise it is a command
				BRA nm_next		; do not process number in this case
; ** pick a hex number and push it into stack **
nm_num:
			JSR nm_hx2n			; convert from hex and keep nibble in z_dat
			INC z_cur
			LDX z_cur			; eeeeeeeeeeeeeeeeeeeeeeeeeek
			LDA buff, X			; pick next hex
#ifdef	SAFE
				BEQ nm_main			; must be in pairs! would be catastrophic at the very end!
#endif
			JSR nm_hx2n			; convert another nibble (over the previous one)
			JSR nm_push			; fully converted byte in A pushed into data stack
nm_next:
; read next char in input and proceed
			INC z_cur			; go for next
			BRA nm_eval

; ** indexed jump to command routine (must be called from main loop) **
nm_exe:
	SBC #' '			; EEEEEEEEEEEEEEK (C was clear, thus same as subtracting '!')
	ASL					; convert to index
	TAX
#ifdef	SAFE
	CPX #nm_endc-nm_cmds	; within bounds?
	BCC nm_okx		; yeah, proceed
; could complain somehow
		RTS			; quietly ignore it, otherwise
nm_okx:
#endif
	JMP (nm_cmds, X)	; *** execute command ***


; **************************
; *** command jump table ***
; **************************
nm_cmds:
	.word	nm_poke			; aaaaaa!	write byte
	.word	nm_asc			; aaaaaa"	ASCII dump
	.word	nm_acc			; wwww#		set A
	.word	nm_hex			; aaaaaa$	hex dump
	.word	nm_regs			; %			view regs
	.word	nm_jsr			; aaaaaa&	call
	.word	nm_psr			; dd'		set P
	.word	nm_ix			; wwww(		set X
	.word	nm_iy			; wwww)		set Y
	.word	nm_jmp			; aaaaaa*	jump
	.word	nm_dump			; +			continue hex dump
	.word	nm_peek			; aaaaaa,	read byte and push
	.word	nm_admp			; -			continue ASCII dump
	.word	nm_hpop			; dd.		show in hex
	.word	nm_ssp			; wwww/		set SP (new)
; special commands outside normal range
	.word	nm_sdb			; wwwwdd?	set D=wwww, B=dd

#ifdef	SAFE
; label just for table size computation
nm_endc:
#endif

; ************************
; *** command routines ***
; ************************
nm_poke:
; * poke value in memory *
	JSR nm_gaddr
	JSR nm_pop
	STA [z_addr]
	RTS

nm_peek:
; * peek value from memory and put it on stack *
	JSR nm_gaddr
	LDA [z_addr]
	JMP nm_push				; push... and return

nm_asc:
; * 16-char ASCII dump from address on stack *
; note common code with hex dump
	JSR nm_gaddr
nm_admp:
; * continue ASCII dump *
	LDY #16				; number of bytes
	LDA #255			; this (negative) means ASCII dump
	BRA nd_reset		; common routine, was not zero anyway

nm_hex:
; * 8-byte hex dump from address on stack *
	JSR nm_gaddr
nm_dump:
; * continue hex dump *
	LDY #8				; number of bytes
	TYA					; this (positive) means HEX dump
nd_reset:
	STY z_tmp			; stored as counter
	STA z_dat			; stored as flag (negative means ASCII dump)
nhd_loop:
		LDA [z_addr]		; get byte from mutable pointer
		BIT z_dat			; check dump type
		BPL nhd_do			; positive means HEX dump
; *** check whether printable ***
			CMP #' '			; otherwise is ASCII, but printable?
			BCC nhd_npr			; no, use substituting character instead
				CMP #127			; high-ASCII will not print either
					BCC nhd_prn			; below 127 (and over 31), keep it as is
nhd_npr:
				LDA #'.'			; otherwise use substituting character
nhd_prn:
; *** end of filtering ***
			JSR nm_out			; print whatever
			BRA nd_done		; go for next
nhd_do:
		JSR nm_shex
nd_done:
		.al: REP #$20
		INC z_addr			; update pointer
		.as: SEP #$20
		BNE nhd_nc			; in case of bank crossing
			INC z_addr+2
nhd_nc:
		DEC z_tmp			; one less to go
		BNE nhd_loop
	RTS

nm_regs:
; * show register values *

; format p$$b$$d$$$$s$$$$
;        y$$$$x$$$$a$$$$

	LDX #11				; max offset
nmv_loop:
		STX z_dat			; just in case
		LDA nm_lab, X		; get label from list
		JSR nm_out
		LDX z_dat			; just in case
		CPX #10				; past the last 8-bit value?
		BCS nmv_8b			; no, skip MSB
			LDA z_acc, X		; yeah, print MSB
			JSR nm_shex
			DEC z_dat			; now for LSB
			LDX z_dat			; continue with updated value
nmv_8b:
		LDA z_acc, X		; get register value, must match order!
		JSR nm_shex			; show in hex
		LDX z_dat			; just in case
		CPX #6				; first line just printed?
; check if first line is complete in order to send a newline...
; ...but may be removed for 16-char displays
		BNE nmv_nol			; no, do not feed
			LDA #10				; yes, jump line (CR if not run816)
			JSR nm_out
			LDX z_dat			; just in case
nmv_nol:
; end of optional newline
		DEX					; go back for next
		BPL nmv_loop		; zero will be last
	RTS
nm_lab:
	.asc	" a x y s dbp"	; register labels, note space before 16-bit values, will be printed backwards!

nm_acc:
; * set A **** and other 16-bit registers
	LDY #0				; A must be the first register into variables array
nm_rgst:
	JSR nm_pop
; use this instead of ABSOLUTE Y-indexed, non 65816-savvy! (same bytes, bit slower but 816-compliant)
	TAX					; will run in emulation mode though
	STX z_acc, Y
	INY					; go to next byte (MSB)
; this is the entry point for 8-bit registers...
nm_rgst1:
	JSR nm_pop
; use this instead of ABSOLUTE Y-indexed, non 65816-savvy! (same bytes, bit slower but 816-compliant)
	TAX					; will run in emulation mode though
	STX z_acc, Y
	RTS

nm_ix:
; * set X *
	LDY #z_x-z_acc		; non-constant, safe way
	BRA nm_rgst			; common code

nm_iy:
; * set Y *
	LDY #z_y-z_acc		; non-constant, safe way
	BRA nm_rgst			; common code

nm_psr:
; * set P **** will set 8 bits only
	LDY #z_psr-z_acc	; non-constant, safe way
	BRA nm_rgst1		; single-byte code

nm_ssp:
; * set S *
	LDY #z_s-z_acc		; non-constant, safe way
	BRA nm_rgst			; common code

nm_sdb:
; * SPECIAL, set D & B **** one 8-bit and one 16-bit
	LDY #z_b-z_acc		; will set 8-bit B first
	JSR nm_rgst1		; CALL single-byte code
	LDY #z_d-z_acc		; then 16-bit D
	BRA nm_rgst			; common code

nm_ireg:
; *** special entry point for register init *** eeeeeeeeeeeeeeek
	PHD					; will stack regular D under the long return address! eeeeeeeek
	BRA njs_regs		; get register status... and return to caller!

nm_jsr:
; * call address on stack *
; must keep current D somewhere!
	PHD					; will stack regular D under the long return address! eeeeeeeek
	JSR @nm_jmp2		; jump as usual but without touching SP, hopefully will return here via RTL!
njs_regs:
; restore register values
	PHP					; flags are delicate and cannot be directly STored
	PHD					; will save Direct Page at exit time
	.al: .xl: REP #$38	; this will reset D flag too! Not needed at startup
; should make certain about nanomon direct page location!
	PHA					; will temporarily destroy A, thus save it first
	LDA 6, S			; gets buried original D value (will be discarded later)
	TCD					; back to original direct page, register values can be safely saved!
	PLA					; A value after exit is restored
; continue saving regular registers
	STA z_acc
	STX z_x
	STY z_y
	PLA					; this picks up D after exit
	STA z_d
	.as: .xs: SEP #$30	; 8 bit registers remain
	PHB					; save Data Bank
	PLA
	STA z_b
	PLA					; this was the saved status reg
	STA z_psr
; perhaps should reset some internal variables, just in case
	PLA					; at least MUST discard previously saved D!
	PLA					; meaningless 8-bit values
	RTS

nm_jmp:
; * jump to address on data stack *
	.xl: REP #$10
	LDX z_s				; saved SP value
	TXS					; this makes sense if could be changed, will not return anyway
	.xs: SEP #$10
nm_jmp2:
	JSR nm_gaddr		; pick desired address
; preload registers
	LDA z_psr
	PHA					; P cannot be directly Loaded, thus push it
	LDA z_b
	PHA					; will preset B
	PLB
	.al: .xl: REP #$30
	LDA z_d				; direct page will be preset from stack
	PHA
	LDA z_acc
	LDX z_x
	LDY z_y
	PLD					; set D from top of stack
	.as: .xs:			; *** SEP #$30 not needed per PLP ***
	PLP					; just before jumping, set flags
	JMP [z_addr]		; go! not sure if it will ever return...

; moved nm_hpop for improved performance and compact size!

; ***********************
; *** useful routines *** OK for 816
; ***********************
nm_gaddr:
; * pop 24-bit address in z_addr *
	JSR nm_pop			; will pop LSB first
	STA z_addr
	JSR nm_pop			; then goes MSB
	STA z_addr+1
	JSR nm_pop			; Bank address goes last
	STA z_addr+2
	RTS

nm_pop:
; * pop 8-bit data in A *
	DEC z_sp			; pre-decrement index
#ifdef	SAFE
	BPL np_some			; non-empty
		STZ z_sp			; or void pointer
; could complain somehow
np_some:
#endif
	LDX z_sp
	LDA stack, X
	RTS

nm_push:
; * push A into stack *
	LDX z_sp
#ifdef	SAFE
	CPX #STKSIZ			; room for it?
	BCC nh_room			; yeah, proceed
; could complain somehow otherwise
		RTS
nh_room:
#endif
	INC z_sp			; post-increment index
	STA stack, X
	RTS

nm_hpop:
; * pop value and show in hex *
	JSR nm_pop
;	JMP nm_shex			; print hex... and return (already there!)

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
;	BRA nm_out			; print it... and return (already there!)

nm_out:
; *** standard output ***
	TAY					; set CONIO parameter
	PHX					; CONIO savviness
	_ADMIN(CONIO)
	PLX					; restore X as was destroyed by the call parameter
	RTS

nm_in:
; *** standard input ***
	PHX					; CONIO savviness
nm_in2:
		LDY #0				; CONIO as input
		_ADMIN(CONIO)
		BCS nm_in2			; it is locking input
	PLX					; always OK on 65816
	TYA					; get read char
	RTS

nm_read:
; * input command line into buffer *
; good to put some prompt before
	LDA #CR				; eeeeeeeeeeeeek (needed for run816, CR otherwise)
	JSR nm_out
	LDA z_addr+2		; PC.Bank *** otherwise seems OK
	JSR nm_shex			; as hex
	LDA z_addr+1		; PC.MSB
	JSR nm_shex			; as hex
	LDA z_addr			; same for LSB
	JSR nm_shex
	LDA #COLON			; prompt sign
	JSR nm_out
	LDX #0				; reset cursor

nr_loop:
		STX z_cur			; keep in memory, just in case
nl_ign:
		JSR nm_in
; *** must convert to uppercase ***
		CMP #'a'			; lowercase?
		BCC nl_upp			; no, leave it as is
			AND #%01011111		; yes, convert to uppercase (strip bit-7 too)
nl_upp:
; *** end of uppercase conversion ***
		CMP #CR				; is it newline (CR)? EEEEEEEEEEEEEEEEK
			BEQ nl_end			; if so, just end input
		CMP #BS				; was it backspace?
			BEQ nl_bs			; delete then
		CMP #' '			; whitespace?
			BCC nl_ign			; simply ignore it!
		PHA					; save what was received...
		JSR nm_out			; ...in case it gets affected
		PLA
		LDX z_cur			; retrieve cursor
; *** could check bounds here ***
#ifdef	SAFE
		CPX #BUFFER			; full buffer?
		BCC nl_ok			; no, just continue
			LDA #BS				; yes, delete last printed
			JSR nm_out
; perhaps could beep also...
			BRA nr_loop			; nothing gets written, ask again for BS
nl_ok:
#endif
		STA buff, X			; store char in buffer
		INX					; go for next
		BRA nr_loop
nl_end:
	JSR nm_out			; must echo CR
	LDX z_cur			; retrieve cursor as usual
	STZ buff, X		; terminate string!
	STZ z_cur			; and reset cursor too
	RTS
nl_bs:
	JSR nm_out			; will echo BS
	LDX z_cur			; retrieve cursor as usual
		BEQ nr_loop			; do not delete if already at beginning
	DEX					; otherwise go back once
	BRA nr_loop

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
.)
