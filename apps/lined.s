; line editor for minimOS!
; v0.5b6
; (c) 2016 Carlos J. Santisteban
; last modified 20160522-1122

#ifndef	ROM
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
.text
#endif

; *** constants declaration ***
#define	LBUFSIZ		80

#define	CR			13
#define	SHOW		$14
#define	EDIT		5
#define	DELETE		$18
#define	DOWN		$12
#define	UP			$17
#define	GOTO		7
#define	QUIT		$11
#define	BACKSPACE	8
#define	TAB			9
#define	ESCAPE		27

; ##### include minimOS headers and some other stuff #####

; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	ptr		=	uz		; current address ponter
	src		=	ptr+2	; source
	dest	=	src+2	; destination
	tmp		=	dest+2	; temporary storage, aka optr
	tmp2	=	tmp+2	; temporary storage, aka delta
	cur		=	tmp2+2	; current line number
	start	=	cur+2	; start of loaded text
	top		=	start+2	; end of text (NULL terminated)
	key		=	top+2	; position in buffer, unlike the C version
	edit	=	key+1	; flag for EDIT mode
	l_buff	=	edit+2	; temporary input buffer
	iodev	=	l_buff+LBUFSIZ	; standard I/O ##### minimOS specific #####

	__last	= iodev+1	; ##### just for easier size check #####

; *** initialise the editor ***

; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_lined		; enough space
	BEQ go_lined		; just enough!
		_ERR(FULL)			; not enough memory otherwise (rare)
go_lined:
#endif
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<le_title		; LSB of window title
	LDA #>le_title		; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_ed			; no errors
		_ERR(NO_RSRC)		; abort otherwise! proper error code
open_ed:
	STY iodev			; store device!!!
; ##### end of minimOS specific stuff #####

	_STZA edit			; reset EDIT flag (false)
; *** ask for text address (could be after loading) ***
	LDA #'$'			; hex radix as prompt
	JSR prnChar			; print it!
	JSR hexIn			; read line asking for address, will set at tmp
; this could be the load() routine
	LDA tmp+1			; get start address
	LDY tmp				; *** this one will define status for BNE ***
	STA start+1			; store unmodified
	STY start
	BNE le_nw			; will not wrap upon decrease
		_DEC				; decrease MSB
le_nw:
	DEY					; one less for leading terminator
	_STZX ptr			; clear pointer LSB (will use indirect indexed)
	STA ptr+1			; pointer MSB
	LDA #0				; NULL value
	STA (ptr), Y		; store just before text!
	INY					; correct value
	BNE le_nw2			; did not wrap
		INC ptr+1			; carry otherwise
le_nw2:
; scan the 'document' until the end
	_STZA cur				; set initial value
	_STZA cur+1			; do not forget MSB!
ll_scan:
		LDA (ptr), Y		; get stored char
			BEQ ll_end			; already at the end
		CMP #CR				; is it newline?
		BNE ll_next			; otherwise continue
			INC cur				; count another line
			BNE ll_next			; did not wrap
				INC cur+1			; or increase MSB!
ll_next:
		INY					; increase LSB
		BNE ll_scan			; no page boundary crossing
			INC ptr+1			; otherwise next page
		_BRA ll_scan
ll_end:
; add leading CR if [-1] is not CR nor NUL
	TYA					; check LSB, worth it
	BNE ll_dec			; directly if no wrap
			DEC ptr+1			; do not forget MSB
ll_dec:
	DEY					; what is before term?
	LDA (ptr), Y
	TAX					; keep for later
	INY					; back to end
	BNE ll_inc		; no wrap
		INC ptr+1			; else correct MSB
ll_inc:
	TXA					; retrieve value
	BEQ ll_empty		; nothing to correct
		CMP #CR				; already a newline?
 	BEQ ll_empty		; nothing to correct
 		LDA #CR				; otherwise put newline
 		STA (ptr), Y
 		INY					; now for the missing term
 		BNE ll_term		; did not wrap
 			INC ptr+1
ll_term:
 		LDA #0				; put terminator
 		STA (ptr), Y
 		INC cur				; one more detected line
 		BNE ll_empty
 			INC cur+1
ll_empty:
; continue setting pointers
	STY ptr				; update pointer LSB
	STY top				; also as top
	LDA ptr+1			; let us see MSB
	STA top+1			; also as top, will not affect flags
	LDA cur				; any line?
	ORA cur+1
	BNE ll_some			; was not empty
		JMP le_cbp			; clear buffer and prompt
