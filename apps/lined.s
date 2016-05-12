; line editor for minimOS!
; v0.5b1
; (c) 2016 Carlos J. Santisteban
; last modified 20160512-1442

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
user_sram	= $0400
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
	cur		=	tmp+2	; current line number
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

; *** ask for text address (could be after loading) ***
	LDA #'$'			; hex radix as prompt
	JSR prnChar			; print it!
	JSR hexIn			; read line asking for address, will set at tmp
; this could be the load() routine
	LDA tmp+1			; get start address
	LDY tmp
	STA start+1			; store
	STY start
	BNE le_nw			; will not wrap
		_DEC				; decrease MSB
le_nw:
	DEY					; one less for leading terminator
	STY ptr				; store pointer
	STA ptr+1
	LDA #0				; NULL value
	_STAY(ptr)			; store just before text!
	LDY ptr				; initial value LSB
	_STZA ptr			; clear pointer LSB
	INY					; correct value
	BNE le_nw2			; did not wrap
		INC ptr+1			; carry otherwise
le_nw2:
; scan the 'document' until the end
	LDA #1				; default number of lines
	STA cur				; set initial value
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
		BNE ll_scan			; no need for BRA
ll_end:
	STY ptr				; update pointer LSB
	LDA ptr+1			; let us see MSB
	CMP start+1			; compare against start address
		BNE ll_some			; not empty
	CPY start			; check LSB too
	BNE ll_some			; was not empty
		_STZA l_buff		; clear buffer otherwise
		BEQ le_pr1			; and go for prompt, no need for BRA
ll_some:
	JSR l_prev			; back to previous (last) line
	JSR l_indent		; get leading whitespace
	JSR l_show			; display this line!
; cur-- is not as easy as it looks...
	LDY cur				; might wrap...
	BNE ll_nw			; process accordingly
		DEC cur+1			; correct MSB!
ll_nw:
	DEY					; will do LSB anyway
	STY cur				; update variable
le_pr1:
	_STZA edit			; reset EDIT flag (false)

; *** main loop ***
le_loop:
		JSR lockCin			; get char in A (and in io_c)
		CMP #SHOW			; was 'show all' command (currently ^T)?
		BNE le_sw1			; check next otherwise
; show all
			JSR l_all			; show all
			JMP l_prlp			; prompt and continue!
le_sw1:
		CMP #EDIT			; was 'edit' command (^E)?
		BNE le_sw2			; check next otherwise
; edit
			LDA ptr+1			; check pointer MSB
			CMP start+1			; at beginning?
				BNE led_else		; was not
			LDA ptr				; check LSB too
			CMP start
			BNE led_else		; otherwise is at the beginning
le_clbuf:
				JSR txtStart		; complain
				_STZA l_buff		; clear buffer
				_BRA led_ex			; and prompt
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
			INY					; increase
			BNE ld_nw2			; check MSB
				_INC
ld_nw2:
			STY src				; store source pointer
			STA src+1
			JSR l_prev			; get previous
			LDY ptr				; get current address
			LDA ptr+1
			INY					; increase
			BNE ld_nw			; check MSB
				_INC
ld_nw:
			STY dest			; store destination pointer
			STA dest+1
			JSR l_mvdn			; move memory down
			JSR l_prev			; back to previous line
			LDA start+1			; check MSB
			CMP ptr+1			; compare current pos
				BCC ld_ind			; well over start, get indent
			LDA start			; now check LSB
			CMP ptr
			BCS ld_ex			; start position, do not get indent
ld_ind:
				JSR l_indent		; get leading whitespace
				JSR l_show			; display this line!
ld_ex:
			JMP l_prlp			; prompt and continue!
le_sw3:
		CMP #CR				; was Return key?
		BNE le_sw4			; check next otherwise
; enter!
			LDY key				; this is really the index for buffer
			LDA #0				; NULL terminator 
			STA l_buff, Y		; terminate buffer
			LDA edit			; edit in progress?
			BNE lcr_else		; replace old content
				LDY ptr				; get current LSB
				LDA ptr				; and MSB
				INY					; one more
				BEQ lcr_nw			; no wrap
					_INC				; correct MSB
lcr_nw:
				STY src			; set source address
				STA src+1
				TYA				; let us operate over the value on src
				SEC				; plus one!!!
				ADC key			; this serves as buflen(), really
				STA dest		; set destination address LSB
				LDA src+1		; now for the MSB
				ADC #0			; just propagate carry
				STA dest+1		; pointer complete
				JSR l_mvup		; move memory up!
				INC cur			; do not forget MSB!
				BNE lcr_com		; did not wrap
					INC cur+1		; otherwise propagate carry
				BNE lcr_com		; continue in common block, no need for BRA
lcr_else:
			_STZA edit			; no longer in edit mode
			LDY ptr				; get current position
			LDA ptr+1
			STY tmp				; store as optr
			STA tmp+1
			JSR l_next			; advance to next line
			; compute delta = key+1+optr-ptr
			LDA key				; this only gets to LSB
			SEC					; +1
; ******cannot use optr & tmp*********
			ADC optr			; third term
			TAY					; keep partial LSB
			LDA optr+1			; this is the MSB
			ADC #0				; propagate carry
			STA tmp+1			; all added
			TYA					; retrieve LSB
			SEC					; prepare
			SBC ptr				; subtract MSB
			STA tmp				; store full LSB
			LDA tmp+1			; now for MSB
			SBC ptr+1			; propagate borrow
			BMI lcr_dn			; negative result will move down
				ORA tmp				; check also LSB in case is zero
					BEQ lcr_nomv		; no need to move!
				; move_up(optr, optr+delta)
				_BRA lcr_nomv
lcr_dn:
			; move_dn(ptr,ptr+delta)
