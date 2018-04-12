/*
 * miniGaal, VERY elementary HTML browser for minimOS
 * last modified 20180412-1318
 * */

#include <stdio.h>

// Global variables

struct pila {
	int		sp;
	char	v[32];
} etiq;

char tags[] = "html*head*title*body*p*h1*br\0" ;	// recognised tabs separated by asterisks!

// Several functions
char push(char token) {		// push a tokenised tag into stack
	if ((etiq.sp)<32) {
		etiq.v[(etiq.sp)++] = token;
		return token;
	} else {
		return -1;			// stack overflow!
	}
}

char pop(void) {			// pop a tokenised tag from stack
	if (etiq.sp>0) {
		return etiq.v[--(etiq.sp)];
	} else {
		return -1;			// stack is empty
	}
}

int looktag(int pos, char f[]) {
	int start=pos;		// keep this position for retying
	int lista=0;		// label-list scanning pointer
	int found=0;		// will scan until found...
	int ended=0;		// ...or the tag list ends
	int token=0;		// token list counter
	char del;			// found delimiter

	while (!found && !ended) {
		while (f[pos++] == tags[lista++]);	// scan until end of label, either way, or any difference found
		del = f[pos];						// check whatever ended the label
		if ((tags[lista] == '*') && (del==' ' || del=='\t' || del=='\n' || del=='>' || del=='/')) {
			// found a proper delimiter for this tag
			found=1;							// we have found a label!
		} else {
			// different label, skip from list and try next one
			if (tags[lista++] != 0) {			// was it the last one?
				ended=1;						// no more to scan
			} else {
				pos=start;						// otherwise will try next, back where it started
				token++;
			}
		}
		if (!ended) {	// properly recognised tag, push it into stack!
printf("OK");
		}
	}
	
	return pos;
}

// *** main code ***
int main(void)
{
	char file[1000], c;
	int pt=0;

// init code
	etiq.sp = 0;		// reset stack pointer!

	fgets(file, 1000, stdin);	// read keyboard

//if < is found, look for the label
//	push it into stack
//	it may show / before >, then pop it (and disable if style)
//	read until >


	do {
		c = file[pt++];
		if (c=='<') {	// tag is starting
			pt=looktag(pt, file);
			while (file[pt++] != '>');	// look for the end of the tag
		}
		else {
			printf("%c", c);
		}
	} while (file[pt]!='\0');

	return 0;
}
