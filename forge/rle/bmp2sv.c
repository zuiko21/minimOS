/* BMP decoder to SV format       *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20211106-0927    */

#include <stdio.h>
#include <string.h>

/* function declarations */
int		word(int);

/* global variables, WTF */
	unsigned char	src[32768];			// just in case, read whole input file
	FILE*	f;					// file handler, both source and output as not simultaneous

/* main code */
int		main(void) {
	char	name[80];			// input filename
	int		x, y;				// image size in pizels
	int		siz, pos;			// pixel data length and start
	int		bpp, limit;			// limit = max dimension
	int		ppb;				// pixels per byte
	int		bpl, bpr;			// bytes per line (source and raster)
	int		inverse, i, j;
	
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
		return -3;
	}
	x = word(18);				// get image size
	y = word(22);
	bpp = word(28);				// colour depth
	if (bpp == 1) {
		limit = 256;
		ppb = 8;
		bpr = 32;
/* check whether the palette is inverse or normal */
		if ((src[54]+src[55]+src[56])>(src[58]+src[59]+src[60]))	inverse = 255;	// black on white
		else														inverse = 0;	// white on black, standard mode
	} else {
		if (bpp == 4) {
			limit = 128;
			ppb = 2;
			bpr = 64;
/* should do something here about the palette */
		}
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
	if (word(30)) {				// 0 = non-compressed RGB, as expected
		printf("\n*** Unsupported compression ***\n");
		return -6;
	}
/* all seems OK, let's load the pixel data */
	pos = word(10);				// offset to image data
	fseek(f, pos, SEEK_SET);	// go to image data start
	siz -= pos;					// actual image data size
	fread(src, 1, siz, f);		// read file into memory
	fclose(f);					// all done with input
/* prepare output file */
	strcat(name, ".sv\0");		// append extension
	f = fopen(name, "wb");		// get ready for output file
	if (f==NULL) {
		printf("\n*** Cannot create output file ***\n");
		return -7;
	}
/* convert loaded image... backwards */
	bpl = // EEEEEEEEEEEEEEEEEEK
/* if not full height, add some black lines at the top */
	for (i=0; i<(limit-y)/2; i++) {
		for (j=0; j<bpr; j++) {
			fputc('\0', f);		// send black byte
		}
	}
/* transfer image data! */
	for (i=(y-1)*bpl; i>=0; i-=bpl) {
/* if not full width, add some black pixels to the left */
		for (j=0; j<(limit-x)/ppb/2; j++) {		// this is DANGEROUS
			fputc('\0', f);		// send black byte
		}
/* actual raster */

/* if not full width, add some black pixels to the right */
		for (j=0; j<(limit-x)/ppb/2; j++) {		// this is DANGEROUS
			fputc('\0', f);		// send black byte
		}
	}
/* if not full height, add some black lines at the bottom, note rounding */
	for (i=0; i<(limit-y+1)/2; i++) {
		for (j=0; j<bpr; j++) {
			fputc('\0', f);		// send black byte
		}
	}

/* end output stream and cleanout */
	fclose(f);

	return 0;
}

/* function definitions */
int		word(int pos) {
	return src[pos]|(src[pos+1]<<8);
}
