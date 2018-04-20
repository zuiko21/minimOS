; miniGaal, VERY elementary HTML browser for minimOS
; v0.1a3
; (c) 2018 Carlos J. Santisteban
; last modified 20180420-0954

#include "../OS/usual.h"

.(
; *****************
; *** constants ***
; *****************

	STK_SIZ	= 32		; tag stack size

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

	_last	= tx+2

; *** HEADER & CODE TO DO ***

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
; * tag processing * TODO TODO
	INC tx				; skip <... or shoud look_tag initialise Y as 1?
	BNE ct_nw
		INC tx+1
ct_nw:
	JSR look_tag		; try to indentify a tag
	TAY					; is it valid?
	BEQ tag_end			; no, just look for >
		JSR push			; yes, push it into stack
; is this switch best done with indexed jump? surely!
		CMP #3				; <title>
		BNE ct_ntit
			LDA flags
			ORA #%00100000		; set d5 as title detected
			STA flags
			LDA #'['			; print title delimiter
			JSR mg_out
			_BRA tag_end
ct_ntit:
		CMP #5				; <p>
		BNE ct_np
ct_np:
		CMP #6				; <h1>
		BNE ct_nh1
ct_nh1:
		CMP #7				; <br />
		BNE ct_nbr
ct_nbr:
		CMP #8				; <hr />
		BNE ct_nhr
ct_nhr:
		CMP #9				; <a>
		BNE ct_nlnk
			LDA #'_'			; print link delimiter
			JSR mg_out
			_BRA tag_end
ct_nlnk:
; closing tags
		CMP #5				; <p>
		BNE ct_np
ct_np:
		CMP #5				; <p>
		BNE ct_np
ct_np:


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
; * detect tags from offset pt and return token number in A (inverted if CLOSING, zero if invalid) *
	LDX #1				; reset token counter... [token=1]
	STX cnt
	DEX					; ...and scanning index too (could use -1 offset and waive this DEX) [cur=0]
; scanning loop, will use tmp as working pointer, retrieving value from pt instead
lt_loop:				; [while (-1) {]
		LDY #0				; reset short range index [pos=start...]
		LDA (tmp), Y		; looking for '/'
		CMP #'/'			; closing tag?  [if (tx[pos] == '/') {]
		BNE no_close		; not, do no pop
			JSR pop			; yes, pop last registered tag [token=pop()]
			EOR #$FF			; ones complement eeeeeeeeeeeeeeeeeek
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
			LDY #0				; back to source original position [pos=start]
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

; **** old C code follows ****

/*
 * TOKEN numbers (0 is invalid) new base 20180413
 * 1 = html (do nothing)
 * 2 = head (expect for title at least)
 * 3 = title (show betweeen [])
 * 4 = body (do nothing)
 * 5 = p (print text, then a couple of CRs)
 * 6 = h1 (print text _with spaces between letters_)
 * 7 = br (print CR)
 * 8 = hr (print '------------------------------------')
 * 9 = a (link????)
 * */
 /*

/* *** main code ***
int main(void)
{


//if < is found, look for the label
//	push it into stack
//	it may show / before >, then pop it (and disable if style)
//	read until >
/*
	do {
			switch(t) {
				case 1:
				case 4:				// <html> <body> (do nothing)
					break;
				case 2:				// <head> (expect for title at least)
					break;
				case 3:				// <title> (show betweeen [])
					tit=-1;
					printf("\n[");
					break;
				case 5:				// <p> (print text, then a couple of CRs)
					printf("\n\n");
					break;
				case 6:				// <h1> (print text _with spaces between letters_)
					head=-1;
					printf("\n\n");
					break;
				case 7:				// <br> (print CR)
					printf("\n");
					break;
				case 8:				// <hr> (print '------------------------------------')
					printf("\n-----------------------------------------\n");
					break;
				case 9:				// <a> (link????)
					printf("_");
					break;
				// closing tags
				case -1:
				case -4:			// </html> </body> (do nothing)
					break;
				case -2:			// </head> (expect for title at least)
					if (!tit)		printf("\n[]\n");
					break;
				case -3:			// </title> (show betweeen [])
					printf("]\n");
					break;
				case -5:			// </p> (print text, then a couple of CRs)
					printf("\n\n");
					break;
				case -6:			// </h1> (print text _with spaces between letters_)
					head=0;
					printf("\n\n");
					break;
				case -7:			// <br /> (print CR) really needed in autoclose?
//					printf("\n");
					break;
				case -8:			// <hr /> (print '------------------------------------'), really needed?
//					printf("\n-----------------------------------------\n");
					break;
				case -9:			// </a> (link????)
					printf("_");
//					break;
//				default:
//					prinf("<?>");
			}
			while ((tx[pt++] != '>') && (tx[pt-1]!='\0')) {
#ifdef	DEBUG
				printf("%c>",tx[pt-1]);
#endif
				if (tx[pt-1] == '/') {	// it is a closing tag
					t=pop();			// try to pull it from stack
#ifdef	DEBUG
					printf("[POP %d]", t);
#endif
				}
					
			}
		}
		else {
	} while (tx[pt]!='\0');

	return 0;
}
