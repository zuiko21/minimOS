#include <stdio.h>

/* luma palette generator
 * (c) 2019 Carlos J. Santisteban
 * last modified 20191004-0928
 */

int main(void) {
	float y;
	int r,g,b,h,l;

	int B[4]={32,96,159,223};
	int G[8]={16,48,80,112,143,175,207,239};
	int R[7]={18,55,91,128,164,200,237};

	for (r=0;r<7;r++) {
		for (l=0;l<2;l++) {
			for (g=0;g<8;g++) {
				for (h=0;h<2;h++) {
					b=h*2+l;
					y=R[r]*0.3+G[g]*0.59+B[b]*0.11;

					if (y<100)	printf(" ");
					printf("%d ",(int)y);
				}
			}
			printf("\n");
		}
	}

	return 0;
}
