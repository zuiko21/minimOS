/*
 * miniGaal, VERY elementary HTML browser for minimOS
 * (c) 2018-2021 Carlos J. Santisteban
 * last modified 20180416-1056
 * */

#include <stdio.h>

// Global variables
char tx[1000];			// the HTML input

struct pila {
	int		sp;
	char	v[32];
} etiq;					// detected tags stack

char tags[] = "html*head*title*body*p*h1*br*hr*a*\0" ;	// recognised tags separated by asterisks!
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
 
// Several functions
char push(char token) {		// push a tokenised tag into stack, return tag# or -1 if full!
	if ((etiq.sp)<32) {
		etiq.v[(etiq.sp)++] = token;
		return token;
	} else {
		return 0;			// stack overflow!
	}
}

char pop(void) {			// pop a tokenised tag from stack, or -1 if empty
	if (etiq.sp>0) {
		return etiq.v[--(etiq.sp)];
	} else {
		return 0;			// stack is empty
	}
}

char tag(int pos) {		// detect tags and return token number (negative if CLOSING, zero if invalid)
	int start=pos;			// keep this position for retrying
	int cur=0;				// label-list scanning index
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
#ifdef	DEBUG
				printf("[CLOSE %d]", token);
#endif
				// do something here?
			}
			return -token;			// report it and do not look further, NOTE SIGN
		}
		// find a matching substring
		while (tx[pos++] == tags[cur++]) {
#ifdef	DEBUG
			printf("%c...",tx[pos-1]);
#endif
		}
		// check whether there is a recognised tag, or a mismatch
		del = tx[pos-1];			// check whatever ended the label
#ifdef	DEBUG
		printf("\n(delimiter %c, lista %c)", del, tags[cur-1]);
#endif
		if ((tags[--cur] == '*') && (del==' ' || del=='\t' || del=='\n' || del=='>' || del=='/')) {
			// found a proper delimiter for this tag
#ifdef	DEBUG
			printf("OK\n");
#endif
			return token;				// is this OK already?
		} else {					// string did not match label
#ifdef	DEBUG
			printf("<No>");
#endif
			if (tags[cur+1] == '\0') {	// was it the last one?
#ifdef	DEBUG
				printf("{EOL}\n");
#endif
				return 0;					// no more to scan
			} else {
				// skip label from list and try next one
				pos=start;					// otherwise will try next, back where it started
				while(tags[cur++]!='*') {
#ifdef	DEBUG
					printf("_%c", tags[cur-1]);		// skip current tag
#endif
				}
				token++;
				if (tags[cur] == '\0')		return 0;	// no more tags to scan!
			}
		}
	}
}

/*
// no more here...
		if (found) {
			// properly recognised tag, push it into stack!
			printf("[%d OK]", token);
			token = push(token);	// try to push the token
			if (!token)				printf("{***OVERFLOW***}");
			// perhaps should check for effects here?
		} else {	// *** I think it will NEVER reach here... ***
			printf("{?}");
			pos=start;
		}
	}
 * */

// *** main code ***
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
