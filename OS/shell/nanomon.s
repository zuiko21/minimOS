; minimOS nano-monitor
; v0.3a4
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20220102-1338
; 65816-savvy, but in emulation mode ONLY

; *** stub as NMI handler, now valid for BRK ***
; (aaaa=4 hex char on stack, dd=2 hex char on stack)
; aaaa@		read byte into stack, NEW format (special mode)
; dd,		write byte AND advance pointer, NEW format
; aaaa!		set write pointer, NEW format
; aaaa$		hex dump
; +			continue hex dump
; aaaa"		ASCII dump
; -			continue ASCII dump
; dd.		pop and show in hex (new)
; aaaa&		call address
; aaaa*		jump to address
; %			show regs
; dd(		set X
; dd)		set Y
; dd#		set A
; dd'		set P
; dd/		set SP (new)
; NEW exit command via the 'colon' character

.(
; ***************
; *** options ***
; ***************
;#define	SAFE	_SAFE
; option to pick full status from standard stack frame, comment if handler not available
#define	NMI_SF	_NMI_SF

BUFFER	= 9				; enough for a single command, even one for a byte and another for a word
STKSIZ	= 4				; in order not to get into return stack space! writes use up to three
; note that with ZP addressing will wrap into start of zeropage, problem with 6510 or default I/O!

; **********************
; *** zeropage usage ***
; **********************
; 6502 registers
; S is never stacked, but must be stored anyway!
	z_s		= $C0		; CANNOT use kernel parameter space
; stacked registers
	z_y		= z_s+1
	z_x		= z_y+1		; must respect register order, now matching stacked order!
	z_acc	= z_x+1
	z_psr	= z_acc+1	; P before PC
; 2-byte PC
	z_addr	= z_psr+1
; internal vars
	z_cur	= z_addr+2
	z_sp	= z_cur+1	; data stack pointer
	z_dat	= z_sp+1
	z_tmp	= z_dat+1
	buff	= z_tmp+1
	stack	= buff+BUFFER

; ******************
; *** init stuff ***
; ******************
+nanomon:
#ifdef	SAFE
	.asc	"UNj*"		; for SAFE service validation!
#endif
#ifdef	C816
	SEC					; make sure it is in emulation mode!!!
	XCE
#endif
; ** procedure for storing PC & PSR values at interrupt time ** 16b, not worth going 15b with a loop
; 65816 valid in emulation mode ONLY!
	STX z_x				; eeeeeek
	TSX
	STX z_s				; store initial SP

#ifdef	NMI_SF
; ** pick register values from standard stack frame, if needed **
; do not mess with systmp/sysptr
; this could be simpler if register variables would match the stacked order... 14b instead of 30b!
	LDY #0				; reset counter, unfortunately cannot work backwards
nmr_loop:
		LDA $106, X			; get stacked value (after a JSR in handler)
		STA !z_y, Y			; actually absolute,Y addressing!
		INX					; go deeper into stack...
		INY					; ...and further into zeropage
		CPY #6				; copied all bytes?
		BNE nmr_loop		; no, continue until done
#else
; systems without NMI-handler may keep old offsets $101...103
	LDX z_x				; eeeeeek
	JSR njs_regs		; keep current state, is PSR ok?
	TSX					; eeeeeek
	LDA $101, X			; get stacked PSR
	STA z_psr			; update value
	LDY $102, X			; get stacked PC
	LDA $103, X
	STY z_addr			; update current pointer
	STA z_addr+1
#endif
	_STZA z_sp			; reset data stack pointer
	CLD					; really worth it...

; main loop
nm_main:
; *** old nm_read code, now inlined ***
		LDA #CR				; eeeeeeeeeeeeek (needed for run816) CR
		JSR nm_out
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
			JSR nm_in			; may inline CONIO call here...
; must convert to uppercase
			CMP #'a'			; lowercase?
			BCC nl_upp			; no, leave it as is
				AND #%01011111		; yes, convert to uppercase (strip bit-7 too)
nl_upp:
; end of uppercase conversion
#ifdef	SAFE

			CMP #FORMFEED		; is it formfeed? must clear, perhaps initialising!
				BNE nl_ncls			; if not, just continue checking others
			CPX #0				; at the beginning? otherwise ^L is ignored
				BEQ nl_bs			; will clear screen with nothing to delete
nl_ncls:
#endif
			CMP #CR				; is it newline? EEEEEEEEEEEEEEEEK (CR)
				BEQ nl_end			; if so, just end input
			CMP #BS				; was it backspace?
				BEQ nl_bs			; delete then
; discarding control codes may just be done before inserting into buffer
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
; perhaps could beep too...
				_BRA nl_ign			; nothing gets written, ask again for BS
; CONIO savviness is already achieved by I/O functions, could use nr_loop instead
nl_ok:
#endif
; this is a good place for discarding control codes, but letting them on print
			CMP #' '			; whitespace?
				BCC nl_ign			; simply ignore it!
			STA buff, X			; store char in buffer
			INX					; go for next (no need for BRA)
			BNE nr_loop
nl_bs:
		JSR nm_out			; will echo BS
		LDX z_cur			; retrieve cursor as usual
			BEQ nl_ign			; do not delete if already at beginning
		DEX					; otherwise go back once
		_BRA nr_loop
nl_end:
		JSR nm_out			; must echo CR
		LDX z_cur			; retrieve cursor as usual
		_STZA buff, X		; terminate string!
		_STZA z_cur			; and reset cursor too
; *** end of inlined input ***
nm_eval:
			CLD					; really worth it...
			LDX z_cur
			LDA buff, X			; get one char
				BEQ nm_main			; if EOL, ask again
; current nm_read rejects whitespace altogether
; *** NEW, check for exit command, remove if not needed ***
			CMP #COLON			; trying to exit?
			BNE nm_cont			; no, continue
#ifndef	NMI_SF
; note that this will not modify stacked register values!
; a simple workaround would be % for checking S as xx
; then 01xx$ to see the stack contents, getting the return address rrrr at 3rd-4th bytes
; subtract 3 to S as yy/ and finally rrrr*
				RTI					; exit from debugger
#else
; the NMI handler will reset registers, thus no sense to preset registers
; use the above workaround, modified as needed (discard whole stack frame!)
				RTS					; back to NMI handler
#endif
; *** end of exit command ***
nm_cont:
; *** special codes are managed here, 6502 version only uses new peek (@) character ***
			CMP #'@'			; is it the peek command?
			BNE nm_npeek		; no, continue with standard form
				JSR nm_peek			; yes, call and return from routine
				_BRA nm_next
nm_npeek:
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
#ifdef	SAFE
			BNE nm_pair			; must be in pairs! would be catastrophic at the very end!
				JMP nm_main
nm_pair:
#endif
			JSR nm_hx2n			; convert another nibble (over the previous one)
			JSR nm_push			; fully converted byte in A pushed into data stack
nm_next:
; read next char in input and proceed
			INC z_cur			; go for next
			BNE nm_eval			; no need for BRA

; ** indexed jump to command routine (must be called from main loop) **
nm_exe:
	SBC #' '			; EEEEEEEEEEEEEEK (C was clear, thus same as subtracting '!')
	ASL					; convert to index
	TAX
#ifdef	SAFE
	CPX #nm_endc-nm_cmds	; within range?
	BCC nm_okx
; might complain here
		RTS				; exit if not
nm_okx:
#endif
; the use of JMPX macro is NOT safe as zeropage is liberally used
; use code from the old, slower macro instead
#ifdef	NMOS
	LDA nm_cmds+1, X	; get MSB
	PHA					; and push it
	LDA nm_cmds, X		; ditto for LSB
	PHA
	PHP					; as required by RTI
	RTI					; actual jump!
#else
	JMP (nm_cmds, X)	; *** execute command ***
#endif

; **************************
; *** command jump table ***
; **************************
nm_cmds:
	.word	nm_gaddr		; aaaa!		set write address (new, note that directly points to generic routine)
	.word	nm_asc			; aaaa"		ASCII dump
	.word	nm_acc			; dd#		set A
	.word	nm_hex			; aaaa$		hex dump
	.word	nm_regs			; %			view regs
	.word	nm_jsr			; aaaa&		call
	.word	nm_psr			; dd'		set P
	.word	nm_ix			; dd(		set X
	.word	nm_iy			; dd)		set Y
	.word	nm_jmp			; aaaa*		jump
	.word	nm_dump			; +			continue hex dump
	.word	nm_poke			; dd,		write byte and advance (new)
	.word	nm_admp			; -			continue ASCII dump
	.word	nm_hpop			; dd.		show in hex
	.word	nm_ssp			; dd/		set SP (new)
;	.word	nm_peek			; aaaa@		read byte and push (managed ad hoc)

#ifdef	SAFE
; label for easy table size computation
nm_endc:
#endif

; ************************
; *** command routines ***
; ************************
nm_poke:
; * poke value in memory *

;	JSR nm_gaddr		; now using predefined address!
	JSR nm_pop			; get value...
	_STAY(z_addr)		; ...and store it into pointed address
	INC z_addr			; new, advance to next address
	BNE nm_pke			; check in case of carry
		INC z_addr+1
nm_pke:
	RTS

nm_peek:
; * peek value from memory and put it on stack *
	JSR nm_gaddr		; traditional way...
	_LDAY(z_addr)		; get byte at that address
	JMP nm_push			; push... and return

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
; format s$$y$$x$$a$$p$$
; new order per matched stack
	LDX #4				; max offset
nmv_loop:
		STX z_dat			; just in case
		LDA nm_lab, X		; get label from list
		JSR nm_out
		LDX z_dat			; just in case
		LDA z_s, X			; get register value, must match order!
		JSR nm_shex			; show in hex
;		LDA #' '			; put a space between registers
;		JSR nm_out
		LDX z_dat			; go back for next
		DEX
		BPL nmv_loop		; zero will be last
	RTS
nm_lab:
	.asc	"syxap"		; register labels, will be printed backwards!

nm_ssp:
; * set S *
; alternate 9+3x4=21b (these were 4x6=24b)
; as ZP register bank mimics stacked order, different offsets than before
	LDY #0				; S must be the first register into variables array
nm_rgst:
	JSR nm_pop
; use this instead of ABSOLUTE Y-indexed, non 65816-savvy! (same bytes, bit slower but 816-compliant)
	TAX					; will run in emulation mode though
	STX z_s, Y
	RTS

nm_iy:
; * set Y *
	LDY #z_y-z_s		; non-constant, safe way, actually is 1
	BNE nm_rgst			; common code

nm_ix:
; * set X *
	LDY #z_x-z_s		; non-constant, safe way, actually is 2
	BNE nm_rgst			; common code

nm_acc:
; * set A *
	LDY #z_acc-z_s		; non-constant, safe way, actually is 3
	BNE nm_rgst			; common code

nm_psr:
; * set P *
	LDY #z_psr-z_s		; non-constant, safe way, actually is 4
	BNE nm_rgst			; common code

nm_jsr:
; * call address on stack *
	JSR nm_jmp2			; jump as usual but without touching SP, hopefully will return here
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
; * jump to address on data stack *
	LDX z_s				; initial SP value
	TXS					; this makes sense if could be changed
nm_jmp2:
	JSR nm_gaddr		; pick desired address
; preload registers
	LDA z_psr
	PHA					; P cannot be directly LoaDed, thus push it
	LDA z_acc
	LDX z_x
	LDY z_y
	PLP					; just before jumping, set flags
	JMP (z_addr)		; go! not sure if it will ever return...

; moved nm_hpop for improved performance and compact size!

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
#ifdef	SAFE
	BPL np_some			; was not empty?
		_STZA z_sp			; reset stack otherwise
; could complain somehow
np_some:
#endif
	LDX z_sp
	LDA stack, X		; should NOT get into return stack, or force absolute,X instead!
	RTS

nm_push:
; * push A into stack *
	LDX z_sp
#ifdef	SAFE
	CPX #STKSIZ			; room for it?
	BCC nh_room
; could complain here
		RTS
nh_room:
#endif
	INC z_sp			; post-increment index
	STA stack, X		; should NOT get into return stack, or force absolute,X instead!
	RTS

nm_hpop:
; * pop value and show in hex * *** from command routines ***
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
;	JMP nm_out			; print it... and return (already there!)

nm_out:
; *** standard output ***
	TAY					; set CONIO parameter
	_PHX				; CONIO savviness
	JSR conio ; test
	_PLX				; restore X as was destroyed by the call parameter
	RTS

nm_in:
; *** standard input ***
	_PHX				; CONIO savviness
nm_in2:
		LDY #0				; CONIO as input
		JSR conio ; test
		BCS nm_in2			; it is locking input
	_PLX				; may destroy A in NMOS!
	TYA					; otherwise, get read char
	RTS

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
