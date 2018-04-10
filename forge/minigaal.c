/*
 * miniGaal, VERY elementary HTML browser for minimOS
 * last modified 20180410-1107
 * */

#include <stdio.h>

// Global variables

struct pila {
	int sp;
	char v[32];
} etiq;					// parsed tags stack

char tags[] = { "html*head*title*body*p*h1*br", 0 };	// recognised tabs separated by asterisks!

// Several functions
char push(char token) {		// push a tokenised tag into stack
	if (sp<32) {
		v[sp++] = token;
		return token;
	} else {
		return -1;			// stack overflow!
	}
}

char pop(void) {			// pop a tokenised tag from stack
	if (sp>0) {
		return v[--sp];
	} else {
		return -1;			// stack is empty
	}

int looktag(int pos) {
	int start=pos;		// keep this position for retying
	int lista=0;		// label-list scanning pointer
	int found=0;		// will scan until found...
	int ended=0;		// ...or the tag list ends
	int token=0;		// token list counter

	while (!found && !ended) {
		while (file[pos++] == tags[lista++]);	// scan until end of label, either way, or any difference found
		del = file[pos];						// check whatever ended the label
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
		}
	}
	
	return pos;
}

// *** main code ***
int main(void)
{
// init code
	etiq.sp = 0;		// reset stack pointer!

//if < is found, look for the label
//	push it into stack
//	it may show / before >, then pop it (and disable if style)
//	read until >


	do {
		c = file[++pt];
		if (c=='<') {	// tag is starting
			pt=looktag(pt+1);
			while (file[pt++] != '>');
		}
		else {
			printf("%c", c);
		}
	} while (true);

	return 0;
}
