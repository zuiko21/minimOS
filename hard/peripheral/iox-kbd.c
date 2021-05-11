/* IOx keyboard interface
 * for VIAport2 keyboard
 * includes two EPROMS, one for ASCII codes, one for control signals
 * (c) 2021 Carlos J. Santisteban
 * THIS CODE GENERATES THE EPROM CONTENTS
 */

#include <stdio.h>

void row(FILE* f, char x8, char x4, char x2, char x1) {
	int		i;
	
	for (i=0;i<7;i++)	fputc(f, 0);
	fputc(f, x8);
	for (i=0;i<3;i++)	fputc(f, 0);
	fputc(f, x4);
	fputc(f, 0);
	fputc(f, x2);
	fputc(f, x1);
	fputc(f, 0);
}

int main(void) {
	FILE*	rom;
	int		i, j;

/* Character ROM
 * A0..A3 = row
 * A4..A7 = column
 * A8 = ~CAPS LOCK
 * A9 = SHIFT
 * A10 = CONTROL
 * A11 = ALT
 */
	
/* ***********************
 * *** character EPROM ***
 * *********************** */

	rom=fopen("iox-char.bin", "wb");
	if (rom==NULL) {
		printf("*** Can't write to character ROM ***\n\n");
		return -1;
	}

/* unshifted but CAPS LOCK on */
	row(rom, 'º', 9, '<', ' ');
	
	fclose(rom);
	
	return 0;
}
	
