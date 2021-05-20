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
	row(rom, '2', 'W', 'S', 'X');	/* 2x */
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
	row(rom,0x22, 'W', 'S', 'X');	/* 2x */
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

	row(rom,0xAA,0x0B, '>', ' ');	/* 0x, shift-Tab like VT (or cursor up) */
	rom(rom, '!', 'Q', 'A', 'Z');	/* 1x */
	row(rom,0x22, 'W', 'S', 'X');	/* 2x */
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

/* CONTROL with or without CAPS LOCK */
/* basic keys follow PASK standard, currently undetermined values are 0 */
	row(rom,   0,   0,   0,0x80);	/* 0x, NBSP */
	rom(rom, '+',0x11,0x01,0x1A);	/* 1x */
	row(rom,0x27,0x17,0x13,0x18);	/* 2x */
	row(rom, '.',0x05,0x04,0x03);	/* 3x */
	row(rom, ',',0x12,0x06,0x16);	/* 4x */
	row(rom, ':',0x14,0x07,0x02);	/* 5x */
	row(rom, ';',0x19,0x08,0x0E);	/* 6x */
	row(rom, '-',0x15,0x0A,0x0D);	/* 7x */
	row(rom, '<',0x09,0x0B,   0);	/* 8x */
	row(rom, '>',0x0F,0x0C,   0);	/* 9x */
	row(rom, '_',0x10,   0,   0);	/* Ax */
	row(rom,   0,   0,   0,   0);	/* Bx */
	row(rom,   0,   0,   0,   0);	/* Cx */
	row(rom,   0,   0,   0,   0);	/* BS, CR, up, down... perhaps will change*/
	row(rom,   0,   0,   0,   0);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */

	row(rom,   0,   0,   0,0x80);	/* 0x, NBSP */
	rom(rom, '+',0x11,0x01,0x1A);	/* 1x */
	row(rom,0x27,0x17,0x13,0x18);	/* 2x */
	row(rom, '.',0x05,0x04,0x03);	/* 3x */
	row(rom, ',',0x12,0x06,0x16);	/* 4x */
	row(rom, ':',0x14,0x07,0x02);	/* 5x */
	row(rom, ';',0x19,0x08,0x0E);	/* 6x */
	row(rom, '-',0x15,0x0A,0x0D);	/* 7x */
	row(rom, '<',0x09,0x0B,   0);	/* 8x */
	row(rom, '>',0x0F,0x0C,   0);	/* 9x */
	row(rom, '_',0x10,   0,   0);	/* Ax */
	row(rom,   0,   0,   0,   0);	/* Bx */
	row(rom,   0,   0,   0,   0);	/* Cx */
	row(rom,   0,   0,   0,   0);	/* BS, CR, up, down... perhaps will change*/
	row(rom,   0,   0,   0,   0);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */

/* CONTROL-SHIFT with or without CAPS LOCK */
	row(rom,   0,   0,   0,   0);	/* 0x, **************** TO BE DONE *************** */
	rom(rom, '+',0x11,0x01,0x1A);	/* 1x */
	row(rom,0x27,0x17,0x13,0x18);	/* 2x */
	row(rom, '.',0x05,0x04,0x03);	/* 3x */
	row(rom, ',',0x12,0x06,0x16);	/* 4x */
	row(rom, ':',0x14,0x07,0x02);	/* 5x */
	row(rom, ';',0x19,0x08,0x0E);	/* 6x */
	row(rom, '-',0x15,0x0A,0x0D);	/* 7x */
	row(rom, '<',0x09,0x0B,   0);	/* 8x */
	row(rom, '>',0x0F,0x0C,   0);	/* 9x */
	row(rom, '_',0x10,   0,   0);	/* Ax */
	row(rom,   0,   0,   0,   0);	/* Bx */
	row(rom,   0,   0,   0,   0);	/* Cx */
	row(rom,   0,   0,   0,   0);	/* BS, CR, up, down... perhaps will change*/
	row(rom,   0,   0,   0,   0);	/* ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* MODIFIERS -> CapsLock, Shift, Control, Alt */


/* ALT plus CAPS LOCK */

/* ALT unshifted */

/* ALT-SHIFT with or without CAPS LOCK */

/* ALT-CONTROL, must check... */

/* ALT-CONTROL-SHIFT, with or without CAPS LOCK */

	fclose(rom);
	
	return 0;
}
	
