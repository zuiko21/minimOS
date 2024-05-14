/* PPM to SV image converter          */
/* assume 128x128 4bpp GRgB D0-3      */
/* (C)2021-2024 Carlos J. Santisteban */
/* last modified 20240514-1840        */

#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[]) {
	FILE*	f;
	FILE*	o;
	unsigned int	r, g, gh, gl, b, s;
	unsigned char	c;
	char	nombre[80];

	if (argc<2) {
		printf("\nUsage: %s filename\n\n", argv[0]);
		return -4;
	}
/* generate output filename */
	strcpy(nombre, argv[1]);
	s=0;
	while (nombre[s]!='\0')	{s++;}
	while (nombre[s]!='.')	{s--;}	// seek extension!
	nombre[++s] = 's';
	nombre[++s] = 'v';
	nombre[++s] = '\0';				// final terminator
/* open files */
	printf("Opening %s...\n", nombre);
	f=fopen(argv[1], "rb");
	if (f==NULL) {
		printf("*** no file ***\n");
		return -1;
	}
	if ((fgetc(f)!='P')||(fgetc(f)!='6')) {
		printf("*** wrong file type ***\n");
		fclose(f);
		return -2;
	}
	o=fopen(nombre, "wb");
	if (o==NULL) {
		printf("*** cannot write ***\n");
		fclose(f);
		return -3;
	}
/* skip header */
	b=0;					/* will count LFs here */
	while (b<4)
		if (fgetc(f)==10)	b++;
	s=255;					/* usual value, may read from header */
	do {
/* read three channels of one pixel */
		r=fgetc(f);
		g=fgetc(f);
		b=fgetc(f);
/* quantise them */
		r=r/s;
		g=g*3/s;			/* green is 0...3 */
		b=b/s;				/* all other channels are 0 or 1 */
		gh=g>>1;
		gl=g&1;
/* create index for leftmost pixel */
		c=b<<7|gl<<6|r<<5|gh<<4;
/* ditto for another pixel */
		r=fgetc(f);
		g=fgetc(f);
		b=fgetc(f);
/* quantise channels */
		r=r/s;
		g=g*3/s;			/* green is 0...3 */
		b=b/s;				/* all other channels are 0 or 1 */
		gh=g>>1;
		gl=g&1;
/* add index for rightmost pixel */
		c|=b<<3|gl<<2|r<<1|gh;
/* write into output file */
		if (!feof(f))	fputc(c, o);
	} while(!feof(f));
/* clean up */
	fclose(f);
	fclose(o);
	printf("OK!\n");

	return 0;
}
