#include <stdio.h>

/* RAW 128-colour palette generator
 * (c) 2019-2021 Carlos J. Santisteban
 * last modified 20191125-0856
 */

int main(void) {
	FILE* arch;
	int r,g,b,h,l,i=0;

/* scale arrays */
	int byte[2]={0,255};
	int four[4]={0,85,170,255};
	int B[4]={32,96,159,223};
	int G[8]={16,48,80,112,143,175,207,239};
	int R[3]={42,128,213};

/* open output file */
	arch=fopen("minimOS128.pal","w");
	if (arch==NULL) {
		printf("*** CANNOT WRITE ***\n");
		return -1;
	}
/* create system colours */
	for (h=0;h<2;h++) {
		for (r=0;r<2;r++) {
			for (l=0;l<2;l++) {
				for (b=0;b<2;b++) {
					i++;
					g=(h<<1)|l;
					fprintf(arch,"%c%c%c",byte[r],four[g],byte[b]);
				}
			}
		}
	}
	printf("Created %d system colours\n",i);
/* create system greyscale */
	for (g=15;g<255;g+=15) {
		i++;
		fprintf(arch,"%c%c%c",g,g,g);
	}
	printf("Added system greyscale (total %d entries)\n",i);
/* create remaining 96 colours */
	for (r=0;r<3;r++) {
		for (l=0;l<2;l++) {
			for (g=0;g<8;g++) {
				for (h=0;h<2;h++) {
					i++;
					b=(h<<1)|l;
					fprintf(arch,"%c%c%c",R[r],G[g],B[b]);
				}
			}
		}
	}
	fclose(arch);
	printf("Finished palette with %d entries\n",i);

	return 0;
}
