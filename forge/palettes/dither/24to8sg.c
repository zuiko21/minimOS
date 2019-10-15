/*	24-bit dithering for 8-bit SIXtation palette
 *	(c) 2019 Carlos J. Santisteban
 *	last modified 20191015-1343 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* global variables */
unsigned char levR[7]=	{18, 55, 91, 128, 164, 200, 237};
unsigned char levG[8]=	{16, 48, 80, 112, 143, 175, 207, 239};
unsigned char levB[4]=	{32, 96, 159, 223};
unsigned char grey[16]=	{15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240};

/***********************/
/* auxiliary functions */
/***********************/
long coord(int x, int y, int sx, int sy) {
/* compute offset from coordinates */
	if (x>=sx|y>=sy)	return -1;	/* negative offset means OUT of bounds! */
	return (long)sx*y+x;			/* returns long in case int cannot handle one meg */
}

float luma(unsigned char r, unsigned char g, unsigned char b){
/* return luminance value for selected RGB values */
	return 0.3*r+0.59*g+0.11*b;
}

int prox(unsigned char r, unsigned char g, unsigned char b){
/* find index closest to suggested RGB, based on luma! */
	int i, pos;
	float y, yo, diff=256;			/* sentinel value, as we are looking for the minimum distance in absolute value */

	yo=luma(r, g, b);				/* target luminance */
	for (i=0;i<256;i++) {			/* scan all indexed colours */
		y=luma(palR(i), palG(i), palB(i));		/* luminance for this one */
		if (y<yo) {					/* compute absolute value of difference */
			y=yo-y;
		} else {
			y=y-yo
		}
		if (y<diff) {				/* update minimum if found */
			diff=y;
			pos=i;					/* keep track of found index */
		}
	}

	return i;						/* this is the closest (by luma) indexed colour */
}

unsigned char byte(int v) {
/* trim value to unsigned byte */
	if (v<0)	return 0;			/* check boundaries */
	if (v>255)	return 255;
	return (unsigned char)v;		/* standard uncropped value */
}

unsigned char palR(int i) {
/* get red value from standard palette */
	if (i>31)	return levR[((i&224)>>5)-1];	/* user-defined colours */
	if (i>15)	return grey[i-16];				/* system grayscale */
	return (i&4)?255:0;							/* system colours otherwise */
	}
}

unsigned char palG(int i) {
/* get green value from standard palette */
	unsigned char g;
	if (i>31)	return levG[(i&15)>>1];			/* user-defined colours */
	if (i>15) 	return grey[i-16];				/* system grayscale */
	/* system colours otherwise... a bit more difficult here as uses two bits for green */
	g=((i&8)>>2)|((i&2)>>1);					/* green level 0...3 */
	return g|(g<<2)|(g<<4)|(g<<6);				/* faster multiply by 85 */
}

unsigned char palB(int i) {
/* get blue value from standard palette */
	if (i>31) 	return levB[((i&16)>>3)|(i&1)];	/* user-defined colours */
	if (i>15)	return grey[i-16];				/* system grayscale */
	return (i&1)?255:0;							/* system colours otherwise */
}

