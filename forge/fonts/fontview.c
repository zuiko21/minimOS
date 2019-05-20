/* 
 * PGM font viewer for minimOS bitmaps *
 * (C) 2019 Carlos J. Santisteban      *
 * Last modified: 20190520-1233        *
 */
 
#include <stdio.h>
#include <string.h>

int main(void) {
	FILE *font, *pgm;			// file handlers
	char name[100];				// filename
	unsigned char mat[16][16][16];	// matrix for row, column, scanline
	unsigned char c, mask;
	int i, j, k, z;

// select input file
	printf("Font bitmap? ");
	fgets(name, 100, stdin);
// why should I put the terminator on the read string?
	i=0;
	while (name[i]!='\n' && name[i]!='\0')	{i++;}
	name[i]=0;					// filename is ready
	printf("Opening %s font bitmap...\n", name);
	font=fopen(name, "rb");		// binary mode!
	if (font==NULL) {			// error handling
		printf("Could not open font bitmap!\n");
	} else {
// open output file
		strcat(name,".pgm");
		pgm=fopen(name,"w");
		if (pgm==NULL) {		// error handling
			printf("Cannot output picture!\n");
		} else {
// proceed! first read whole font in matrix
			i = j = 0;			// reset row and column counters
			while (!feof(font)) {
				for (k=0; k<16; k++) {
					mat[i][j][k]=fgetc(font);	// read byte into matrix
				}
				if ((++j) == 16) {				// column wrap
					j=0;
					++i;
				}
			}
			printf("All read!\n");
			fclose(font);
// create PGM header, in ASCII mode
			fprintf(pgm, "P2\n145 273\n255\n");
// then create picture from matrix contents
			for(i=0; i<16; i++) {
				for (z=0; z<16; z++)	fprintf(pgm,"128 128 128 128 128 128 128 128 128 128\n");
				for (k=0; k<16; k++) {			// first scanline, then column
					for (j=0; j<16; j++) {
						fprintf(pgm, "\n128");	// 1px grey at left
						for (mask=128; mask>0; mask/=2) {
							if (mask & mat[i][j][k])	fprintf(pgm, "   0");	// black ink
							else						fprintf(pgm, " 255");	// white paper
						}
						fprintf(pgm, " 128\n");	// 1px grey at right
					}
				}
			}
			for (z=0; z<16; z++)	fprintf(pgm,"128 128 128 128 128 128 128 128 128 128\n");
			fprintf(pgm, "\n");
// clean up
			fclose(pgm);
			printf("Success!\n");
		}
	}

	return 0;
}
