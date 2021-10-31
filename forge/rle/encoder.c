/* RLE encoder for minimOS        *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20211031-1756    */

#include <stdio.h>

/* function declarations */
void	send_u(void);			// go backwards and send uncompressed chunk

/* global variables, WTF */
	char	src[32768];			// just in case, read whole input file
	FILE*	f;					// file handler, both source and output as not simultaneous
	int		i;					// i = source index
	int		siz, unc, count, output;
	int		clocks = 0;			// estimated 6502 decompression time!

/* main code */
int		main(void) {
	char	base;				// repeated character
	char	name[80];			// input filename
	int		thres;				// compression threshold (usually 2 is optimum, but ~19 is faster)
/* read source file into memory */
	printf("File to compress: ");
	scanf("%s", name);			// does this put terminator? I think so
	f = fopen(name, "rb");		// open source file
	if (f==NULL) {
		printf("\n*** No input file ***\n");
		return -1;
	}
	fseek(f, 0, SEEK_END);		// go to the end for a moment
	siz = ftell(f);				// get length
	fseek(f, 0, SEEK_SET);		// back to start
	if (siz>32768) {
		printf("\n*** File is too large ***\n");
		return -2;
	}
	fread(src, 1, siz, f);		// read file into memory
	fclose(f);					// all done with input
/* prepare output file */
	f = fopen("source.rle", "wb");		// get ready for output file
	if (f==NULL) {
		printf("\n*** Cannot create output file ***\n");
		return -3;
	}
/* compress array */
	printf("Compression threshold? (optimum ~2): ");
	scanf("%d", &thres);

	i = output = 0;				// cursor and output size reset
	unc = 0;					// this gets reset every time but first
	while (i < siz) {
		base = src[i++];		// read this first byte and point to following one
		count = 1;				// assume not yet repeated
		while (src[i]==base && count<127 && i<siz) {	// next one is the same?
			count++;									// count it
			i++;										// and check the next one
		}
		if (count>thres) {		// any actual repetition?
			if (unc)
				send_u();		// send previous uncompressed chunk, if any!
			fputc(count, f);	// first goes 'command', positive means repeat following byte
			fputc(base, f);		// this was the repeated value
			output += 2;
			clocks += 47+13*count;
		} else {
			unc+=count;			// different, thus more for the uncompressed chunk EEEEEEK
			if (unc>=128) {
				send_u();		// cannot add more to chunk
			}
		}
	}
/* input stream ended, but check for anything in progress! */
	count=0;					// EEEEEEEEEEEK
	if (unc)
		send_u();				// send uncompressed chunk in progress!

/* end output stream and cleanout */
	fputc(0, f);				// end of stream
	output++;
	fclose(f);
	printf("\nDone! Encoded %d bytes into %d (%d%%)\n", siz, output, 100*output/siz);
	printf("Estimated 6502 timing: %d clock cycles\n", clocks);

	return 0;
}

/* function definitions */
void	send_u(void) {	// go backwards and send uncompressed chunk
	int		x, y;				// x = uncompressed chunk index, y = min(unc,128)

	x = i - unc - count;		// compute start of chunk
	y = (unc<128)?unc:128;		// cannot sent more than 128 in a chunk
	clocks += 46+18*y;
	fputc(-y, f);				// negative 'command' means length of uncompressed chunk EEEEK
	output++;
	while (y--) {
		fputc(src[x++], f);		// send uncompressed byte
		output++;
		unc--;					// may NOT finish as 0
	}
}
