/*	24-bit dithering for 8-bit SIXtation palette
 *	(c) 2019 Carlos J. Santisteban
 *	last modified 20191029-1353 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char	byt;	// most helpful!

/* global arrays */
byt levR[7]=	{18, 55, 91, 128, 164, 200, 237};
byt levG[8]=	{16, 48, 80, 112, 143, 175, 207, 239};
byt levB[4]=	{32, 96, 159, 223};
byt grey[16]=	{15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240};
byt *R, *G, *B;					// pointers to dynamically allocated buffers
int sx, sy;						// coordinate limits

/************************/
/* auxiliary prototypes */
/************************/
float	uns(float x) {return (x<0?-x:x);}		// absolute value **no prototype**

long	coord(int x, int y);					// compute offset from coordinates
void	diff(int x, int y, float k, int dr, int dg, int db);	// generic diffusion function
void	floyd(int x, int y, int dr, int dg, int db);			// Floyd-Steinberg implementation
void	sierra(int x, int y, int dr, int dg, int db);			// full Sierra implementation
void	atkinson(int x, int y, int dr, int dg, int db);			// Atkinson implementation
void	burkes(int x, int y, int dr, int dg, int db);			// Burkes implementation
void	simple(int x, int y, int dr, int dg, int db) {diff(x+1,y,1,dr,dg,db);}	// simple diffusion at right ** no prototype **
float	eucl(int i, byt r, byt g, byt b);		// Euclidean distance between some index and supplied RGB value
float	hdist(int i, byt r, byt g, byt b);		// hue-based distance between some index and supplied RGB value
float	luma(byt r, byt g, byt b);				// return luminance for selected RGB values
float	hue(byt r, byt g, byt b);				// return hue (0...360) for selected RGB values
float	sat(byt r, byt g, byt b);				// return saturation (0...1) for selected RGB values
float	val(byt r, byt g, byt b);				// return value (0...255) for selected RGB values
byt		byte(int v);							// trim value to unsigned byte
byt		palR(int i);							// get red value from standard palette
byt		palG(int i);							// get green value from standard palette
byt		palB(int i);							// get blue value from standard palette
int		prox(byt r, byt g, byt b, char met);	// find index closest to suggested RGB, several methods