ll_some:
	JSR l_prev			; back to previous (last) line
	JSR l_indent		; get leading whitespace
	JSR l_show			; display this line!
	JSR l_prompt		; eeeeeeeeek!

; *** main loop ***
le_loop:
		JSR lockCin			; get char in A
		CMP #SHOW			; was 'show all' command (currently ^T)?
		BNE le_sw1			; check next otherwise
; show all
			JSR l_all			; show all
			JMP l_prlp			; prompt and continue!
le_sw1:
		CMP #EDIT			; was 'edit' command (^E)?
		BNE le_sw2			; check next otherwise
; edit
			LDA cur				; check whether at start
			ORA cur+1
			BNE led_else		; was not leading terminator
le_clbuf:
				JSR txtStart		; otherwise complain
				JMP le_cbp			; clear buffer and prompt
led_else:
			LDA edit			; check edit mode
			BNE led_ned			; discard current buffer
				JSR l_prev			; otherwise get previous
				INC edit			; and enter edit mode
led_ned:
			JSR l_pop			; fill buffer from memory
led_ex:
			JMP l_prlp			; prompt and continue!
le_sw2:
		CMP #DELETE			; was 'delete' command (^X)?
		BNE le_sw3			; check next otherwise
; delete
			LDA cur				; is it at the beginning?
			ORA cur+1			; do not forget MSB!
				BEQ le_clbuf		; complain, clear buffer and continue
			LDY ptr				; get current pos
			LDA ptr+1
			STY src				; store source pointer
			STA src+1
			JSR l_prev			; get previous
			LDY ptr				; get current address
			LDA ptr+1
			STY dest			; store destination pointer
			STA dest+1
			JSR l_mvdn			; move memory down
			LDA cur				; was the first one?
			ORA cur+1			; just look for zero
			BNE ld_do			; more before, can show last
				JMP l_prlp			; otherwise prompt and continue
ld_do:
			JSR l_prev			; back to previous line (to be shown)
			JMP ldn_do			; indent, show, prompt and continue!
le_sw3:
		CMP #CR				; was Return key?
			BEQ lcr_do			; process accordingly
		JMP le_sw4			; check next otherwise (was out of range)
; enter!
lcr_do:
			LDX key				; this is really the index for buffer
			LDA #0				; NULL terminator 
			STA l_buff, X		; terminate buffer, 816-savvy
			LDA edit			; edit in progress?
			BNE lcr_else		; replace old content then
				LDY ptr				; get current LSB
				LDA ptr+1			; and MSB
				STY src				; set source address = ptr!
				STA src+1
				TYA					; let us operate over the value on src
				SEC					; plus one!!!
				ADC key				; this serves as buflen(), really
				STA dest			; set destination address LSB
				LDA src+1			; now for the MSB
				ADC #0				; just propagate carry
				STA dest+1			; pointer complete
				JSR l_mvup			; move memory up!
				INC cur				; do not forget MSB!
				BNE lcr_com			; did not wrap
					INC cur+1			; otherwise propagate carry
				_BRA lcr_com		; continue in common block
lcr_else:
			_STZA edit			; no longer in edit mode
			LDY ptr				; get original pointer (will stay)
			LDA ptr+1
			STY src				; store as src
			STA src+1
			PHA					; keep optr in stack!!!!!! eeeeeek!
			_PHY				; order essential for NMOS compatibility
			INC key				; buffer length plus newline
			JSR l_next			; advance to next line
; Y = old line length (ptr-optr)
			CPY key				; compare old-new
			BEQ lcr_nomv		; no need to move!
			BCC lcr_down		; now is shorter
; now is longer, move up
; compute delta A = Y-(key+1)

/*				TYA					; old line length
				SEC					; set borrow!
				SBC key				; subtract new length (plus one)
				PHP					; keep status for later
				STA tmp				; store delta!
				SEC					; prepare
				LDA src				; get source LSB
				SBC tmp				; minus delta
				STA dest			; as destination
				LDA src+1			; now MSB
				SBC #0				; propagate borrow
				STA dest+1			; pointers ready
				PLP					; retrieve status (from unsigned op) */

				JSR l_plusD			; make dest = src + delta
				JSR l_mvup			; move memory up
				_BRA lcr_nomv
