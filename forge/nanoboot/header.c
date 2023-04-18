/* generic file header            */
/* (c) 2023 Carlos J. Santisteban */

#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[]) {
	char name[80];
	FILE *f, *s;
	int c, i, siz;

	if (argc < 2) {
		printf("Usage: %s filename\n", argv[0]);
		return -1;
	}

	f = fopen(argv[1], "r");
	fseek(f, 0, SEEK_END);
	siz = 256 + ftell(f);	/* input file size plus header */
	fseek(f, 0, SEEK_SET);
	strcpy(name, argv[1]);
	strcat(name, ".da");	/* output file name */
	s = fopen(name, "w");
	printf("Output: %s (total %d bytes)\n", name, siz);

/* generate header */
	fputc(0, s);
	fputs("dA****\r", s);
	fputs(argv[1], s);		/* original name */
	fputc(0, s);
	fputc(0, s);
	c = 248-ftell(s);
	for (i=0; i<c; i++)		fputc(0xFF, s);	/* filling, no commits or version */
	for (i=0; i<4; i++)		fputc(0, s);	/* jan 1 1980 */
	fputc(siz & 255, s);
	fputc((siz>>8) & 255, s);
	fputc(0, s);
	fputc(0, s);

/* copy file contents */
	while (!feof(f)) {
		c = fgetc(f);
		if (c==10)	c=13;	/* newline UNIX -> minimOS conversion */
		fputc(c, s);
	}
/* padding to complete current sector */
	c = (-siz & 511);
//	if (c==512)		c = 0;
	printf("filling %d bytes...\n",c);
	for (i=1; i<c; i++)		fputc(0xFF, s);
/* clean up */
	fclose(f);
	fclose(s);

	return 0;
}