/****************/
/* main program */
/****************/
int main(void) {
	char nombre[80];			// string for filenames, plus substrings buffer
	char buf[80];				// read buffer
	char *pt, mode, dith;		// temporary pointer plus quantizing/dithering mode
	byt r, g, b, i;				// pixel values PLUS index
	int dr, dg, db;				// error diffusion, best with extended range AND SIGNED
	float k;					// diffusion factor
	int x, y, z;				// coordinates  plus read value
	long xy, siz;				// complete array offset plus size
	FILE *fi, *fo;				// file handlers

/* get input file */
	printf("PPM file? ");		// get input filename
	fgets(nombre, 80, stdin);	// no longer scanf!
	x=0;						// damned! I have to manually terminate the string
	while (nombre[x]!='\n' && nombre[x]!='\0')	{x++;}	// look for CR or NULL
	nombre[x]=0;				// filename is ready
	printf("Try to open %s...\n", nombre);
	fi=fopen(nombre, "r");		// open input file
	if (fi==NULL) {
		printf("NO FILE!\n");		// error handling
		return -1;
	}

/* swap extension on filename */
	pt=strstr(nombre, ".ppm");	// temporary pointer use
	if (pt==NULL) {				// extension not found?
		pt=strstr(nombre, ".PPM");	// perhaps in uppercase?
		if (pt==NULL) {
			printf("WRONG TYPE!\n");
			return -1;
		}
		printf("(caps) ");
	}
	*pt='\0';					// cut extension off
	strcat(nombre, ".six");		// create output filename
	printf("Output file: %s\n", nombre);

/* prepare output file*/
	fo=fopen(nombre, "wb");		// open output file
	if (fo==NULL) {
		printf("CANNOT OUTPUT!\n");	// error handling
		return -1;
	}

/* start reading PPM in order to determine size */
/*** common read-buffer-minus-comments code ***/
	do {
		fgets(buf, 80, fi);			// get line into temporary buffer...
	} while (buf[0]=='#');		// ...but reject comments!
/*** end of comment-striping code ***/
	if (strcmp(buf, "P3\n")!=0) {
		printf("WRONG FORMAT!\n");	// abort if not ASCII-type PPM
		return -1;
	}
	do {
		fgets(buf, 80, fi);			// get line into temporary buffer...
	} while (buf[0]=='#');		// ...but reject comments!
/* hardwired format, both sizes on one line, then another with max value, then each value on single line */
/* read sizes */
	sscanf(buf, "%d", &sx);		// get one number from file
	pt=buf;
	do {
		i=*pt;
		pt++;
	} while (i!='\0' && i!=' ' && i!='\n' && i!='\t');
	sscanf(pt, "%d", &sy);		// get one number from file
	do {
		fgets(buf, 80, fi);			// get line into temporary buffer...
	} while (buf[0]=='#');		// ...but reject comments!
	if (strcmp(buf, "255\n")!=0) {
		printf("WRONG DEPTH!\n");	// abort if not 256-level
		return -1;
	}
	printf("Image size is %d x %d pixels\n", sx, sy);
/* allocate buffer space */
	siz=sx*sy;					// precompute size
	R=(byt*)malloc(siz);		// allocate arrays
	G=(byt*)malloc(siz);
	B=(byt*)malloc(siz);
	if(R==NULL||G==NULL||B==NULL) {
		printf("OUT OF MEMORY!\n");	// abort if not enough memory
		return -1;
	}
	printf("Successfully allocated %ld bytes per channel\n", siz);
/* read image file into array */
	xy=0;						// convenient counter
	while (!feof(fi)) {
		if (!(xy&16383))	printf("Read %ld Kp...\n", xy>>10);	// progress indicator

		do {
			fgets(buf, 80, fi);			// get line into temporary buffer...
		} while (buf[0]=='#');		// ...but reject comments!
		sscanf(buf, "%d", &z);		// get one number from file
		R[xy] = z;					// put RED value into array

		do {
			fgets(buf, 80, fi);			// get line into temporary buffer...
		} while (buf[0]=='#');		// ...but reject comments!
		sscanf(buf, "%d", &z);		// get one number from file
		G[xy] = z;					// put GREEN value into array

		do {
			fgets(buf, 80, fi);			// get line into temporary buffer...
		} while (buf[0]=='#');		// ...but reject comments!
		sscanf(buf, "%d", &z);		// get one number from file
		B[xy] = z;					// put BLUE value into array

		xy++;						// go for next
	}
/* file is read, select quantizing method */
	printf("Quantizing method:\nEuclidean (C=256, L=32, D=16)\nHue (H=256, U=32, E=16)\n");
	printf("Luma based: G=Greyscale (16+2), S=Salt&pepper(2)\n");
	printf("Your choice? ");
	scanf(" %c", &mode);
	mode |= 32;						// always lowercase
	if (mode!='c' && mode!='l' && mode!='d' && mode!='h' && mode!='u' && mode!='e' && mode!='g' && mode!='s') {
		printf("*** Unrecognised quantizing method ***\n");
		return -1;						// abort in case of wrong parameter
	}
/* ditto for dithering method */
	printf("Dithering method:\n[F]loyd-Steinberg, [A]tkinson, full [S]ierra, [B]urkes, simple [D]iffusion? ");
	scanf(" %c", &dith);
	dith |= 32;						// always lowercase, will check values later
/*******************************************/
/* scan original array for error diffusion */
/*******************************************/
	for (y=0;y<sy;y++) {
		if (!(y&15))	printf("Processing row %d...\n", y);	// progress indicator
		for (x=0;x<sx;x++) {
			xy=coord(x,y);				// current pixel, no need to check bounds
//			if (xy>=0) {				// not really needed here...
			r=R[xy];					// component values
			g=G[xy];
			b=B[xy];
/* seek nearest colour */
			i=prox(r, g, b, mode);		// find best match according to mode (e, h, g, s)
			fputc(i, fo);				// get value into file!
/* compute error per channel */
			dr=r-palR(i);				// these are signed!
			dg=g-palG(i);
			db=b-palB(i);
/*****************/
/* diffuse error */
/*****************/
			switch(dith) {				// select dithering algorithm
				case 'f':
					floyd(x, y, dr, dg, db);	// trying Floyd-Steinberg formula
					break;
				case 'a':
					atkinson(x, y, dr, dg, db);	// trying Atkinson formula
					break;
				case 's':
					sierra(x, y, dr, dg, db);	// trying full Sierra formula
					break;
				case 'b':
					burkes(x, y, dr, dg, db);	// trying Burkes formula
					break;
				case 'd':
					simple(x, y, dr, dg, db);	// trying simple diffusion formula
					break;
				default:
					printf("*** Unrecognised dithering algorithm! ***\n");
					return -1;
			}
//			}							// ...in case of coordinates check
		}
	}

/* cleanup and exit */
	fclose(fi);
	fclose(fo);
/* THIS FOR DEBUGGING */
	if(R==NULL||G==NULL||B==NULL) {
		printf("UNALLOCATED MEMORY!\n");
		return -1;
	}
/* release memory */
	free(R);
	free(G);
	free(B);

	return 0;
}

