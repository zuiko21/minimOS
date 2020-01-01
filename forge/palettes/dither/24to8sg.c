/*	24-bit dithering for 8-bit SIXtation palette
 *	(c) 2019-2020 Carlos J. Santisteban
 *	last modified 20191128-0956 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char	byt;	// most helpful!

/* global arrays and variables */
byt levR[7]=	{18, 55, 91, 128, 164, 200, 237};
byt levG[8]=	{16, 48, 80, 112, 143, 175, 207, 239};
byt levB[4]=	{32, 96, 159, 223};
byt grey[16]=	{15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240};
byt *R, *G, *B;					// pointers to dynamically allocated buffers
int sx, sy;						// coordinate limits
char buf[80];					// read buffer
FILE *fi, *fo;					// file handlers

/***********************/
/* auxiliary functions */
/***********************/
void	readf(void) {do fgets(buf, 80, fi); while (buf[0]=='#');}	// read into buffer but reject comments! ** no prototype **

float	uns(float x) {return (x<0?-x:x);}		// absolute value **no prototype**

long	coord(int x, int y);					// compute offset from coordinates

void	diff(int x, int y, float k, int dr, int dg, int db);	// generic diffusion function

void	floyd   (int x, int y, int dr, int dg, int db);		// Floyd-Steinberg implementation
void	stucki  (int x, int y, int dr, int dg, int db);		// Stucki implementation
void	sierra  (int x, int y, int dr, int dg, int db);		// full Sierra implementation
void	s2row   (int x, int y, int dr, int dg, int db);		// 2-row Sierra implementation
void	atkinson(int x, int y, int dr, int dg, int db);		// Atkinson implementation
void	burkes  (int x, int y, int dr, int dg, int db);		// Burkes implementation
void	simple  (int x, int y, int dr, int dg, int db) {diff(x+1,y,1,dr,dg,db);}	// simple diffusion at right ** no prototype **

float	eucl (int i, byt r, byt g, byt b);		// Euclidean distance between some index and supplied RGB value
float	hdist(int i, byt r, byt g, byt b);		// hue-based distance between some index and supplied RGB value

float	luma(byt r, byt g, byt b);				// return luminance for selected RGB values
float	hue (byt r, byt g, byt b);				// return hue (0...360) for selected RGB values
float	sat (byt r, byt g, byt b);				// return saturation (0...1) for selected RGB values
float	val (byt r, byt g, byt b);				// return value (0...255) for selected RGB values

byt		byte(int v);							// trim value to unsigned byte

byt		palR(int i);							// get red value from standard palette
byt		palG(int i);							// get green value from standard palette
byt		palB(int i);							// get blue value from standard palette

int		prox (byt r, byt g, byt b, char met);	// find index closest to suggested RGB, several palettes
int		pdith(byt r, byt g, byt b, char met);	// P-dither suggested index, several palettes

/****************/
/* main program */
/****************/
int main(void) {
	char nombre[80];			// string for filenames, plus substrings buffer
	char *pt, mode, dith;		// temporary pointer plus quantizing/dithering mode
	byt r, g, b, i;				// pixel values PLUS index
	int dr, dg, db;				// error diffusion, best with extended range AND SIGNED
	float k;					// diffusion factor
	int x, y, z;				// coordinates  plus read value
	long xy, siz;				// complete array offset plus size
/*
r=0;g=85;b=0;i=4;
printf("(%d,%d,%d): H=%f, S=%f, V=%f\n",r,g,b,hue(r,g,b),sat(r,g,b),val(r,g,b)); 
printf("S%d > %f\n",i,hdist(i,r,g,b));
printf("G[%d,%d,%d]\n",palR(i),palG(i),palB(i));
return -2;
/**/
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
	readf();					// common read-buffer-minus-comments
	if (strcmp(buf, "P3\n")!=0) {
		printf("WRONG FORMAT!\n");	// abort if not ASCII-type PPM
		return -1;
	}
	readf();					// common read-buffer-minus-comments
/* hardwired format, both sizes on one line, then another with max value, then each value on single line */
/* read sizes */
	sscanf(buf, "%d", &sx);		// get one number from file
	pt=buf;
	do {
		i=*pt;
		pt++;
	} while (i!='\0' && i!=' ' && i!='\n' && i!='\t');
	sscanf(pt, "%d", &sy);		// get one number from file
	readf();					// common read-buffer-minus-comments
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

		readf();					// common read-buffer-minus-comments
		sscanf(buf, "%d", &z);		// get one number from file
		R[xy] = z;					// put RED value into array

		readf();					// common read-buffer-minus-comments
		sscanf(buf, "%d", &z);		// get one number from file
		G[xy] = z;					// put GREEN value into array

		readf();					// common read-buffer-minus-comments
		sscanf(buf, "%d", &z);		// get one number from file
		B[xy] = z;					// put BLUE value into array

		xy++;						// go for next
	}

