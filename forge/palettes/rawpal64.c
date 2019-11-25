#include <stdio.h>

/* RAW 64-colour palette generator
 * (c) 2019 Carlos J. Santisteban
 * last modified 20191125-0913
 */

int main(void) {
	FILE* arch;
	int r,g,b,h,l,i=0;

/* scale arrays */
	int byte[2]={0,255};
	int four[4]={0,85,170,255};
	int RG[4]={32,96,159,223};
	int B[2]={64,192};

/* open output file */
	arch=fopen("minimOS64.pal","w");
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
/* create remaining 32 colours */
	for (r=0;r<4;r++) {
		for (g=0;g<4;g++) {
			for (b=0;b<2;b++) {
				i++;
				fprintf(arch,"%c%c%c",RG[r],RG[g],B[b]);
			}
		}
	}
	fclose(arch);
	printf("Finished palette with %d entries\n",i);

	return 0;
}
