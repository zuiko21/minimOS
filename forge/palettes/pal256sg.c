/*
 * minimOS palette generator
 * (c) 2019-2020 Carlos J. Santisteban
 * last modified: 20191217-1347
 */

#include <stdio.h>

/* global arrays */
int elbbin[16]	= {0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};	// reversed nibble
int cuatro[4]	= {0, 0x55, 0xAA, 0xFF};
int B[4]		= {32,96,159,223};
int G[8]		= {16,48,80,112,143,175,207,239};
int R[7]		= {18,55,91,128,164,200,237};

int main(void) {
	int rr, gg, bb, r, g, b;
	int i, j, x;
	FILE* f;

/* open output file and abort if error */
	f=fopen("a256col-s.html","w");
	if (f==NULL) {
		printf("No space!\n");
		return -1;
	}
/* create basic HTML header */
	fprintf(f, "<!DOCTYPE html>\n<html>\n\t<head>\n");
	fprintf(f, "\t\t<title>minimOS AUTO palette</title>\n");
	fprintf(f, "\t</head>\n\t<body style='");
	fprintf(f, "font-family:\"DINNeuzeitGrotesk LT Light\", avantgarde, sans-serif;");
	fprintf(f, "text-align:center;'>\n");
	fprintf(f, "\t\t<table border='0'>\n");
/* system GRgB colours, LSB-to-MSB */
	fprintf(f, "\t\t\t<tr>\n");
	for (i=0; i<16; i++) {
		x = i;		// b0g0r0g1 background
		r = x&2 ? 255 : 0;
		b = x&8 ? 255 : 0;
		g = cuatro[((x&1)<<1) | ((x&4)>>2)];
		x = i^1;	// adjacent foreground
		rr = x&2 ? 255 : 0;
		bb = x&8 ? 255 : 0;
		gg = cuatro[((x&1)<<1) | ((x&4)>>2)];
/* generate table cells */
/* select foreground colour for adequate contrast against background */
		fprintf(f, "\t\t\t\t<td style='color:#%.2X%.2X%.2X;", rr, gg, bb);
/* set background */
 		fprintf(f, "background-color:#%.2X%.2X%.2X;'>", r, g, b);
/* continue with actual cell contents */
		fprintf(f, "S%d<br /><span style='font-size:0.7em;'>", i);
		fprintf(f, "%X%X%X</span></td>\n", r&15, g&15, b&15);
	}
	fprintf(f, "\t\t\t</tr>\n");
/* system greyscale */
	fprintf(f, "\t\t\t<tr>\n");
	for (i=0; i<16; i++) {
		x = elbbin[i];
		b = (x+1)*15;		// background grey level
		r = elbbin[i^1];
		g = (r+1)*15;		// foreground grey level (as per inverted index LSB)
/* generate table cells */
/* select foreground colour for adequate contrast against background */
		fprintf(f, "\t\t\t\t<td style='color:#%.2X%.2X%.2X;", g, g, g);
/* set background */
 		fprintf(f, "background-color:#%.2X%.2X%.2X;'>", b, b, b);
/* continue with actual cell contents */
		fprintf(f, "G%d<br /><span style='font-size:0.7em;'>", x+1);
		fprintf(f, "#%.2X</span></td>\n", b);
	}
	fprintf(f, "\t\t\t</tr>\n");
/* proposed remaining colours */
/* high nibble */
	for (i=2; i<16; i++) {
/* low nibble, switch row here */
		fprintf(f, "\t\t\t<tr>\n");
		for (j=0; j<16; j++) {
/* compute colour values and labels */
			r = R[(i-2)>>1];
			g = G[elbbin[j]>>1];
			b = B[(j&8)>>2 | (i&1)];
/* making foreground colour from adjacent index! */
			rr = R[(i-2)>>1];
			gg = G[elbbin[(j^1)]>>1];
			bb = B[((((j^1)&8))>>2) | (i&1)];
/* generate table cells */
/* select foreground colour for adequate contrast against background */
			fprintf(f, "\t\t\t\t<td style='color:#%.2X%.2X%.2X;", rr, gg, bb);
/* set background */
			fprintf(f, "background-color:#%.2X%.2X%.2X;'>", r, g, b);
/* continue with actual cell contents */
			fprintf(f, "$%.2X<br /><span style='font-size:0.5em;'>", i<<4|j);
			fprintf(f, "%.2X%.2X%.2X</span></td>\n", r, g, b);
		}
		fprintf(f,"\t\t\t</tr>\n");
	}
/* complete HTML table */
	fprintf(f, "\t\t</table>\n\t</body>\n</html>");
	fclose(f);

	return 0;
}
