; miniGaal, VERY elementary HTML browser for minimOS
; v0.1a1
; (c) 2018 Carlos J. Santisteban
; last modified 20180418-1107

#include "../OS/usual.h"

; ****************************
; *** zeropage definitions ***
; ****************************

	flags	= uz		; several flags
	tok		= flags+1	; decoded token
	del		= tok+1		; delimiter
	tmp		= del+1		; temporary use
	lst		= tmp+1		; tag scanning, temporary?
	pt		= lst+1		; cursor (16b)
	pila_sp	= pt+2		; stack pointer
	pila_v	= pila_sp+1	; stack contents (32)
	tx		= pila_v+32	; pointer to source (16b)

	_last	= tx+2

; *** HEADER & CODE TO DO ***

; *************************
; *** several functions ***
; *************************

push:
; * push token in A into internal stack (returns A, or 0 if full) *
	LDX pila_sp
	CPX #32				; already full?
	BNE ps_ok			; no, go for it
		LDA #0				; yes, return error
		RTS
ps_ok:
	STA pila_v, X		; store into stack
	INC pila_sp			; post-increment
	RTS

;950857000 ALCER Y PABLO

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
	LDY pt				; get original pointer
	LDA pt+1
	STY tmp				; store working copy
	STA tmp+1
	LDX #0				; reset scanning index
	LDY #1				; token counter
; scanning loop... TO DO 


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

	char token=1;			// token list counter
	char del;				// found delimiter

	while (-1) {
		// beware of closing tags
		if (tx[pos] == '/') {	// it is a closing tag
			token=pop();			// try to pull token from stack
			if (!token) {
				printf("{EMPTY}");
			}
			else
			{
				// do something here?
			}
			return -token;			// report it and do not look further, NOTE SIGN
		}
		// find a matching substring
		while (tx[pos++] == tags[cur++]) {
		}
		// check whether there is a recognised tag, or a mismatch
		del = tx[pos-1];			// check whatever ended the label
		if ((tags[--cur] == '*') && (del==' ' || del=='\t' || del=='\n' || del=='>' || del=='/')) {
			// found a proper delimiter for this tag
			return token;				// is this OK already?
		} else {					// string did not match label
			if (tags[cur+1] == '\0') {	// was it the last one?
				return 0;					// no more to scan
			} else {
				// skip label from list and try next one
				pos=start;					// otherwise will try next, back where it started
				while(tags[cur++]!='*') {
				}
				token++;
				if (tags[cur] == '\0')		return 0;	// no more tags to scan!
			}
		}
	}
}
*/
/* *** main code ***
int main(void)
{
	int pt=0, t;
	char c;
	int tit=0;			// flag if title is defined
	int head=0;			// flag for heading mode

// init code
	etiq.sp = 0;				// reset stack pointer!
	printf("HTML input: ");
	fgets(tx, 1000, stdin);		// read HTML from keyboard

//if < is found, look for the label
//	push it into stack
//	it may show / before >, then pop it (and disable if style)
//	read until >
/*
	do {
		c = tx[pt++];
		if (c=='<') {		// tag is starting
		// should look for comments here
#ifdef	DEBUG
			printf("\nTag ");
#endif
			t=tag(pt);			// detect token
			if (t)		push(t);	// push the token!
			// identify and execute the token
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
#ifdef	DEBUG
			printf(":");
#endif
			printf("%c", c);
			if (head)	printf(" ");
		}
	} while (tx[pt]!='\0');

	return 0;
}
