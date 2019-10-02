/*	24-bit dithering for 8-bit SIXtation palette
 *	(c) 2019 Carlos J. Santisteban
 *	last modified 20191002-1012 */

int main(void) {
	char nombre[80];				/* string for filenames, plus read buffer */
	char *pt;						/* pointer to dynamically allocated output buffer */
	FILE *fi, *fo;					/* file handlers */
	
	prinf(".PPM file? ");			/* get input filename */
	fgets(nombre, 80, stdin);		/* no longer scanf! */
	fi=fopen(nombre, "r");			/* open input file */
	if (fi==NULL) {
		printf("NO FILE!\n");		/* error handling */
		return -1;
	}
	strcat(nombre, ".SIX");			/* create output filename */
	fo=fopen(nombre, "wb");			/* open output file */
	if (fo==NULL) {
		printf("CANNOT OUTPUT!\n");	/* error handling */
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
	
/* neighbouring colours: (RRRBGGGB)
R & %11100000 if >=%100000
| G>>4 & %1110
| B&%10000000 >>3
| B&%01000000 >>7
*/
	return 0;
}