lcr_down:
; now is shorter, 
			JSR l_plusD			; make dest = src + delta
			JSR l_mvdn			; move memory down
lcr_nomv:
			_PLY				; retrieve optr
			PLA
			STY ptr				; restore pointer
			STA ptr+1
lcr_com:
			JSR l_push			; copy buffer into memory
			JSR l_prev			; back to previous line
			JSR l_indent		; get leading whitespace
			JSR l_next			; advance to next line
			JMP l_prlp			; prompt and continue!
le_sw4:
; --- supress debug code from here ---
		CMP #4					; was 'debug' key (^D)?
		BNE le_sw_debug			; check next otherwise
			LDY #<debug_str			; pointer to debug string
			LDA #>debug_str
			JSR prnStr				; print banner
			LDA start+1			; 'start'
			JSR prnHex
			LDA start
			JSR prnHex
			LDA #' '			; space
			JSR prnChar
			LDA ptr+1			; 'ptr'
			JSR prnHex
			LDA ptr
			JSR prnHex
			LDA #' '			; space
			JSR prnChar
			LDA top+1			; 'top'
			JSR prnHex
			LDA top
			JSR prnHex
			LDA #CR
			JSR prnChar
			JMP l_prlp
debug_str:
	.asc	CR, "(start,ptr,top)=", 0
le_sw_debug:
; --- end of debug block ---
		CMP #UP				; was 'up' key (^W)?
		BNE le_sw5			; check next otherwise
; line up
			LDA cur				; is it at the beginning?
			ORA cur+1			; do not forget MSB!
				BEQ lu_no			; complain, clear buffer and continue
			JSR l_prev			; skip pointed buffer
			LDA cur				; is it now at the beginning?
			ORA cur+1			; do not forget MSB!
			BNE lu_yes			; OK to back off another one
lu_no:
				JMP le_clbuf		; otherwise complain etc
lu_yes:
			JSR l_prev			; ...and previous
			_BRA ldn_do			; indent, show, prompt and continue!
le_sw5:
		CMP #DOWN			; was 'down' key (^R)?
		BNE le_sw6			; check next otherwise
; line down *** this is a common ending ***
ldn_do:
			_LDAY(ptr)			; watch pointed
			BNE ldn_pick		; not at end
				JSR txtEnd			; complain
				JSR l_prev			; otherwise do not advance
ldn_pick:
			JSR l_indent		; get leading whitespace
			JSR l_show			; display this line!
			JMP l_prlp			; prompt and continue!
le_sw6:
		CMP #GOTO			; was 'go to' command (^G)?
		BNE le_sw7			; check next otherwise
			LDY #<le_line		; get string address
			LDA #>le_line
			JSR prnStr			; prompt for line number
			JSR hexIn			; read value asking for line number, will set at tmp
			LDY start			; get start address
			LDA start+1
			STY ptr				; reset pointer
			STA ptr+1
			_STZA cur			; reset counter
			_STZA cur+1
			_STZA tmp2			; reset counter as zz
			_STZA tmp2+1
lg_loop:
				LDA tmp				; check LSB of asked value
				CMP tmp2			; compare with zz
					BNE lg_adv			; another one
				LDA tmp+1			; check MSB just in case
				CMP tmp2+1
					BEQ lg_exit			; all done then
lg_adv:
				_LDAY(ptr)			; check currently pointed
				BNE lg_cont			; not at end
					JSR txtEnd			; otherwise complain
					_BRA lg_exit		; finish anyway
lg_cont:
				JSR l_next			; advance one line
				INC tmp2			; another zz
				BNE lg_loop			; did not wrap
					INC tmp2+1			; otherwise correct MSB
				_BRA lg_loop		; continue
lg_exit:
			LDA cur				; check whether there is nothing before
			ORA cur+1
				BEQ le_cbp			; no reference to pick
			JSR l_prev			; otherwise back once
			_BRA ldn_do			; indent, show, prompt and continue
le_sw7:
		CMP #ESCAPE			; was 'esc' key?
		BNE le_sw8			; check next otherwise
; escape clears input buffer and prompt *** common ***
le_cbp:
			_STZA l_buff		; clear buffer
			_BRA l_prlp			; prompt and continue!
le_sw8:
		CMP #QUIT			; was 'quit' command (^Q)?
		BNE le_sw9			; check next otherwise