lcr_nomv:
			LDY tmp				; retrieve optr
			LDA tmp+1
			STY ptr				; restore pointer
			STA ptr+1
lcr_com:
			JSR l_push			; copy buffer into memory
			JSR l_prev			; back to previous line
			JSR l_indent		; get leading whitespace
			JSR l_next			; advance to next line
			JMP l_prlp			; prompt and continue!
le_sw4:
		CMP #UP				; was 'up' key (^W)?
		BNE le_sw5			; check next otherwise
; line up

			JSR l_indent		; get leading whitespace
			JSR l_show			; display this line!
			
			JMP l_prlp			; prompt and continue!
le_sw5:
		CMP #DOWN			; was 'down' key (^R)?
		BNE le_sw6			; check next otherwise
; line down
			JSR l_indent		; get leading whitespace
			JSR l_show			; display this line!
			JMP l_prlp			; prompt and continue!
le_sw6:
		CMP #GOTO			; was 'go to' command (^G)?
		BNE le_sw7			; check next otherwise
			
			JSR l_indent		; get leading whitespace
			JSR l_show			; display this line!

			JMP l_prlp			; prompt and continue!
le_sw7:
		CMP #ESCAPE			; was 'esc' key?
		BNE le_sw8			; check next otherwise
; escape clears input buffer
			_STZA l_buff		; clear buffer
			JMP l_prlp			; prompt and continue!
le_sw8:
		CMP #BACKSPACE		; was 'backspace' key?
		BNE le_def			; check default otherwise
; backspace
			LDY key				; this is really the index for buffer
			BEQ le_loop2		; empty buffer, nothing to delete
				DEC key				; otherwise decrease index
				JSR prnChar			; proper code already at A (and io_c...)
le_loop2:
			JMP	le_loop			; continue forever
le_def:	
; manage regular typing as default
		LDY key				; this is really the index for buffer
		CPY #LBUFSIZ		; full buffer?
			BCS le_loop2		; ignore then
		JSR l_valid			; check for a valid key
			BCS le_loop2		; was not
;		LDA io_c			; the valid raw key
		STA l_buff, Y		; store into buffer!
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

; * convert two hex ciphers into byte@tmp, A is current char, X is cursor *
hex2byte:
	LDY #0				; reset loop counter
	STY tmp				; also reset value
h2b_l:
		SEC					; prepare
		SBC #'0'			; convert to value
			BCC h2b_err			; below number!
		CMP #10				; already OK?
		BCC h2b_num			; do not shift letter value
			CMP #23			; should be a valid hex
				BCS h2b_err			; not!
			SBC #6			; convert from hex (had CLC before!)
h2b_num:
		ASL tmp				; older value times 16
		ASL tmp
		ASL tmp
		ASL tmp
		ORA tmp				; add computed nibble
		STA tmp				; and store full byte
gnc_do:
		INX					; advance!
		LDA l_buff, X		; get raw character
		  BEQ gn_ok  ; go away if ended
		CMP #'a'			; not lowercase?
			BCC gn_ok			; all done!
		CMP #'z'+1			; still within lowercase?
			BCS gn_ok			; otherwise do not correct!
		AND #%11011111		; remove bit 5 to uppercase
gn_ok:
		INY					; loop counter
		CPY #2				; two ciphers per byte
		BNE h2b_l			; until done
	RTS					; value is at tmp
h2b_err:
	DEX					; will try to reprocess this char
	RTS

; * print a byte in A as two hex ciphers *
prnHex:
	JSR ph_conv			; first get the ciphers done
	LDA tmp				; get cipher for MSB
	JSR prnChar			; print it!
	LDA tmp+1			; same for LSB
	JMP prnChar  ; will return
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
; get char from device in A
lockCin:
	_PHX				; should not affect X
lci_loop:
		LDY iodev			; get I/O device
		_KERNEL(CIN)		; non-locking input
#ifndef	SAFE
		BCS lci_loop		; wait for something (other errors will lock!)
#else
		CPY #EMPTY			; the only expected error
		BEQ lci_loop		; continue waiting
			PLA					; otherwise discard stack and abort!
			PLA
			PLA
			PLA
			PLA
			RTS					; will keep error for the OS
#endif
	_PLX				; restore X
	LDA io_c			; get char in A
	RTS

; TO DO TO DO
l_prev:					; back to previous (last) line
l_indent:				; get leading whitespace
l_show:					; display this line!
l_all					; show all
l_prompt				; ask for current line
l_push					; copy buffer into memory
l_next					; advance to next line
l_pop					; fill buffer from memory
l_mvdn					; move memory down
l_mvup					; move memory up
l_valid					; check for a valid key

; * hexadecimal input *
hexIn:					; read line asking for address, will set at tmp
	LDX #0				; reset cursor
hxi_loop:
		JSR lockCin			; wait until something is in A
		CMP #BACKSPACE		; is it backspace?
		BNE hxi_nbs			; skip otherwise
			CPX #0				; is there anything to delete?
				BCC hxi_loop		; ignore if empty
			DEX					; back one char otherwise
			JSR prnChar			; print backspace 
			_BRA hxi_loop		; continue
hxi_nbs:
		CMP #CR				; is it return?
			BEQ hxi_proc		; proceed!
		CPX #LBUFSIZ		; check against limits
			BCS hxi_loop		; buffer full, only backspace or CR accepted!
		STA l_buff, X		; store char
		INX					; next position in buffer
		BNE hxi_loop		; no need for BRA
hxi_proc:
; process hex and save result at tmp ******** TO DO TO DO TO DO

	RTS

; * alert from start of document *
txtStart:
	LDY #<le_start		; LSB of string
	LDA #>le_start		; MSB
	JMP prnStr			; continue subroutine

; * alert from end of document *
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