/************************/
/* function definitions */
/************************/
long coord(int x, int y) {
/* compute offset from coordinates */
	if (0>x||x>=sx||0>y||y>=sy)	return -1;	// negative offset means OUT of bounds!
	return (long)sx*y+x;			// returns long in case int cannot handle one meg
}

void diff(int x, int y, float k, int dr, int dg, int db) {
/* generic diffusion function */
	long xy;

	xy=coord(x, y);
	if (xy<0)	return;			// check bounds

	R[xy]=byte(k*dr+R[xy]);		// diffuse the error
	G[xy]=byte(k*dg+G[xy]);
	B[xy]=byte(k*db+B[xy]);
}

void floyd(int x, int y, int dr, int dg, int db) {
/* Floyd-Steinberg implementation */
	diff(x+1,   y, 7.0/16, dr, dg, db);	// pixel at right
	diff(x+1, y+1, 1.0/16, dr, dg, db);	// pixel below right
	diff(  x, y+1, 5.0/16, dr, dg, db);	// pixel below
	diff(x-1, y+1, 3.0/16, dr, dg, db);	// pixel below left
}

void sierra(int x, int y, int dr, int dg, int db) {
/* full Sierra implementation */
	diff(x+1,   y, 5.0/32, dr, dg, db);	// pixel at right
	diff(x+2,   y, 3.0/32, dr, dg, db);	// two pixels at right
	diff(x-2, y+1, 2.0/32, dr, dg, db);	// two pixels left below
	diff(x-1, y+1, 4.0/32, dr, dg, db);	// pixel below left
	diff(  x, y+1, 5.0/32, dr, dg, db);	// pixel below
	diff(x+1, y+1, 4.0/32, dr, dg, db);	// pixel below right
	diff(x+2, y+1, 2.0/32, dr, dg, db);	// two pixels right, below
	diff(x-1, y+2, 2.0/32, dr, dg, db);	// two pixels below left
	diff(  x, y+2, 3.0/32, dr, dg, db);	// two pixels below
	diff(x+1, y+2, 2.0/32, dr, dg, db);	// two pixels below right
}

void atkinson(int x, int y, int dr, int dg, int db) {
/* Atkinson implementation */
/* some specific implementation will speed this up a lot */
	diff(x+1,   y, 1.0/8, dr, dg, db);	// pixel at right
	diff(x+2,   y, 1.0/8, dr, dg, db);	// two pixels at right
	diff(x-1, y+1, 1.0/8, dr, dg, db);	// pixel below left
	diff(  x, y+1, 1.0/8, dr, dg, db);	// pixel below
	diff(x+1, y+1, 1.0/8, dr, dg, db);	// pixel below right
	diff(  x, y+2, 1.0/8, dr, dg, db);	// two pixels below
}

void burkes(int x, int y, int dr, int dg, int db) {
/* Burkes implementation */
/* some specific implementation will speed this up */
	diff(x+1,   y, 8.0/32, dr, dg, db);	// pixel at right
	diff(x+2,   y, 4.0/32, dr, dg, db);	// two pixels at right
	diff(x-2, y+1, 2.0/32, dr, dg, db);	// two pixels left below
	diff(x-1, y+1, 4.0/32, dr, dg, db);	// pixel below left
	diff(  x, y+1, 8.0/32, dr, dg, db);	// pixel below
	diff(x+1, y+1, 4.0/32, dr, dg, db);	// pixel below right
	diff(x+2, y+1, 2.0/32, dr, dg, db);	// two pixels right, below
}

float luma(byt r, byt g, byt b){
/* return luminance for selected RGB values */
	return 0.3*r+0.59*g+0.11*b;
}

float eucl(int i, byt r, byt g, byt b) {
/* Euclidean distance between some index and supplied RGB value */
	int pr, pg, pb;

	pr = palR(i);				// get RGB values for selected index
	pg = palG(i);
	pb = palB(i);

	return ((pr-r)*(pr-r)+(pg-g)*(pg-g)+(pb-b)*(pb-b));		// compute Euclidean distance
//	return (uns(pr-r)+uns(pg-g)+uns(pb-b));		// compute Euclidean distance, but cuadratic looks a bit better
}

float hdist(int i, byt r, byt g, byt b) {
/* hue-based distance between some index and supplied RGB value */
	float hi, si, vi;			// values for indexed entry
	float hp, sp, vp;			// values for target colour
	byt ir, ig, ib;				// temporary palette values

	ir = palR(i);				// get RGB values for selected index
	ig = palG(i);
	ib = palB(i);
	hi = hue(ir, ig, ib);		// convert indexed colour to HSV
	si = sat(ir, ig, ib);
	vi = val(ir, ig, ib);
	hp = hue(r, g, b);			// convert pixel colour to HSV
	sp = sat(r, g, b);
	vp = val(r, g, b);

// TO DO TO DO TO DO
//	return ((360+(hi-hp)*(hi-hp))*(1+(si-sp)*(si-sp))*(256+(vi-vp)*(vi-vp)));
	return (((hi-hp)*(hi-hp))+(256*uns(si-sp))+(uns(vi-vp)));
}