/* file is read, select quantizing method */
	printf("Quantizing method:\nEuclidean (C=256, L=32, D=16)\nHue (H=256, U=32, E=16)\n");
	printf("Luma based: G=Greyscale (16+2), S=Salt&pepper (2)\n");
	printf("Your choice? ");
	scanf(" %c", &mode);
	mode |= 32;						// always lowercase
	if (mode!='c' && mode!='l' && mode!='d' && mode!='h' && mode!='u' && mode!='e' && mode!='g' && mode!='s') {
		printf("*** Unrecognised quantizing method ***\n");
		return -1;						// abort in case of wrong parameter
	}
/* ditto for dithering method */
	printf("Dithering method:\n[F]loyd-Steinberg, [A]tkinson, [B]urkes, simple [D]iffusion,\n");
	printf("Full [S]ierra, [T]wo-row Sierra, Stuc[K]i, [P]-dither, [N]one? ");
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
			if (dith!='p') {			// except for P-dithering...
				i=prox(r, g, b, mode);		// ...find best match according to mode (will diffuse error later)
			} else {					// P-dither directly implemented here!
				i=pdith(r, g, b, mode);		// add random noise depending on palette
			}
			fputc(i, fo);				// ** put index value into output file! **
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
				case 'k':
					stucki(x, y, dr, dg, db);	// trying Stucki formula
					break;
				case 's':
					sierra(x, y, dr, dg, db);	// trying full Sierra formula
					break;
				case 't':
					s2row(x, y, dr, dg, db);	// trying 2-row Sierra formula
					break;
				case 'b':
					burkes(x, y, dr, dg, db);	// trying Burkes formula
					break;
				case 'd':
					simple(x, y, dr, dg, db);	// trying simple diffusion formula
				case 'p':					// P-dithering makes no error diffusion!
				case 'n':					// just like no dither at all
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

