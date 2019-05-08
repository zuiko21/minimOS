/*
 * converts BitFontMaker exported fonts *
 * into xa65 assembly files             *
 *
 * (c) 2019 Carlos J. Santisteban       *
 * last modified 20190508-1606          *
 */

#include <stdio.h>
#include <string.h>

/* global variables */
	FILE	*f, *s;
	unsigned char g[256][16];	/* whole glyph definitions */
	int		SCAN =16;			/* *** number of scanlines (assume 8-pixel wide) *** */

/* functions */
int	readval(FILE *f) {
	int x=0;
	unsigned char c;

	while (-1) {
		c=fgetc(f);
		if (c>'9' || c<'0')		break;
		x*=10;			/* previous cipher is ten times more */
		x+=(c-'0');		/* add this cipher */
	}
	if (c=='"' || c==',' || c==']') {	/* possible delimiters */
		return x;
	} else return -1;					/* ERROR sentinel */
}

unsigned char minimOS(int x) {
	switch(x) {
		case 290 ... 321:	return (unsigned char)x-290;	/* C0 control */
		case 164:	return 32;	/* space, with invisible dot */
		case 256 ... 271:	return (unsigned char)x-128;	/* ZX block graphs */
		case 274 ... 289:	return (unsigned char)x-130;	/* greek & math */
		case 189:	return 160;	/* hollow square */
		case 190:	return 173;	/* not equal */
		case 8364:	return 164;	/* euro */
		case 339:	return 189;	/* oe ligature */
		case 331:	return 190;	/* eng */
		case 272:	return 208;	/* uppercase eth */
		case 273:	return 240;	/* lowercase eth */

		default:	return (unsigned char)x;
	}
}

/* *** main code *** */
int main(void) {
	char	name[80];
	char	c;
	int		i, j, k, x;

/* init matrix */
	for (i=0; i<256; i++) {
		for (j=0; j<SCAN; j++) {
			g[i][j]=0;
		}
	}
/* select input file */
	printf("File? ");
	fgets(name, 80, stdin);
/* why should I put the terminator on the read string? */
	i=0;
	while (name[i]!='\n' && name[i]!='\0')	{i++;}
	name[i]=0;			/* filename is ready */
	printf("Opening %s file...\n", name);
	f=fopen(name, "r");
	if (f==NULL) {		/* error handling */
		printf("Could not open file!\n");
	} else {
/* open output file */
		strcat(name,".s");
		s=fopen(name,"w");
		if (s==NULL) {	/* error handling */
			printf("Cannot output source!\n");
		} else {
/* proceed! first read file into matrix */
			c=fgetc(f);			/* first character must be { */
			if (c!='{') {
				printf("*** WRONG FILE FORMAT ***\n");
				fclose(s);		/* disable regular output */
				s=fopen("/dev/null","w");
			}
/* read loop, scan for  "  then a number -> index for matrix
 * then  ":[  and the 16 comma-separated numbers
 * lastly  ],  and start again
 * any letter after  "  ends procedure */
			while (fgetc(f)=='"') {			/* emergency exit */
				i=readval(f);				/* try to read index */
				if (i<0)			break;	/* *** non-numeric character found *** */
				i=minimOS(i);				/* convert non-compatible codes! */
/* get array for this index */
				if (fgetc(f)!=':')	break;
				if (fgetc(f)!='[')	break;
				for (j=0; j<SCAN; j++) {	/* get every scanline */
					x=readval(f);
					if (x<0) 		break;	/* unexpected error... */
					g[i][j]=x>>2;			/* note shift */
				}
				if (fgetc(f)!=',')	break;	/* ] was taken by last readval() */
			}
			fclose(f);
			printf("All read!\n");
		}
/* then create assembly file from matrix contents */
		printf("Writing into %s...\n", name);
/* header contents */
		fprintf(s, "; Automatic font definition for minimOS\n");
		fprintf(s, "; (c) 2019 Carlos J. Santisteban\n");
/* loops for contents creation */
		for (i=0; i<256; i++) {
			fprintf(s, "\n; ASCII $%X", i);			/* ASCII code */
			if (i>31) {fprintf(s, " - %c", i);}		/* only printable chars */
			fprintf(s, "\n");
			for (j=0; j<SCAN; j++) {				/* scanline loop */
				fprintf(s,"\t.byt\t%%");
				for (k=0; k<8; k++) {				/* convert to binary, note reversed order! */
					fprintf(s, "%d", g[i][j]>>k & 1);
				}
				fprintf(s,"\n");
			}
		}
/* clean up */
		fclose(s);
		printf("Success!\n");
	}

	return 0;
}
