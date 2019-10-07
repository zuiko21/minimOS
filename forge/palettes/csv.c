#include <stdio.h>

/* palette generator
 * (c) 2019 Carlos J. Santisteban
 * last modified 20191006-2141
 */

int main(void) {
	FILE* arch;
	int r,g,b,h,l;

/* scale arrays */
	int B[4]={32,96,159,223};
	int G[8]={16,48,80,112,143,175,207,239};
	int R[7]={18,55,91,128,164,200,237};

/* open output file */
/* must check about GPL format... */
	arch=fopen("256col.gpl","w");
	if (arch==NULL) {
		printf("*** CANNOT WRITE ***\n");
		return -1;
	}
/* create system colours */
	for (h=0;h<2;h++) {
		for (r=0;r<2;r++) {
			for (l=0;l<2;l++) {
				for (b=0;b<2;b++) {
					g=h*2+l;
					fprintf(arch,"%d,%d,%d\n",r*255,g*85,b*255);
				}
			}
		}
	}
/* create system greyscale */
	for (g=15;g<255;g+=15) {
		fprintf(arch,"%d,%d,%d\n",g,g,g);
	}
/* create remaining 224 colours */
	for (r=0;r<7;r++) {
		for (l=0;l<2;l++) {
			for (g=0;g<8;g++) {
				for (h=0;h<2;h++) {
					b=h*2+l;
					fprintf(arch,"%d,%d,%d\n",R[r],G[g],B[b]);
				}
			}
		}
	}
	fclose(arch);

	return 0;
}
