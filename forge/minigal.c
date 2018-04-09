/*
 * miniGal, elementary HTML browser for minimOS
 * last modified 20180409-1343
 * */

#include <stdio.h>

char tags[] = { "html", "head", "title", "body", "p", "h1", "br" };

int looktag(int pos) {
	int start=pos;
	int lista=0;
	while (file[pos++] == tags[lista++]);	// keep comparing
	if (file[pos] == '\0' && tags[lista] == '\0') {		//found
	}
	
	return pos;
}

int main(void)
{
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