/****************/
/* main program */
/****************/
int main(void) {
	char nombre[80];				/* string for filenames, plus read buffer */
	char *pt;						/* temporary pointer */
	unsigned char *R, *G, *B;		/* pointers to dynamically allocated buffers */
	unsigned char r, g, b, i;		/* pixel values PLUS index */
	float dr, dg, db, k;			/* error diffusion plus factor, best with extended range AND SIGNED */
	int sx, sy, x, y;				/* coordinates and limits */
	long xy;						/* complete array offset */
	FILE *fi, *fo;					/* file handlers */

/* get input file */
	printf("PPM file? ");			/* get input filename */
	fgets(nombre, 80, stdin);		/* no longer scanf! */
	fi=fopen(nombre, "r");			/* open input file */
	if (fi==NULL) {
		printf("NO FILE!\n");			/* error handling */
//		return -1;
	}

/* swap extension on filename */
	pt=strstr(nombre, ".ppm");		/* temporary pointer use */
	if (pt==NULL) {				/* extension not found? */
		pt=strstr(nombre, ".PPM");		/* perhaps in uppercase? */
		if (pt==NULL) {
			printf("WRONG TYPE!\n");
			return -1;
		}
	}
	*pt='\0';						/* cut extension off */
	strcat(nombre, ".six");			/* create output filename */
	printf("Output file:%s\n", nombre);

/* prepare output file*/
	fo=fopen(nombre, "wb");			/* open output file */
	if (fo==NULL) {
		printf("CANNOT OUTPUT!\n");	/* error handling */
		return -1;
	}

/* start reading PPM in order to determine size */
sx=1;//1360;	/* placeholders */
sy=1;//768;

/* allocate buffer space */
	R=(unsigned char*)malloc(sx*sy);
	G=(unsigned char*)malloc(sx*sy);
	B=(unsigned char*)malloc(sx*sy);
	if(R==NULL||G==NULL||G==NULL) {
		printf("OUT OF MEMORY!\n");
		return -1;
	}

/* expected format:
P3
#comments after pound sign
#P3 means ASCII pixmap
#width and height in pixels
1360 768
#max value
255
#actual data follows, no more than 76 chars per line
#triplet order is R G B
#whitespace is ignored
*/

/* scan original file for error diffusion */
	for (y=0;y<sy;y++) {
		for (x=0;x<sx;x++) {
			xy=coord(x,y,sx,sy);	/* current pixel, no need to check bounds */
//			if (xy>=0) {			/* not really needed here... */
			r=R[xy];				/* component values */
			g=G[xy];
			b=B[xy];
/* seek nearest colour */
			i=prox(r, g, b);		/* find best match */
			fputc(fo,i);			/* get value into file! */
/* compute error per channel */
			dr=r-palR(i);			/* these are signed! */
			dg=g-palG(i);
			db=b-palB(i);
/* diffuse error */
/* trying floyd-steinberg formula */
			xy=coord(x+1,y,sx,sy);				/* pixel at right */
			if (xy>=0) {						/* add diffusion within bounds */
				k=7/16.0;
				R[xy]=byte(k*dr+R[xy]);
				G[xy]=byte(k*dg+G[xy]);
				B[xy]=byte(k*db+B[xy]);
			}
			xy=coord(x+1,y+1,sx,sy);			/* pixel at down right */
			if (xy>=0) {						/* add diffusion within bounds */
				k=1/16.0;
				R[xy]=byte(k*dr+R[xy]);
				G[xy]=byte(k*dg+G[xy]);
				B[xy]=byte(k*db+B[xy]);
			}
			xy=coord(x,y+1,sx,sy);				/* pixel at down */
			if (xy>=0) {						/* add diffusion within bounds */
				k=5/16.0;
				R[xy]=byte(k*dr+R[xy]);
				G[xy]=byte(k*dg+G[xy]);
				B[xy]=byte(k*db+B[xy]);
			}
			xy=coord(x-1,y+1,sx,sy);			/* pixel at down left */
			if (xy>=0) {						/* add diffusion within bounds */
				k=3/16.0;
				R[xy]=byte(k*dr+R[xy]);
				G[xy]=byte(k*dg+G[xy]);
				B[xy]=byte(k*db+B[xy]);
			}
//			}						/* ...in case of coordinates check */
		}
	}

/* cleanup and exit */
	fclose(fi);
	fclose(fo);
/* THIS FOR DEBUGGING */
	if(R==NULL||G==NULL||G==NULL) {
		printf("OUT OF MEMORY!\n");
		return -1;
	}
/* release memory */
	free(R);
	free(G);
	free(B);

	return 0;
}
