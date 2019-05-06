/*
 * convert web-edited bitmap fonts *
 * into xa65 assembly files        *
 *
 * (c) 2019 Carlos J. Santisteban  *
 * last modified 20190506-2227     *
 */

#include <stdio.h>
#include <string.h>

/* global variables */
	FILE	*f, *s;

/* functions */
int leedef(void) {
	char r;

	r=fgetc(f);

}

/* *** main code *** */
int main(void) {
	char	nombre[80];
	int	c, d;
	char	r;

/* select input file */
	printf("File? ");
	gets();
	f=fopen(nombre,"r");
	if(f==NULL) {
		printf("Could not open file!\n");
	} else {
/* open output file */
		s=fopen(strcat(nombre,".s"),"w");
		if(s==NULL) {
			printf("Cannot output source!\n");
		} else {
/* proceed! */
			fprinf(s,"; Automatic font definition for minimOS\n");
			fprinf(s,"; (c) 2019 Carlos J. Santisteban\n\n");
			c=0; /* init loop*/
			while(c<256 && r!='}') {
				fprintf(s,"\n; ASCII $%X,c"); /* ASCII code */
				if(c>31) {fprintf(s," - %c",c);} /* only printable chars */
				fprintf(s,"\n\n\t");
				if(c!=d) { /* not this one, fill with blanks */
					fprinf(s,".byt\t\%00000000\t; undefined\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
					fprinf(s,"\t.byt\t\%00000000\n");
				} else { /* insert binary definition and read next entry */
				}
				c++; /* look for next ASCII */
			}
/* clean up */
			fclose(s);
			printf("Success!\n");
		}
		fclose(f);
	}

	return 0;
}
