#include <stdio.h>

/* GIMP palette generator
 * (c) 2019 Carlos J. Santisteban
 * last modified 20191017-2302
 */

int main(void) {
	FILE* arch;
	int r,g,b,h,l,i=0;

/* scale arrays */
	int byte[2]={0,255};
	int four[4]={0,85,170,255};
	int B[4]={32,96,159,223};
	int G[8]={16,48,80,112,143,175,207,239};
	int R[7]={18,55,91,128,164,200,237};

/* open output file */
	arch=fopen("minimOS.gpl","w");
	if (arch==NULL) {
		printf("*** CANNOT WRITE ***\n");
		return -1;
	}
/* GIMP palette header */
	fprintf(arch,"GIMP Palette\nName: minimOS\nColumns: 16\n#\n");
/* create system colours */
	for (h=0;h<2;h++) {
		for (r=0;r<2;r++) {
			for (l=0;l<2;l++) {
				for (b=0;b<2;b++) {
					g=(h<<1)|l;
					fprintf(arch,"%d %d %d\tIndex %d\n",byte[r],four[g],byte[b],i++);
				}
			}
		}
	}
	printf("Created %d system colours\n",i);
/* create system greyscale */
	for (g=15;g<255;g+=15) {
		fprintf(arch,"%d %d %d\tIndex %d\n",g,g,g,i++);
	}
	printf("Added system greyscale (total %d entries)\n",i);
/* create remaining 224 colours */
	for (r=0;r<7;r++) {
		for (l=0;l<2;l++) {
			for (g=0;g<8;g++) {
				for (h=0;h<2;h++) {
					b=(h<<1)|l;
					fprintf(arch,"%d %d %d\tIndex %d\n",R[r],G[g],B[b],i++);
				}
			}
		}
	}
	fclose(arch);
	printf("Finished palette with %d entries\n",i);

	return 0;
}
