/* RLE encoder for minimOS        *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20211030-1648    */

#include <stdio.h>

/* function declarations and definitions */
void	send_u(int i, int u, int c) {	// go backwards and send uncompressed chunk
	int		x;					// x = uncompressed chunk index

	fputc(-u, f);				// negative 'command' means length of uncompressed chunk
	x = i - u - c;				// compute start of chunk
	while (u--) {
		fputc(src[x++]);		// send uncompressed byte
	}
}

/* main code */
int		main(void) {
	char	src[32768];			// just in case, read whole input file
	char	b;					// repeated character
	int		s, u, c, o;			// s = original size, u = uncompressed length, c = counted repetitions, o = output size
	int		i, x;				// i = source index, x = start of uncompressed chunk
	char	name[80];			// input filename
	FILE*	f;					// file handler, both source and output as not simultaneous

/* read source file into memory */
	printf("File to compress: ");
	scanf("%s", name);			// does this put terminator? I think so
	f = fopen(name, "rb");		// open source file
	if (f==NULL) {
		printf("\n*** No input file ***\n");
		return -1;
	}
	fseek(f, 0, SEEK_END);		// go to the end for a moment
	s = ftell(f);				// get length
	fseek(f, 0, SEEK_SET);		// back to start
	if (s>32768) {
		printf("\n*** File is too large ***\n");
		return -2;
	}
	fread(src, 1, s, f);		// read file into memory
	fclose(f);					// all done with input
/* prepare output file */
	f = fopen("source.rle", "wb");		// get ready for output file
	if (f==NULL) {
		printf("\n*** Cannot create output file ***\n");
		return -3;
	}
/* compress array */
	i = 0;						// cursor reset
	u = 0;						// this gets reset every time but first
	while (i < size) {
		b = src[i++];			// read this first byte and point to following one
		c = 1;					// assume not yet repeated
		while (src[i]==b && c<127) {	// next one is the same?
			c++;						// count it
			i++;						// and check the next one
		}
		if (c>1) {				// any actual repetition?
			send_u(i, u, c);	// send previous uncompressed chunk, if any!
			u = 0;
			fputc(c, f);		// first goes 'command', positive means repeat following byte
			fputc(b, f);		// this was the repeated value
		} else {
			u++;				// different, thus one more for the uncompressed chunk
			if (u==128) {
				send_u(i, u, c);		// cannot add more to chunk
				u = 0;
			}
		}
	}
	fputc(0, f);				// end of stream
	fclose(f);

	return 0;
}
