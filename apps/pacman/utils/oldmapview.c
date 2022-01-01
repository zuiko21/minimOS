/* Pacman map viewer */
/* (c) 2021-2022 Carlos J. Santisteban */

#include <stdio.h>

int main(void) {
	FILE	*f;
	int		x, y;
	unsigned char	c;

	f=fopen("a.o65","rb");
	if (f==NULL)	return -1;
	for (y=0;y<31;y++) {
		for (x=0; x<32; x++) {
			c=fgetc(f);
			switch(c) {
				case 128:			/* wall */
					printf("#");
					break;
				case 129:			/* base */
					printf("x");
					break;
				case 64:			/* dot */
					printf(".");
					break;
				case 32:			/* pill */
					printf("O");
					break;
				case 0:				/* empty */
					printf(" ");
					break;
				default:
					printf("?");
			}
		}
		printf("\n");
	}
	fclose(f);
	
	return 0;
}