; quit after asking for confirmation!
			LDY #<le_quit		; get string address
			LDA #>le_quit
			JSR prnStr			; print the string
			JSR lockCin			; wait for a char
			ORA #32				; all lower case
			CMP #'y'			; accepted by user?
			BNE l_prlp			; if not, prompt again and continue
				_EXIT_OK			; otherwise exit to shell?
le_sw9:
		CMP #BACKSPACE		; was 'backspace' key?
		BNE le_def			; check default otherwise
; backspace
			LDY key				; this is really the index for buffer
			BEQ le_loop2		; empty buffer, nothing to delete
				DEC key				; otherwise decrease index
				JSR prnChar			; proper code already at A
le_loop2:
			JMP	le_loop			; continue forever
le_def:
; manage regular typing as default
		LDX key				; this is really the index for buffer
		CPX #LBUFSIZ-1		; full buffer?
			BEQ le_loop2		; ignore then
		JSR l_valid			; check for a valid key
			BCS le_loop2		; was not
		STA l_buff, X		; store into buffer, 816-savvy!
		CMP #TAB			; was a tabulator?
		BNE ldf_prn			; regular char, do not convert
			LDA #'~'			; substitution char
ldf_prn:
		JSR prnChar			; print 
		INC key				; another char in buffer
		_BRA le_loop2		; and continue
l_prlp:
		JSR l_prompt		; prompt for current line
		_BRA le_loop2		; and continue (saves one byte)

; *** useful routines ***
; ** basic output and hexadecimal handling **

; might include this library when a portable, properly interfaced one is available!
;#include "libs/hexio.s"
; in the meanwhile, it takes these subroutines

; * print a character in A *
prnChar:
	STA io_c			; store character
	LDY iodev			; get device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print a NULL-terminated string pointed by $AAYY *
prnStr:
	STA str_pt+1		; store MSB
	STY str_pt			; LSB
	LDY iodev			; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS

; * convert two hex ciphers into byte@tmp, X is cursor originally set at 0 *
hex2byte:
	LDY #2				; reset loop counter, 2 ciphers per byte
	_STZA tmp			; also reset value
	JSR gnc_do			; get first char!

h2b_l:
		SEC					; prepare
		SBC #'0'			; convert to value
			BCC h2b_err			; below number!
		CMP #10				; already OK?
		BCC h2b_num			; do not shift letter value
			CMP #23			; should be a valid hex
				BCS h2b_err		; not!
			SBC #6			; convert from hex (had CLC before!)
h2b_num:
		ASL tmp				; older value times 16
		ASL tmp
		ASL tmp
		ASL tmp
		ORA tmp				; add computed nibble
		STA tmp				; and store full byte
		JSR gnc_do			; obtain next char
		DEY					; loop counter
		BNE h2b_l			; until done
h2b_err:
	DEX					; why?
	RTS					; value is at tmp

; simplified gnc_do routine
gnc_do:
	LDA l_buff, X		; get raw character
		BEQ gn_ok			; go away if ended
	CMP #'a'			; not lowercase?
		BCC gn_ok			; all done!
	CMP #'z'+1			; still within lowercase?
		BCS gn_ok			; otherwise do not correct!
	AND #%11011111		; remove bit 5 to uppercase
gn_ok:
	INX					; advance! eeeeeek!
	RTS

; * print a byte in A as two hex ciphers *
; uses tmp.W
prnHex:
	JSR ph_conv			; first get the ciphers done
	LDA tmp				; get cipher for MSB
	JSR prnChar			; print it!
	LDA tmp+1			; same for LSB
	JMP prnChar			; will return
ph_conv:
	STA tmp+1			; keep for later
	AND #$F0			; mask for MSB
	LSR					; convert to value
	LSR
	LSR
	LSR
	LDY #0				; this is first value
	JSR ph_b2a			; convert this cipher
	LDA tmp+1			; get again
	AND #$0F			; mask for LSB
	INY					; this will be second cipher
ph_b2a:
	CMP #10				; will be letter?
	BCC ph_n			; numbers do not need this
		ADC #'A'-'9'-2		; turn into letter, C was set
ph_n:
	ADC #'0'			; turn into ASCII
	STA tmp, Y
	RTS

; ** end of inline library **

; ##### standard locking input (minimOS specific) #####
; * get char in A from standard device *
lockCin:
		LDY iodev			; get I/O device
		_KERNEL(CIN)		; non-locking input
#ifndef	SAFE
		BCS lockCin			; wait for something (other errors will lock!)
