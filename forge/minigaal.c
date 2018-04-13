/*
 * miniGaal, VERY elementary HTML browser for minimOS
 * last modified 20180413-1014
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
		return -1;			// stack overflow!
	}
}

char pop(void) {			// pop a tokenised tag from stack, or -1 if empty
	if (etiq.sp>0) {
		return etiq.v[--(etiq.sp)];
	} else {
		return -1;			// stack is empty
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
				printf("[CLOSE %d]", token);
				// do something here?
			}
			return -token;			// report it and do not look further, NOTE SIGN
		}
		// find a matching substring
		while (tx[pos++] == tags[cur++]) {
			printf("%c...",tx[pos-1]);
		}
		// check whether there is a recognised tag, or a mismatch
		del = tx[pos-1];			// check whatever ended the label
		printf("\n(delimiter %c, lista %c)", del, tags[cur-1]);
		if ((tags[--cur] == '*') && (del==' ' || del=='\t' || del=='\n' || del=='>' || del=='/')) {
			// found a proper delimiter for this tag
			printf("OK\n");
			return token;				// is this OK already?
		} else {					// string did not match label
			printf("<No>");
			if (tags[cur+1] == '\0') {	// was it the last one?
				printf("{EOL}\n");
				return 0;					// no more to scan
			} else {
				// skip label from list and try next one
				pos=start;					// otherwise will try next, back where it started
				while(tags[cur++]!='*')	printf("_%c", tags[cur-1]);		// skip current tag
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
			printf("\nTag ");
			t=tag(pt);			// detect token
			// identify and execute the token
			switch(t) {
				case 1:				// <html> (do nothing)
					break;
				case 2:				// <head> (expect for title at least)
					break;
				case 3:				// <title> (show betweeen [])
					break;
				case 4:				// <body> (do nothing)
					break;
				case 5:				// <p> (print text, then a couple of CRs)
					break;
				case 6:				// <h1> (print text _with spaces between letters_)
					break;
				case 7:				// <br> (print CR)
					break;
				case 8:				// <hr> (print '------------------------------------')
					break;
				case 9:				// <a> (link????)
					break;
				// closing tags
				case -1:			// <html> (do nothing)
					break;
				case -2:			// <head> (expect for title at least)
					break;
				case -3:			// <title> (show betweeen [])
					break;
				case -4:			// <body> (do nothing)
					break;
				case -5:			// <p> (print text, then a couple of CRs)
					break;
				case -6:			// <h1> (print text _with spaces between letters_)
					break;
				case -7:			// <br> (print CR)
					break;
				case -8:			// <hr> (print '------------------------------------')
					break;
				case -9:			// <a> (link????)
					break;
				default:
			}
			while ((tx[pt++] != '>') && (tx[pt-1]!='\0')) {
				printf("%c>",tx[pt-1]);
				if (tx[pt-1] == '/') {	// it is a closing tag
					t=pop();			// try to pull it from stack
					printf("[POP %d]", t);
				}
					
			}
		}
		else {
			printf(":%c", c);
		}
	} while (tx[pt]!='\0');

	return 0;
}
