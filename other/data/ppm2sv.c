/* PPM to SV image converter     */
/* assume 128x128 4bpp GRgB D0-3 */
/* (C)2021 Carlos J. Santisteban */
/* last modified 20210903-0031   */

#include <stdio.h>

int main(void) {
	FILE*	f;
	FILE*	o;
	unsigned int	r, g, gh, gl, b, s;
	unsigned char	c;
	char	nombre[80];

/* ask for filename and open files */
	printf("File: ");
	fgets(nombre, 80, stdin);
	s=0;
	while (nombre[s]!='\n' && nombre[s]!='\0')	{s++;}
	nombre[s]=0;			/* add termination */
	printf("Opening %s...\n", nombre);
	f=fopen(nombre, "rb");
	if (f==NULL) {
		printf("*** no file ***\n");
		return -1;
	}
	o=fopen("output.sv", "wb");
	if (o==NULL) {
		printf("*** cannot write ***\n");
		return -1;
	}
/* skip header, may check things */
	if ((fgetc(f)!='P')||(fgetc(f)!='6')) {
		printf("*** wrong file type ***\n");
		return -1;
	}
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
		fputc(c, o);
	} while(!feof(f));
/* clean up */
	fclose(f);
	fclose(o);

	return 0;
}
