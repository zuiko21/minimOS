/*
 * PGM font viewer for minimOS bitmaps *
 * (C) 2019-2021 Carlos J. Santisteban *
 * Last modified: 20210201-1617        *
 */

#include <stdio.h>
#include <string.h>

int main(void) {
	FILE *font, *pgm;			// file handlers
	char name[100];				// filename
	unsigned char mat[16][16][16];	// matrix for row, column, scanline
	unsigned char c, mask;			// no longer unsigned char?
	int i, j, k, z, top;
	int y;					// scanlines per char, assume 8-bit width

// select input file
	printf("Font bitmap? ");
	fgets(name, 100, stdin);
	printf("Scanlines? (max. 16) ");
	scanf(" %d", &y);
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
		pgm=fopen(name, "w");
		if (pgm==NULL) {		// error handling
			printf("Cannot output picture!\n");
		} else {
// proceed! first read whole font in matrix
			top = j = 0;		// reset row and column counters
			while (!feof(font) && top<16) {
				for (k=0; k<y; k++) {
					mat[top][j][k]=fgetc(font);	// read byte into matrix
				}
				if ((++j) == 16) {				// column wrap
					j=0;
					++top;
				}
			}
			printf("All read! (%d)\n", y);
			fclose(font);
// create PGM header, in ASCII mode
			fprintf(pgm, "P2\n145 %d\n2\n", 17+y*top);
// then create picture from matrix contents
			for(i=0; i<top; i++) {
				printf("Row %d of 16 columns...\n", i);
				for (z=0; z<16; z++)	fprintf(pgm,"\n1 1 1 1 1 1 1 1 1");
				fprintf(pgm, " 1\n");
				for (k=0; k<y; k++) {		// first scanline, then column
					for (j=0; j<16; j++) {
						fprintf(pgm, "\n1");	// 1px grey at left
						for (mask=128; mask>0; mask>>=1) {
							if (mask & mat[i][j][k])	fprintf(pgm, " 0");	// black ink
							else						fprintf(pgm, " 2");	// white paper
						}
					}
					fprintf(pgm, " 1\n");	// 1px grey at right
				}
			}
			for (z=0; z<16; z++)	fprintf(pgm,"\n1 1 1 1 1 1 1 1 1");
			fprintf(pgm, " 1\n");
// clean up
			fclose(pgm);
			printf("Success!\n");
		}
	}

	return 0;
}
