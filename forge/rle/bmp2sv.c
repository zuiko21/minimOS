/* BMP decoder to SV format       *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20211105-2041    */

#include <stdio.h>

/* function declarations */
int		word(int);

/* global variables, WTF */
	char	src[32768];			// just in case, read whole input file
	FILE*	f;					// file handler, both source and output as not simultaneous

/* main code */
int		main(void) {
	char	name[80];			// input filename
	int		x, y;				// image size in pizels
	int		bpp, limit;
	
/* read source file into memory */
	printf("File to convert: ");
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
	fread(src, 1, 62, f);		// read header
	if (src[0]!='B' || src[1]!='M') {
		printf("\n*** Not a .BMP ***\n");
		return -3
	}
	x = word(12);				// get image size
	y = word(16);
	bpp = word(28);				// colour depth
	if (bpp == 1)		limit = 256;
	else
		if (bpp == 4)	limit = 128
		else
		{
			printf("\n*** Invalid colour depth ***\n");
			return -4;
		}
	}
	if (x>limit | y>limit) {
		printf("\n*** Image is too large ***\n");
		return -5;
	}
	limit = word(10);			// reuse for offset to image data
	fseek(f, limit, SEEK_SET);	// go to image data start
	siz -= limit;				// actual image data size
	fread(src, 1, siz, f);		// read file into memory
	fclose(f);					// all done with input
/* prepare output file */
	strcat(name, ".sv\0");		// append extension
	f = fopen(name, "wb");		// get ready for output file
	if (f==NULL) {
		printf("\n*** Cannot create output file ***\n");
		return -6;
	}
/* convert laoded image... backwards */


/* end output stream and cleanout */
	fputc(0, f);				// end of stream
	output++;
	fclose(f);
	printf("\nDone! Encoded %d bytes into %d (%d%%)\n", siz, output, 100*output/siz);
	printf("Estimated 6502 timing: %d clock cycles\n", clocks);

	return 0;
}

/* function definitions */
int		word(int pos) {
	return src[pos]|(src[pos]<<8);
}