#else
			BCC lci_ok			; already got a valid char!
		CPY #EMPTY			; if not, this is the only expected error
		BEQ lockCin			; continue waiting
			BRK					; abort execution!
			.asc	"I/O error", 0		; just in case is handled
#endif
lci_ok:
	LDA io_c			; get char in A
	RTS

; * hexadecimal input *
hexIn:					; read line asking for address, will set at tmp
	LDX #0				; reset cursor
	STX tmp2			; new safer storage
hxi_loop:
		JSR lockCin			; wait until something is in A
		CMP #BACKSPACE		; is it backspace?
		BNE hxi_nbs			; skip otherwise
			LDX tmp2			; is there anything to delete?
				BEQ hxi_loop		; ignore if empty
			DEC tmp2				; back one char otherwise
			JSR prnChar			; print backspace 
			_BRA hxi_loop		; continue
hxi_nbs:
		CMP #CR				; is it return?
			BEQ hxi_proc		; proceed!
		LDX tmp2			; retrieve index
		CPX #LBUFSIZ		; check against limits
			BEQ hxi_loop		; buffer full, only backspace or CR accepted!
		STA l_buff, X		; store char
		JSR prnChar			; eeeeeeek!!!
		INC tmp2			; next position in buffer
		_BRA hxi_loop
hxi_proc:
; process hex and save result at tmp.w
	JSR prnChar				; show final CR!
	LDX #0					; reset index
	JSR hex2byte			; convert MSB
	LDA tmp					; preserve low byte
	STA tmp+1
	JMP hex2byte			; now convert LSB in situ, and return

; ** business logic functions **
; back to previous line (revamped)
; X returns skipped line length
l_prev:
	LDX #0				; auxiliary counter!
	LDY ptr				; get pointer LSB
	_STZA ptr			; will use indirect indexed!
	TYA					; worth it
	BNE lpv_nw			; no page cross
		DEC ptr+1			; otherwise correct MSB
lpv_nw:
	INX
	DEY					; back once anyway
	LDA (ptr), Y		; check for leading newline
	BNE lpv_do			; not at start
lpv_abort:
		DEX
		INY					; restore position
		STY ptr				; in case of reaching first line
		BNE lpv_nw2			; was MSB changed?
			INC ptr+1			; if so, restore it
lpv_nw2:
		JMP txtStart		; just complain and will return
lpv_do:
		TYA					; check LSB, worth it
		BNE lpv_dec			; directly if no wrap
			DEC ptr+1			; do not forget MSB
lpv_dec:
		DEY					; should be before a leading CR
		INX
		LDA (ptr), Y		; look at char
			BEQ lpv_exit		; terminator aborts
		CMP #CR				; newline aborts in a different way
			BNE lpv_do			; continue otherwise
lpv_exit:
	DEX
	INY					; not at the very lead
	STY ptr				; update pointer
	BNE lpv_nw3			; was MSB changed?
		INC ptr+1			; if so, restore it
lpv_nw3:
	LDY cur				; will decrease cur
	BNE lpv_cur			; directly if no wrap
		DEC cur+1			; do not forget MSB
lpv_cur:
	DEC cur				; decrease LSB
	RTS

; get leading whitespace (revamped)
l_indent:
	LDX #0				; reset index
	LDY #0				; source index
li_loop:
		LDA (ptr), Y		; get first char
		CMP #' '			; check whether space
		BEQ li_do			; will be accepted
			CMP #TAB			; or tabulation
				BNE li_exit			; stop otherwise
li_do:
		STA l_buff, X		; put data on buffer, 816-savvy!
		INY					; next
		INX
		_BRA li_loop
li_exit:
	_STZA l_buff, X		; no need for temporary offset, as ptr will not be changed!
	RTS

; display this line! (revamped)
l_show:
; get the 'cur' line number printed in hex!
	LDA #CR				; eeeek
	JSR prnChar			; put leading newline
	LDA cur+1			; MSB goes first!
	JSR prnHex			; prints two hex digits
	LDA cur				; now the LSB
	JSR prnHex
	LDA #$3A			; code of the colon character
	JSR prnChar			; print it, end of header
	LDY #0				; reset index
lsh_loop:
		_PHY				; save index, needs to be here for NMOS compatibility
		LDA (ptr), Y		; get char from memory
		BNE lsh_cr			; abort upon terminator, do not forget stacked index!
			PLA
			JSR txtEnd			; complain
			RTS					; that is it???
