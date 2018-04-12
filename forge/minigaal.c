/*
 * miniGaal, VERY elementary HTML browser for minimOS
 * last modified 20180412-1425
 * */

#include <stdio.h>

// Global variables
char tx[1000], c;		// the HTML input

struct pila {
	int		sp;
	char	v[32];
} etiq;					// detected tags stack

char tags[] = "html*head*title*body*p*h1*br*hr*\0" ;	// recognised tags separated by asterisks!
/*
 * TOKEN numbers (-1 is invalid)
 * 0 = html (do nothing)
 * 1 = head (expect for title at least)
 * 2 = title (show betweeen [])
 * 3 = body (do nothing)
 * 4 = p (print text, then a couple of CRs)
 * 5 = h1 (print text _with spaces between letters_)
 * 6 = br (print CR)
 * 7 = hr (print '------------------------------------')
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

int looktag(int pos) {
	int start=pos;		// keep this position for retying
	int lista=0;		// label-list scanning pointer
	int found=0;		// will scan until found...
	int ended=0;		// ...or the tag list ends
	int token=0;		// token list counter
	char del;			// found delimiter

	while (!found && !ended) {
		while (tx[pos++] == tags[lista++])	printf("%c...",tx[pos-1]);	// scan until end of label, either way, or any difference found
		del = tx[pos-1];						// check whatever ended the label
		printf("\n(delimiter %c, lista %c)", del, tags[lista-1]);
		if ((tags[--lista] == '*') && (del==' ' || del=='\t' || del=='\n' || del=='>' || del=='/')) {
			// found a proper delimiter for this tag
			found=1;							// we have found a label!
			printf("OK\n");
		} else {
			printf("<No>");
			// different label, skip from list and try next one
			if (tags[lista+1] == 0) {			// was it the last one?
				ended=1;						// no more to scan
			} else {
				pos=start;						// otherwise will try next, back where it started
				while(tags[lista++]!='*');		// skip current tag
				token++;
			}
		}
		if (found) {	// properly recognised tag, push it into stack!
printf("[%d OK]", token);
			if(push(token)==-1)	printf("{***OVERFLOW***}");		// try to push the token
			
		} else {
			printf("{?}");
			pos=start+1;
		}
	}
	
	return --pos;
}

// *** main code ***
int main(void)
{
	int pt=0, t;

// init code
	etiq.sp = 0;		// reset stack pointer!

	fgets(tx, 1000, stdin);	// read keyboard

//if < is found, look for the label
//	push it into stack
//	it may show / before >, then pop it (and disable if style)
//	read until >


	do {
		c = tx[pt++];
		if (c=='<') {		// tag is starting
		// should look for comments here
			pt=looktag(pt);		// detect token and execute
			while (tx[pt++] != '>') {
				printf("%c·",tx[pt-1]);
				if (tx[pt-1] == '/') {	// it is a closing tag
					t=pop();			// try to read from stack
				}
					
			}	// look for the end of the tag
		}
		else {
			printf("%c", c);
		}
	} while (tx[pt]!='\0');

	return 0;
}
