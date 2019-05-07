/*
 * convert web-edited bitmap fonts *
 * into xa65 assembly files        *
 *
 * (c) 2019 Carlos J. Santisteban  *
 * last modified 20190507-1004     *
 */

#include <stdio.h>
#include <string.h>

/* global variables */
	FILE	*f, *s;
	unsigned char g[256][16];	/* whole glyph definitions */
	int		SCAN =16;			/* *** number of scanlines (assume 8-pixel wide) *** */

/* functions */
int	leenum(FILE *f) {
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

/* *** main code *** */
int main(void) {
	char	nombre[80];
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
	fgets(nombre, 80, stdin);
/* why should I put the terminator on the read string? */
	i=0;
	while (nombre[i]!='\n'&&nombre[i]!='\0')	i++;
	nombre[i]=0;
/* filename is OK */
	printf("Opening %s file...\n", nombre);
	f=fopen(nombre, "r");
	if (f==NULL) {
		printf("Could not open file!\n");
	} else {
/* open output file */
		strcat(nombre,".s");
		s=fopen(nombre,"w");
		if (s==NULL) {
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
				i=leenum(f);				/* try to read index */
				if (i==-1)			break;	/* *** non-numeric character found *** */
/* get array for this index */
				if (fgetc(f)!=':')	break;
				if (fgetc(f)!='[')	break;
				for (j=0; j<SCAN; j++) {	/* get every scanline */
					x=leenum(f);
					if (x<0) 		break;	/* unexpected error... */
					g[i][j]=x>>2;			/* note shift */
				}
				if (fgetc(f)!=',')	break;	/* ] was taken by last leenum() */
			}
			fclose(f);
			printf("All read!\n");
		}
/* then create assembly file from matrix contents */
		printf("Writing into %s...\n", nombre);
/* header contents */
		fprintf(s, "; Automatic font definition for minimOS\n");
		fprintf(s, "; (c) 2019 Carlos J. Santisteban\n");
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