lsh_cr:
		CMP #CR				; newline will exit too, but in a different way
			BEQ lsh_exit
		JSR prnChar			; print it
		_PLY				; restore index
		INY					; next char
		_BRA lsh_loop
lsh_exit:
	PLA					; discard saved index!!!
	TYA					; get current offset
	BEQ lsh_nw			; did not move, go away!
		SEC					; prepare... but from next! eeeeeeek!
		ADC ptr				; add to current value
		STA ptr				; update LSB
		BCC lsh_cur			; no page cross
			INC ptr+1			; update MSB otherwise
lsh_cur:
	INC cur				; count another line
	BNE lsh_nw			; no page cross
		INC cur+1			; increase  MSB otherwise
lsh_nw:
;	LDA #CR				; end on newline
;	JMP prnChar			; print it and return
	RTS

; show all (revamped)
l_all:
	LDA #CR				; leading newline
	JSR prnChar			; make some room
	LDY start			; get LSB
	LDA start+1			; MSB too
	JSR prnStr			; print whole string!!!
	LDA #'~'			; trailing character
	JMP prnChar			; make room and return

; ask for current line (revised)
l_prompt:
	LDA #CR				; eeeeeek
	JSR prnChar			; put leading newline
	LDA cur+1			; MSB goes first!
	JSR prnHex			; prints two hex digits
	LDA cur				; now the LSB
	JSR prnHex
	LDA #'>'			; prompt character
	JSR prnChar			; print it, end of header
	LDX #0				; reset index
lpm_loop:
		_PHX				; save index, NMOS compatibility needs to be here
		LDA l_buff, X		; get char from buffer, 816-savvy!
			BEQ lpm_exit		; abort upon terminator, do not forget stacked index!
		JSR prnChar			; print it
		_PLX				; restore index
		INX					; next char
		_BRA lpm_loop
lpm_exit:
	PLA					; discard saved index!!!
	STX key				; eeeeeeeeek^2!
	RTS

; copy buffer into memory (revamped)
l_push:
	LDX #0				; source index
	LDY #0				; reset index
lph_loop:
		LDA l_buff, X		; get buffer data, 816-savvy!
			BEQ lph_exit		; abort upon terminator
		STA (ptr), Y		; store from pointer (to be increased later)
		INY					; next
		INX
		_BRA lph_loop
lph_exit:
	LDA #CR				; terminator
	STA (ptr), Y		; copied as newline
	TYA					; get index
	CLC					; prepare
	ADC ptr				; add to LSB
	STA ptr				; update
	BCC lph_end			; will not cross page
		INC ptr+1			; rarely done?
lph_end:
	RTS

; advance to next line (revamped)
; Y returns advanced skipped line length
l_next:
	LDY #0				; reset index
lnx_loop:
		LDA (ptr), Y		; see char
		BNE lnx_cont		; terminator aborts
			_PHY				; save index
			JSR txtEnd			; complain
			_PLY				; restore register!
			_BRA lnx_abort		; exit with ptr at trailing terminator
lnx_cont:
		CMP #CR				; newline ends but go past it!
			BEQ lnx_exit
		INY					; next in line
		_BRA lnx_loop
lnx_exit:
	INY					; skip trailing newline!
lnx_abort:
	TYA					; did move?
	BEQ lnx_end			; if not, same line!
		CLC					; prepare
		ADC ptr				; add to current value
		STA ptr				; update
		BCC lnx_cur			; will not cross page
			INC ptr+1			; rarely done?
lnx_cur:
		INC cur				; increase cur
		BNE lnx_end
			INC cur+1			; do not forget MSB
lnx_end:
	RTS

; fill buffer from memory (revamped)
l_pop:
	LDX #0				; index for buffer
	LDY #0				; reset index
lpl_loop:
		LDA (ptr), Y		; get char
			BEQ lpl_exit		; abort if terminator
		CMP #CR				; newline also aborts
			BEQ lpl_exit
		STA l_buff, X		; put data on buffer, 816-savvy!
		INY					; next
		INX
		_BRA lpl_loop
lpl_exit:
	_STZA l_buff, X		; no need for temporary offset, as ptr will not be changed!
	RTS

