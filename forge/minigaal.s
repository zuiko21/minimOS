; miniGaal, VERY elementary HTML browser for minimOS
; v0.1a3
; (c) 2018 Carlos J. Santisteban
; last modified 20180425-1327

#include "../OS/usual.h"

.(
; *****************
; *** constants ***
; *****************

	STK_SIZ	= 32		; tag stack size
	CLOSING	= 10		; offset for closing tags

; ****************************
; *** zeropage definitions ***
; ****************************

	flags	= uz				; several flags
	tok		= flags+1			; decoded token
	del		= tok+1				; delimiter
	tmp		= del+1				; temporary use
	cnt		= tmp+1				; token counter
	pt		= cnt+1				; cursor (16b)
	pila_sp	= pt+2				; stack pointer
	pila_v	= pila_sp+1			; stack contents (as defined)
	tx		= pila_v+STK_SIZ	; pointer to source (16b)
	iodev	= tx+2				; * usual mOS device handler *

	_last	= iodev+1

; TOKEN numbers (0 is invalid) new base 20180413
; 1 = html (do nothing)
; 2 = head (expect for title at least)
; 3 = title (show betweeen [])
; 4 = body (do nothing)
; 5 = p (print text, then a couple of CRs)
; 6 = h1 (print text _with spaces between letters_)
; 7 = br (print CR)
; 8 = hr (print 20 dashes)
; 9 = a (link????)

; *********************************
; *** minimOS executable header ***
; *********************************
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
mgHead:
; *** header identification ***
	BRK						; don't enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
title:
	.asc	"miniGaal", 0	; file name (mandatory)
	.asc	"HTML browser v0.1", 0	; version in comment

; advance to end of header
	.dsb	mgHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$54E0			; time, 10.39
	.word	$4AAB			; date, 2017/5/11

mgSize	=	mgEnd - mgHead - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	mgSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
#else
title:
	.asc	"miniGaal", 0	; keep window title at least
#endif

; ****************************************
; *** usual minimOS app initialisation ***
; ****************************************
	LDA #_last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_xmg			; enough space
	BEQ go_xmg			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_xmg:
#endif
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<title			; LSB of window title
	LDA #>title			; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
#ifdef	C816
	PHK					; current bank eeeeeeek
	PLA					; get it
	STA str_pt+2		; and set parameter
#endif
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_xmg		; no errors
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_xmg:
	STY iodev			; store device!!!

; ***************************
; *** init business staff ***
; ***************************
; flag format
;		d7 = h1 (spaces between letters)
;		d6 = last was a block element (do not add CRs)
;		d5 = title was shown inside <head>
;		...
	_STZA flags
; must initialise pt in a proper way...
	_STZA pila_sp
; *** main loop ***
mg_loop:
		_LDAY(tx)		; get char from source
			BEQ mg_end		; no more source code!
		CMP #'<'		; opening tag? [if (c=='<') {]
			BEQ chktag		; yes, it is a tag
; * plain text print *
		JSR mg_out		; otherwise, just print it
		BIT flags		; check for flags
		BPL mg_next		; not heading, thus no extra space
			LDA #' '		; otherwise add spaces between letters
			JSR mg_out
mg_next:
		INC tx			; go for next char
		BNE mg_loop		; no wrap
			INC tx+1		; or increase MSB
		BNE mg_loop		; no need for BRA
chktag:
; * tag processing *
	JSR look_tag		; try to indentify a tag, will start from (tx)+1
	TAY					; is it valid?
	BEQ tag_end			; no, just look for >
		JSR push			; yes, push it into stack
; is this switch best done with indexed jump? surely!
		ASL					; convert to index
		TAX
		JSR call_tag
tag_end:
; *** look for trailing > ***
	LDY #1			; start after <
te_loop:
		LDA (tx), Y		; what is there?
			BEQ mg_end		; it is finished!
		CMP #'>'		; is it the trailing >?
			BEQ te_found		; yes, go for next tag
; should it check for closing tags?
		CMP #'/'		; closing tag?
		BNE te_ncl
			JSR pop			; yes, try to forget it
te_ncl:
		INY			; no, keep scanning
		BNE te_loop		; no need for BRA
te_found:
	SEC					; as it has tx++
	TYA
	ADC tx				; add current offset to pointer
	STA tx
		BCC mg_loop
	INC tx+1
		BNE mg_loop			; no need for BRA
mg_end:
; rendering is complete, free window and exit as usual
	LDY iodev
	_KERNEL(FREE_W)		; will no longer use this window, but keep contents
	_EXIT_OK			; *** end of application code ***

; ***************************

; *** tag handling caller ***
call_tag:
	_JMPX(tagtab)

; *** tag handling table ***
tagtab:
	.word	tag_ret			; 0 invalid
	.word	t_html			; 1 <html>
	.word	t_head			; 2 <head>
	.word	t_title			; 3 <title>
	.word	t_body			; 4 <body>
	.word	t_p				; 5 <p>
	.word	t_h1			; 6 <h1>
	.word	t_br			; 7 <br />
	.word	t_hr			; 8 <hr />
	.word	t_link			; 9 <a>
	.word	tag_ret			; 10 invalid too
	.word	tc_html			; 11 </html>
	.word	tc_head			; 12 </head>
	.word	tc_title		; 13 </title>
	.word	tc_body			; 14 </body>
	.word	tc_p			; 15 </p>
	.word	tc_h1			; 16 </h1>
	.word	tc_br			; 17 <br /> needed?
	.word	tc_hr			; 18 <hr /> needed?
	.word	tc_link			; 19 </a>

; *******************************
; *** tag processing routines ***
; *******************************

t_title:
	LDA flags
	ORA #%00100000		; set d5 as title detected
	STA flags
	LDA #'['			; print title delimiter... will return
	JMP mg_out

t_p:
tc_p:
	JMP block			; block element must use CRs... will return

t_h1:
	LDA flags
	ORA #%10000000		; set d7 as heading detected
	JMP block			; block element must use CRs... will return

t_br:
	LDA #CR				; print newline... and return
	JMP mg_out

t_hr:
; draw a line... TO DO
	JSR block			; this is a block element
	LDX #20				; number of dashes
thr_loop:
		_PHX				; just in case
		LDA #'-'			; print a dash
		JSR mg_out
		_PLX
		DEX					; one less to go
		BNE thr_loop
tag_ret:				; ** generic exit point **
	RTS

t_link:
tc_link:
	LDA #'_'			; print link delimiter... and return
	JMP mg_out

; closing tags
tc_head:
	LDA flags
	AND #%00100000		; was a title detected?
		BNE tag_ret			; yes, do nothing
	LDA #'['			; no, print empty brackets
	JSR mg_out
tc_title:
	LDA #']'
	JMP mg_out

; *************************
; *** several functions ***
; *************************

push:
; * push token in A into internal stack (returns A, or 0 if full) *
	LDX pila_sp
	CPX #STK_SIZ		; already full?
	BNE ps_ok			; no, go for it
		LDA #0				; yes, return error
		RTS
ps_ok:
	STA pila_v, X		; store into stack
	INC pila_sp			; post-increment
	RTS

pop:
; * pop token from internal stack into A (0=empty) *
	LDX pila_sp			; is it empty?
	BNE pl_ok			; no, go for it
		LDA #0				; yes, return error
		RTS
pl_ok:
	DEC pila_sp			; pre-decrement
	LDA pila_v, X		; pull from stack
	RTS

look_tag:
; * detect tags from offset pt and return token number in A (+CLOSING if closing, zero if invalid) *
	LDX #0				; reset scanning index
	LDY #1				; reset short range index, note < is skipped [pos=start...]
	STY cnt				; reset token counter [token=1]
; scanning loop, will use tmp as working pointer, retrieving value from pt instead
lt_loop:				; [while (-1) {]
		LDA (tmp), Y		; looking for '/'
		CMP #'/'			; closing tag?  [if (tx[pos] == '/') {]
		BNE no_close		; not, do no pop
			JSR pop			; yes, pop last registered tag [token=pop()]
			CLC
			ADC #CLOSING		; no longer ones complement...
			RTS					; [return -token]
no_close:					; [}]
lt_sbstr:
; find matching substring
			LDA tags, X			; char in tag list... [while (tags[cur]] 
			CMP (tmp), Y		; ...against source [== tx[pos]) {]
			BNE lts_nxt			; does not coincide
				INX					; advance both indexes... hopefully 256 bytes from X will suffice!
				INY					; these are [pos++; cur++;}] from scanning while
			BNE lt_sbstr		; no real need for BRA
; first mismatch
lst_nxt:
			CMP #'*'			; tag in list was ended? [if ((tags[--cur] == '*')]
			BNE lt_mis			; no, try next tag [ && ]
				LDA (tmp), Y		; yes, now check for a suitable delimiter in source [del = tx[pos];]
				CMP #'>'			; tag end? [(del=='>' ||]
					BEQ lt_tag			; it is suitable!
				CMP #' '			; space? [del==' ' ||]
					BEQ lt_tag			; it is suitable!
				CMP #CR				; newline (whitespace)? [del=='\n' ||]
					BEQ lt_tag			; it is suitable!
				CMP #HTAB			; tabulator (whitespace)? [del=='\t')) {]
					BNE lt_longer		; if none of the above, keep trying
lt_tag:			LDA tok				; finally return token [return token]
				RTS
lt_longer:
			DEX					; ...as we already are at the end of a listed label [} else {]
lt_mis:
; skip label from list and try next one
			LDY #1				; back to source original position [pos=start]
lts_skip:
				INX					; advance in tag list
				LDA tags, X			; check what is pointing now [while(tags[cur++]]
				CMP #'*'			; label separator? [!='*') ;]
				BNE lst_skip		; not yet, keep scanning
			INC cnt				; another label skipped [token++]
			LDA tags+1, X		; check whether ended [if (tags[cur] == '\0')]
		BNE lt_loop			; not ended, thus may try another [}]
	RTS					; otherwise return 0 (invalid tag)


; ************
; *** data ***
; ************

tags:
	.asc "html*head*title*body*p*h1*br*hr*a*", 0	; recognised tags separated by asterisks!

mgEnd:					; for easy size computation
