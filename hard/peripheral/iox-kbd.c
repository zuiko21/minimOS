/* IOx keyboard interface
 * for VIAport2 keyboard
 * includes two EPROMS, one for ASCII codes, one for control signals
 * (c) 2021 Carlos J. Santisteban
 * THIS CODE GENERATES THE EPROM CONTENTS
 */

#include <stdio.h>

int main(void) {
	FILE*	rom;
	int		i, j;
	unsigned char	mat[16][16][16];	/* modifiers, col, row */
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
/* unshifted but CAPS LOCK on */
	
	mat[0][0]={  0,  0,  0,  0,  0,  0,  0,'º',  0,  0,  9,  0,'<',' '};
	
	rom=fopen("iox-char.bin", "wb");
	if (rom==NULL) {
		printf("*** Can't write to character ROM ***\n\n");
		return -1;
	}
	
	fclose(rom);
	
	return 0;
}
	