float hue(byt r, byt g, byt b){
/* return hue for selected RGB values */
	float max=r, min=r;
	float h;

	if (g>max)	max=g;			// compute max and min values
	if (b>max)	max=b;
	if (g<min)	min=g;
	if (b<min)	min=b;

	if (max==min)	return 0;	// black is a special case

	if (max==r) {				// compute according to formulae
		h=(g-b)/(max-min);
	} else if (max==g) {
		h=(b-r)/(max-min)+2;
	} else {
		h=(r-g)/(max-min)+4;
	}
	h *= 60;					// scale to 360 degrees
	if (h<0)	h+=360;			// wrap!

	return h;
}

float sat(byt r, byt g, byt b){
/* return saturation for selected RGB values */
	float max=r, min=r, s;

	if (g>max)	max=g;			// compute maximum
	if (b>max)	max=b;

	if (max==0)	return 0;		// black is the darkest grey

	if (g<min)	min=g;			// compute minimum
	if (b<min)	min=b;
	s=(max-min)/max;			// saturation level

	return s;
}

float val(byt r, byt g, byt b){
/* return value for selected RGB values */
	float max=r;

	if (g>max)	max=g;			// compute maximum
	if (b>max)	max=b;

	return max;
}

byt byte(int v) {
/* trim value to unsigned byte */
	if (v<0)	return 0;		// check boundaries
	if (v>255)	return 255;
	return (byt)v;				// standard uncropped value
}

byt palR(int i) {
/* get red value from standard palette */
	if (i>31)	return levR[((i&224)>>5)-1];	// user-defined colours
	if (i>15)	return grey[i-16];				// system grayscale
	return (i&4)?255:0;							// system colours otherwise
}

byt palG(int i) {
/* get green value from standard palette */
	byt g;

	if (i>31)	return levG[(i&15)>>1];			// user-defined colours
	if (i>15) 	return grey[i-16];				// system grayscale
	// system colours otherwise... a bit more difficult here as uses two bits for green
	g=((i&8)>>2)|((i&2)>>1);					// green level 0...3
	return g|(g<<2)|(g<<4)|(g<<6);				// faster multiply by 85
}

byt palB(int i) {
/* get blue value from standard palette */
	if (i>31) 	return levB[((i&16)>>3)|(i&1)];	// user-defined colours
	if (i>15)	return grey[i-16];				// system grayscale
	return (i&1)?255:0;							// system colours otherwise
}

int prox(byt r, byt g, byt b, char met) {
/* find index closest to suggested RGB, according to method: */
/* Euclidean (c=256 colours, l=sys+gs, d=16 system colours) */
/* Hue-based (h=256, u=32, e=16) */
/* Luma-based (g=16+2 greyscale, s=salt & pepper)  */
	int i, pos, col=256;
	float y, diff=1e38;			// sentinel value, as we are looking for the minimum distance in absolute value

	if (met=='g'||met=='s') {	// non-colour modes use luma
		i=(int)luma(r, g, b);		// target luminance
	}
	switch(met) {
		case 'g':					// Greyscale quantizing (0, 15 and 16...31)
			if (i<8)	return 0;		// darkest goes black
			if (i>247)	return 15;		// lightest goes white
			i -= 8;						// darkest grey compensation
			i /= 15;					// into 16 greyscale values
			return i+16;				// EXIT with closest grey
		case 's':					// Salt & pepper quantizing (0 and 15)
			if (i<128)	return 0;		// lower than mid-grey EXIT as black
			return 15;					// otherwise EXIT as white
/* remaining cases only for colour loop, otherwise the function is over */
		case 'l':					// System colours & greyscale (0...31)
		case 'u':
			col=32;						// number of colours
			break;
		case 'd':					// System colours only (0...15)
		case 'e':
			col=16;
/* optional sentences as default value is OK */
			break;
		case 'c':					// whole palette
		case 'h':
			col=256;
	}
	for (i=0;i<col;i++) {		// scan all indexed colours
		if (met=='c'||met=='l'||met=='d') {		// Euclidean method selected
			y=eucl(i, r, g, b);
		}
		if (met=='h'||met=='u'||met=='e') {		// Hue-based method selected
			y=hdist(i, r, g, b);
		}
		if (y<diff) {				// update minimum if found
			diff=y;
			pos=i;						// keep track of found index
		}
	}

	return pos;					// this is the closest indexed colour
}
