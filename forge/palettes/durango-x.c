/* *** Durango-X palette generator for GIMP ***
 * *** (c) 2023 Carlos J. Santisteban       ***
 * *** last modified 20230508-1332          *** */

#include <stdio.h>

int main(void) {
	FILE* arch;
	int r,g,b,h,l,i=0;

/* scale arrays */
	int G[4]={0,85,170,255};
	int RB[2]={0,255};

/* open output file */
//	arch=fopen("durango-x.gpl","w");
	arch=fopen("stdout","w");

	if (arch==NULL) {
		printf("*** CANNOT WRITE ***\n");
		return -1;
	}
/* GIMP palette header */
	fprintf(arch,"GIMP Palette\nName: Durango-X\nColumns: 16\n#\n");
/* create system colours */
	for (h=0;h<2;h++) {
		for (r=0;r<2;r++) {
			for (l=0;l<2;l++) {
				for (b=0;b<2;b++) {
					g=(h<<1)|l;
					fprintf(arch,"%d %d %d\tIndex %d\n",RB[r],G[g],RB[b],i++);
				}
			}
		}
	}
	printf("Created %d system colours\n",i);
/* create system greyscale */
	for (g=15;g<255;g+=15) {
		fprintf(arch,"%d %d %d\tIndex %d\n",g,g,g,i++);
	}

	fclose(arch);
	printf("Added system greyscale (total %d entries)\n",i);

	return 0;
}