void stucki(int x, int y, int dr, int dg, int db) {
/* Stucki implementation */
	diff(x+1,   y, 8.0/42, dr, dg, db);	// pixel at right
	diff(x+2,   y, 4.0/42, dr, dg, db);	// two pixels at right
	diff(x-2, y+1, 2.0/42, dr, dg, db);	// two pixels left below
	diff(x-1, y+1, 4.0/42, dr, dg, db);	// pixel below left
	diff(  x, y+1, 8.0/42, dr, dg, db);	// pixel below
	diff(x+1, y+1, 4.0/42, dr, dg, db);	// pixel below right
	diff(x+2, y+1, 2.0/42, dr, dg, db);	// two pixels right, below
	diff(x-2, y+2, 1.0/42, dr, dg, db);	// two pixels below and left
	diff(x-1, y+2, 2.0/42, dr, dg, db);	// two pixels below left
	diff(  x, y+2, 4.0/42, dr, dg, db);	// two pixels below
	diff(x+1, y+2, 2.0/42, dr, dg, db);	// two pixels below right
	diff(x+2, y+2, 1.0/42, dr, dg, db);	// two pixels below and right
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

void s2row(int x, int y, int dr, int dg, int db) {
/* 2-row Sierra implementation */
	diff(x+1,   y, 4.0/16, dr, dg, db);	// pixel at right
	diff(x+2,   y, 3.0/16, dr, dg, db);	// two pixels at right
	diff(x-2, y+1, 1.0/16, dr, dg, db);	// two pixels left below
	diff(x-1, y+1, 2.0/16, dr, dg, db);	// pixel below left
	diff(  x, y+1, 3.0/16, dr, dg, db);	// pixel below
	diff(x+1, y+1, 2.0/16, dr, dg, db);	// pixel below right
	diff(x+2, y+1, 1.0/16, dr, dg, db);	// two pixels right, below
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
	float dh, fh;				// absolute hue distances
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
// check possible hue wrap!
	dh = uns(hi-hp);			// standard distance...
	fh = 360 - dh;				// ...in case hue wrapped
	if (fh<dh)		dh = fh;	// choose the lowest one

// TO DO TO DO TO DO
//	return ((360+(hi-hp)*(hi-hp))*(1+(si-sp)*(si-sp))*(256+(vi-vp)*(vi-vp)));
//	return (((hi-hp)*(hi-hp))+(256*uns(si-sp))+(uns(vi-vp)));
	return	(dh*dh)*uns(si-sp)+uns(vi-vp);
}

float hue(byt r, byt g, byt b){
/* return hue (0...360) for selected RGB values */
	float max=r, min=r;
	float h;

	if (g>max)	max=g;			// compute max and min values
	if (b>max)	max=b;
	if (g<min)	min=g;
	if (b<min)	min=b;

	if (max==min)	return 0;	// grey is a special case (same hue as RED)

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
/* return saturation (0...1) for selected RGB values */
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
/* return value (0...255) for selected RGB values */
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
		case 'h':
		case 'c':					// these modes use the whole palette
			col=256;
	}
	for (i=0;i<col;i++) {		// scan suitable number of indexed colours
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

int pdith(byt r, byt g, byt b, char met) {
/* P-dither suggested RGB, several palettes */
/* Euclidean and Hue-based work the same here: C=H=_224_, L=U=32, D=E=16 colours */
	float y;					// target luma
	int x;						// random value
	int dr, dg, db;				// component values
	int i;						// temporary index, if appliable

	switch(met) {				// add dithering noise according to selected palette
// ** 16+2 greys **
		case 'g':
			y=luma(r, g, b);			// compute target luminance
			x=1+rand()%15;				// generate noise
			i=(int)y/grey[0]-1;			// closest grey, index -1...16 (palette greyscale is 0...15, plus black & white)
			if (i<0) {					// is it really dark? may turn black
				if (y<x)			return 0;		// emit full black...
				else				return 16;		// ...or the darkest grey
			} else if (i>=15) {			// or is it really light?
				if (y-grey[15]<x)	return 31;		// emit the lightest grey...
				else				return 15;		// ...or full white
			} else {					// regular greyscale otherwise
				if (y-grey[i]<x)	return 16+i;	// emit computed index...
				else				return 17+i;	// ...or the following one
			}
// ** salt-and-pepper **
		case 's':
			y=luma(r, g, b);			// compute target luminance
			x=1+rand()%255;				// generate random noise
			if (y<x)	return 0;		// emit black or white depending on chance
			else		return 15;
// ** 224-colour modes (not using greyscale!) **
		case 'c':
		case 'h':
// Red channel from 224
			i=(r+levR[0])/levR[0]/2;	// floored red index (0 is the darkest value)
			if (i<1) {					// is it really dark?
				dr = 1;						// emit the darkest red
			} else if (i>5) {			// or is it really light?
				dr = 7;						// emit a very light red
			} else {					// regularly spaced otherwise
				x=1+rand()%(levR[i]-levR[i-1]-1);	// generate noise according to quantizing intervals
				if (r-levR[i-1]<x)			dr=i;	// emit computed index...
				else						dr=i+1;	// ...or the following one
			}
// Green channel from 224
			i=(g+levG[0])/levG[0]/2;	// floored green index (0 is the darkest value)
			if (i<1) {					// is it really dark?
				dg = 0;						// emit the darkest green
			} else if (i>6) {			// or is it really light?
				dg = 7;						// emit a very light green
			} else {					// regularly spaced otherwise
				x=1+rand()%(levG[i]-levG[i-1]-1);	// generate noise according to quantizing intervals
				if (r-levG[i-1]<x)			dg=i-1;	// emit computed index...
				else						dg=i;	// ...or the following one
			}
// Blue channel from 224
			i=(b+levB[0])/levB[0]/2;	// floored blue index (0 is the darkest value)
			if (i<1) {					// is it really dark?
				db = 0;						// emit the darkest blue
			} else if (i>2) {			// or is it really light?
				db = 3;						// emit a very light blue
			} else {					// regularly spaced otherwise
				x=1+rand()%(levB[i]-levB[i-1]-1);	// generate noise according to quantizing intervals
				if (r-levB[i-1]<x)			db=i-1;	// emit computed index...
				else						db=i;	// ...or the following one
			}
			return (dr<<5)|(dg<<1)|(db&1)|((db&2)<<3);	// base index RRRBGGGB, where R=1...7
// ** 16 system colours **
		case 'd':
		case 'e':
// system + greyscale will try to compute one candidate from system palette, just like if using 16 system colours only
// alternative grey tried only when allowed
		case 'l':
		case 'u':
// generic system colour picker
// Red channel
			x  = 1+rand()%255;			// generate red noise...
			dr = r<x ? 0 : 4;			// ...and emit discrete value
// Green channel (black plus 3 levels!)
			x  = 1+rand()%84;			// generate green noise (shallower range)
			i  = g/85;					// floored green index (0...3)
			dg = (g-85*i)<x ? i : i+1;	// emit discrete value
// Blue channel
			x  = 1+rand()%255;			// generate blue noise...
			db = b<x ? 0 : 1;			// ...and emit discrete value
			if (met=='d'||met=='e')		// if no greys are allowed...
				return dr|((dg&1)<<1)|((dg&2)<<2)|db;	// ...compute index and exit
// ** 16 system colours + 16 greys! Does this make any sense? **
// dr, dg, db already have a candidate system colour
// let us find a suitable grey, just in case
			if (sat(r, g, b)<0.1) {		// is it a weakly-saturated colour?
// should alternate between grey & sys with chance according to saturation!
				y = luma(r, g, b);			// compute target luminance
				x=1+rand()%15;				// generate noise
				i=(int)y/grey[0]-1;			// closest grey, index -1...16 (palette greyscale is 0...15, plus black & white)
				if (i<0) {					// is it really dark? may turn black
					if (y<x)			i = 0;	// emit full black...
					else				i = 16;	// ...or the darkest grey
				} else if (i>=15) {			// or is it really light?
					if (y-grey[15]<x)	i = 31;	// emit the lightest grey...
					else				i = 15;	// ...or full white
				} else {					// regular greyscale otherwise
					if (y-grey[i]<x)	i=16+i;	// emit computed index...
					else				i=17+i;	// ...or the following one
				}
				return i;					// ** PLACEHOLDERS **
			} else return dr|((dg&1)<<1)|((dg&2)<<2)|db;
	}
}
