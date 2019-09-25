/*
 * minimOS palette generator
 * (c) 2019 Carlos J. Santisteban
 * last modified: 20190925-0859
 */

#include <stdio.h>

int bin(int d7, int d6, int d5, int d4, int d3, int d2, int d1, int d0) {
	return d7<<7|d6<<6|d5<<5|d4<<4|d3<<3|d2<<2|d1<<1|d0;
}

int main(void) {
	int r0, r1, r2, g0, g1, g2, b0, b1;
	int R, G, B;
	char tr, tg, tb;
	FILE* f;

/* open output file and abort if error */
	f=fopen("256col.html","w");
	if (f==NULL) {
		printf("No file!\n");
		return 1;
	}
/* create basic HTML header */
	fprintf(f,"<html>\n\t<head>\n");
	fprintf(f,"\t\t<title>minimOS palette</title>\n");
	fprintf(f,"\t</head>\n\t<body>\n");
	fprintf(f,"\t\t<table border='0'>\n");
/* high nibble */
	for (r1=0; r1<2; r1++) {
		for (g0=0; g0<2; g0++) {
			for (r0=0; r0<2; r0++) {
				for (b0=0; b0<2; b0++) {
/* low nibble, switch row here */
					fprintf(f,"\t\t\t<tr>\n");
					for (g2=0; g2<2; g2++) {
						for (r2=0; r2<2; r2++) {
							for (g1=0; g1<2; g1++) {
								for (b1=0; b1<2; b1++) {
/* compute colour values and labels */
									R=bin(r2,r1,r0,r2,r1,r0,r2,r1);
									G=bin(g2,g1,g0,g2,g1,g0,g2,g1);
									B=bin(b1,b0,b1,b0,b1,b0,b1,b0);

									tr=48+bin(0,0,0,0,0,r2,r1,r0);
									tg=48+bin(0,0,0,0,0,g2,g1,g0);
									tb=48+bin(0,0,0,0,0,0,b1,b0);
/* generate table cells */
									fprintf(f,"\t\t\t\t<td style='color:");
/* select foreground colour for adequate contrast against background */
									if(tg>'3') {
										fprintf(f,"black");
									} else {
										fprintf(f,"white");
									}
/* continue with actual cell contents */
									fprintf(f,";background-color:rgb(%d,%d,%d);'>%c%c%c</td>\n",R,G,B,tr,tg,tb);
								}
							}
						}
					}
					fprintf(f,"\t\t\t</tr>\n");
				}
			}
		}
	}
/* complete HTML table */
	fprintf(f,"\t\t</table>\n\t</body>\n</html>");
	fclose(f);

	return 0;
}
