/* IOx keyboard interface
 * for VIAport2 keyboard
 * includes two EPROMS, one for ASCII codes, one for control signals
 * (c) 2021 Carlos J. Santisteban
 * THIS CODE GENERATES THE EPROM CONTENTS
 */

#include <stdio.h>

void row(FILE* f, char x8, char x4, char x2, char x1) {
	int		i;
	
	for (i=0;i<7;i++)	fputc(0, f);
	fputc(x8, f);
	for (i=0;i<3;i++)	fputc(0, f);
	fputc(x4, f);
	fputc(0,  f);
	fputc(x2, f);
	fputc(x1, f);
	fputc(0,  f);
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
	row(rom,0xBA,0x09, '<', ' ');	/* 0x */
	rom(rom, '1', 'Q', 'A', 'Z');	/* 1x */
	row(rom, '2', 'w', 'S', 'X');	/* 2x */
	row(rom, '3', 'E', 'D', 'C');	/* 3x */
	row(rom, '4', 'R', 'F', 'V');	/* 4x */
	row(rom, '5', 'T', 'G', 'B');	/* 5x */
	row(rom, '6', 'Y', 'H', 'N');	/* 6x */
	row(rom, '7', 'U', 'J', 'M');	/* 7x */
	row(rom, '8', 'I', 'K', ',');	/* 8x */
	row(rom, '9', 'O', 'L', '.');	/* 9x */
	row(rom, '0', 'P', 'Ñ', '-');	/* Ax */
	row(rom,0x27,0x60,0xB4,0x02);	/* apostrophe, backtick, acute accent, cursor left */
	row(rom, '¡', '+', 'Ç',0x06);	/* ...cursor right */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* BS, CR, up, down */
	row(rom,0x1B,0x7F,0x19,0x16);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */

/* unshifted without CAPS LOCK */
	row(rom,0xBA,0x09, '<', ' ');	/* 0x */
	rom(rom, '1', 'q', 'a', 'z');	/* 1x */
	row(rom, '2', 'w', 's', 'x');	/* 2x */
	row(rom, '3', 'e', 'd', 'c');	/* 3x */
	row(rom, '4', 'r', 'f', 'v');	/* 4x */
	row(rom, '5', 't', 'g', 'b');	/* 5x */
	row(rom, '6', 'y', 'h', 'n');	/* 6x */
	row(rom, '7', 'u', 'j', 'm');	/* 7x */
	row(rom, '8', 'i', 'k', ',');	/* 8x */
	row(rom, '9', 'o', 'l', '.');	/* 9x */
	row(rom, '0', 'p', 'ñ', '-');	/* Ax */
	row(rom,0x27,0x60,0xB4,0x02);	/* apostrophe, backtick, acute accent, cursor left */
	row(rom, '¡', '+', 'ç',0x06);	/* ...cursor right */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* BS, CR, up, down */
	row(rom,0x1B,0x7F,0x19,0x16);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */

/* shifted, with or without CAPS LOCK */
	row(rom,0xAA,0x0B, '>', ' ');	/* 0x, shift-Tab like VT (or cursor up) */
	rom(rom, '!', 'Q', 'A', 'Z');	/* 1x */
	row(rom,0x22, 'w', 'S', 'X');	/* 2x */
	row(rom, '·', 'E', 'D', 'C');	/* 3x */
	row(rom, '$', 'R', 'F', 'V');	/* 4x */
	row(rom, '%', 'T', 'G', 'B');	/* 5x */
	row(rom, '&', 'Y', 'H', 'N');	/* 6x */
	row(rom, '/', 'U', 'J', 'M');	/* 7x */
	row(rom, '(', 'I', 'K', ',');	/* 8x */
	row(rom, ')', 'O', 'L', '.');	/* 9x */
	row(rom, '=', 'P', 'Ñ', '-');	/* Ax */
	row(rom, '?', '^', '_',0x02);	/* Bx */
	row(rom, '¿',0xA8, 'Ç',0x06);	/* Cx */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* BS, CR, up, down... perhaps will change*/
	row(rom,0x1B,0x7F,0x19,0x16);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */
/* same without CapsLock */
	row(rom,0xAA,0x0B, '>', ' ');	/* 0x, shift-Tab like VT (or cursor up) */
	rom(rom, '!', 'Q', 'A', 'Z');	/* 1x */
	row(rom,0x22, 'w', 'S', 'X');	/* 2x */
	row(rom, '·', 'E', 'D', 'C');	/* 3x */
	row(rom, '$', 'R', 'F', 'V');	/* 4x */
	row(rom, '%', 'T', 'G', 'B');	/* 5x */
	row(rom, '&', 'Y', 'H', 'N');	/* 6x */
	row(rom, '/', 'U', 'J', 'M');	/* 7x */
	row(rom, '(', 'I', 'K', ',');	/* 8x */
	row(rom, ')', 'O', 'L', '.');	/* 9x */
	row(rom, '=', 'P', 'Ñ', '-');	/* Ax */
	row(rom, '?', '^', '_',0x02);	/* Bx */
	row(rom, '¿',0xA8, 'Ç',0x06);	/* Cx */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* BS, CR, up, down... perhaps will change*/
	row(rom,0x1B,0x7F,0x19,0x16);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */

	fclose(rom);
	
	return 0;
}
	