; move memory down (revamped)
; uses tmp2 as delta!
l_mvdn:
	LDA src				; compute local delta!
	SEC					; prepare
	SBC dest			; subtract
	STA tmp2			; store result
	LDA src+1			; same for MSB
	SBC dest+1
	STA tmp2+1
	LDY #0				; let us try to optimise
md_loop:
		LDA (src), Y		; get origin
		STA (dest), Y		; copy value
			BEQ md_exit			; abort upon trailing terminator... already copied!
		INY					; next!
			BNE md_loop			; no page crossing!
		INC src+1			; otherwise, increase BOTH MSBs
		INC dest+1
			_BRA md_loop		; and continue until terminator
md_exit:
	LDA top				; get top.LSB
	SEC					; prepare
	SBC tmp2			; subtract delta.LSB
	STA top				; update value
	LDA top+1			; retrieve MSB
	SBC tmp2+1			; same for MSB
	STA top+1			; top updated
	RTS

; move memory up (revamped)
; uses tmp2 as delta! uses tmp
l_mvup:
	LDA dest			; compute local delta!
	SEC					; prepare
	SBC src				; subtract
	STA tmp2			; store result
	LDA dest+1			; same for MSB
	SBC src+1
	STA tmp2+1
; set local pointers
	LDA top				; start from the end!
	LDX top+1
	STA tmp				; local pointer
	STX tmp+1
	CLC					; prepare
	ADC tmp2			; top += delta
	STA top				; update pointer
	STA dest			; will use as local dest
	TXA					; retrieve MSB
	ADC tmp2+1			; new size
	STA top+1			; complete pointer
	STA dest+1			; use dest locally
; --- supress debug code from here ---
lda tmp
pha
lda tmp+1
pha
			LDY #<debug_mu			; pointer to debug string
			LDA #>debug_mu
			JSR prnStr				; print banner
			LDA src+1			; 'src'
			JSR prnHex
			LDA src
			JSR prnHex
			LDA #' '			; space
			JSR prnChar
			LDA top+1			; 'tmp'
			JSR prnHex
			LDA top
			JSR prnHex
			LDA #' '			; space
			JSR prnChar
			LDA dest+1			; 'dest'
			JSR prnHex
			LDA dest
			JSR prnHex
			LDA #' '			; space
			JSR prnChar
			LDA tmp2+1			; 'delta'
			JSR prnHex
			LDA tmp2
			JSR prnHex
			LDA #CR
			JSR prnChar
pla
			STA tmp+1
pla
			STA tmp
			_BRA debug_mu_end
debug_mu:
	.asc	CR, "(src,tmp,dest,delta)=", 0
debug_mu_end:
; --- end of debug block ---
; go for the loop
	LDY #0				; initial value! will decrease afterwards
mu_loop:
		DEY					; one less
		CPY #$FF			; did wrap?
		BNE mu_sp			; same page if not
			DEC tmp+1			; otherwise decrease BOTH MSBs
			DEC dest+1
mu_sp:
		LDA (tmp), Y		; get source
		STA (dest), Y		; copy value
;			BEQ mu_exit			; unexpected start?
; check whether we are done
		TYA					; operate on offset
		CLC					; prepare
		ADC dest			; compute actual destination
		TAX					; store temporarily
		LDA dest+1			; MSB
		ADC #0				; propagate carry
		CMP src+1			; gross comparison
			BNE mu_loop			; still to do
		CPX src				; check LSB just in case
			BNE mu_loop			; still to do
	RTS

; * check for a valid key * (OK)
l_valid:
	CMP #' '			; printable char?
		BCS lv_ok			; say OK
	CMP #TAB			; or is it a tabulation?
		BEQ lv_ok			; OK too
	SEC				; otherwise is NOT valid
	RTS
lv_ok:
	CLC				; OK by default (minimOS could use macro)
	RTS

; * alert from start of document * (OK)
txtStart:
	LDY #<le_start		; LSB of string
	LDA #>le_start		; MSB
	JMP prnStr			; continue subroutine

; * alert from end of document * (OK)
txtEnd:
	LDY #<le_end		; LSB of string
	LDA #>le_end		; MSB
	JMP prnStr			; continue subroutine

; *** strings and data ***
le_title:
	.asc	"Line Editor", 0
le_start:
	.asc	CR, "{start}", 0
le_end:
	.asc	CR, "{end}", 0
le_quit:
	.asc	CR, "Quit? (Y/n):", 0
le_line:
	.asc	CR, "Line $", 0
