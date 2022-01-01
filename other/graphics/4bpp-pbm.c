/* 4 bpp PPM image converter           *
 * assume GRgB (d0...d3) 128x128       *
 * (c) 2021-2022 Carlos J. Santisteban *
 * last modified 20210401-1157         *
 */

#include <stdio.h>
#include <string.h>

const int max_x	= 128;
const int max_y = 128;

int main(void) {
	FILE	*f, *o;
	int		i, j, r, g, b, ch;
	char	nom[80];

	printf("RGB PBM filename: ");
	scanf("%s", nom);
	f=fopen(nom, "rb");
	if (f==NULL) {
		printf("NO FILE!!!\n");
		return -1;
	} else {
		strcat(nom,".sv");
		o=fopen(nom, "wb");
		if (o==NULL) {
			printf("Cannot output picture!\n");
			return -2;
		} else {
			fseek(f, 15, SEEK_SET);	// Skip Photoshop header
			for (i=0; i<max_y; i++) {
				for (j=0; j<max_x; j+=2) {
					ch=0;
					r=fgetc(f);
					g=fgetc(f);
					b=fgetc(f);
					if (r)	ch|=32;
					if (b)	ch|=128;
					g>>=6;
					if (g&2)	ch|=16;
					if (g&1)	ch|=64;
					r=fgetc(f);
					g=fgetc(f);
					b=fgetc(f);
					if (r)	ch|=2;
					if (b)	ch|=8;
					g>>=6;
					if (g&2)	ch|=1;
					if (g&1)	ch|=4;
					fputc(ch, o);
					if (feof(f))	break;
				}
				if (feof(f))	break;
			}
			fclose(o);
		}
		fclose(f);
		printf("%d rows OK\n", i);
	}
	return 0;
}
