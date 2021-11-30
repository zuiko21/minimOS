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

/* ***                ***
 * *** note new order ***
 * ***                ***
 * *** Bx= ...BS      ***
 * *** Cx= ...CR      ***
 * *** Dx=Up,Lt,Dn,Rt *** */

/* unshifted but CAPS LOCK on */
	row(rom,0xBA,0x09, '<', ' ');	/* 0x= º Tab < Space */
	row(rom, '1', 'Q', 'A', 'Z');	/* 1x= 1 Q A Z */
	row(rom, '2', 'W', 'S', 'X');	/* 2x= 2 W S X */
	row(rom, '3', 'E', 'D', 'C');	/* 3x= 3 E D C */
	row(rom, '4', 'R', 'F', 'V');	/* 4x= 4 R F V */
	row(rom, '5', 'T', 'G', 'B');	/* 5x= 5 T G B */
	row(rom, '6', 'Y', 'H', 'N');	/* 6x= 6 Y H N */
	row(rom, '7', 'U', 'J', 'M');	/* 7x= 7 U J M */
	row(rom, '8', 'I', 'K', ',');	/* 8x= 8 I K , */
	row(rom, '9', 'O', 'L', '.');	/* 9x= 9 O L . */
	row(rom, '0', 'P',0xD1, '-');	/* Ax= 0 P Ñ - */
	row(rom,0x27,0x60,0xB4,0x02);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,0xA1, '+',0xC7,0x06);	/* Cx= ¡ + Ç right */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* Dx= BS, CR, up, down */
	row(rom,0x1B,0x7F,0x19,0x16);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* unshifted without CAPS LOCK */
	row(rom,0xBA,0x09, '<', ' ');	/* 0x= º Tab < Space */
	row(rom, '1', 'q', 'a', 'z');	/* 1x= 1 Q A Z */
	row(rom, '2', 'w', 's', 'x');	/* 2x= 2 W S X */
	row(rom, '3', 'e', 'd', 'c');	/* 3x= 3 E D C */
	row(rom, '4', 'r', 'f', 'v');	/* 4x= 4 R F V */
	row(rom, '5', 't', 'g', 'b');	/* 5x= 5 T G B */
	row(rom, '6', 'y', 'h', 'n');	/* 6x= 6 Y H N */
	row(rom, '7', 'u', 'j', 'm');	/* 7x= 7 U J M */
	row(rom, '8', 'i', 'k', ',');	/* 8x= 8 I K , */
	row(rom, '9', 'o', 'l', '.');	/* 9x= 9 O L . */
	row(rom, '0', 'p',0xF1, '-');	/* Ax= 0 P Ñ - */
	row(rom,0x27,0x60,0xB4,0x02);	/* apostrophe, backtick, acute accent, cursor left */
	row(rom,0xA1, '+',0xE7,0x06);	/* Cx= ¡ + Ç right */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* Dx= BS, CR, up, down */
	row(rom,0x1B,0x7F,0x19,0x16);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* shifted, with or without CAPS LOCK */
	row(rom,0xAA,0x0B, '>', ' ');	/* 0x= º Tab < Space, shift-Tab like VT (or cursor up) */
	row(rom, '!', 'Q', 'A', 'Z');	/* 1x= 1 Q A Z */
	row(rom,0x22, 'W', 'S', 'X');	/* 2x= 2 W S X */
	row(rom,0xB7, 'E', 'D', 'C');	/* 3x= 3 E D C */
	row(rom, '$', 'R', 'F', 'V');	/* 4x= 4 R F V */
	row(rom, '%', 'T', 'G', 'B');	/* 5x= 5 T G B */
	row(rom, '&', 'Y', 'H', 'N');	/* 6x= 6 Y H N */
	row(rom, '/', 'U', 'J', 'M');	/* 7x= 7 U J M */
	row(rom, '(', 'I', 'K', ',');	/* 8x= 8 I K , */
	row(rom, ')', 'O', 'L', '.');	/* 9x= 9 O L . */
	row(rom, '=', 'P',0xD1, '-');	/* Ax= 0 P Ñ - */
	row(rom, '?', '^',0xA8,0x02);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,0xBF, '*',0xC7,0x06);	/* Cx= ¡ + Ç right */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* Dx= BS, CR, up, down */
	row(rom,0x1B,0x7F,0x19,0x16);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

	row(rom,0xAA,0x0B, '>', ' ');	/* 0x= º Tab < Space, shift-Tab like VT (or cursor up) */
	row(rom, '!', 'Q', 'A', 'Z');	/* 1x= 1 Q A Z */
	row(rom,0x22, 'W', 'S', 'X');	/* 2x= 2 W S X */
	row(rom,0xB7, 'E', 'D', 'C');	/* 3x= 3 E D C */
	row(rom, '$', 'R', 'F', 'V');	/* 4x= 4 R F V */
	row(rom, '%', 'T', 'G', 'B');	/* 5x= 5 T G B */
	row(rom, '&', 'Y', 'H', 'N');	/* 6x= 6 Y H N */
	row(rom, '/', 'U', 'J', 'M');	/* 7x= 7 U J M */
	row(rom, '(', 'I', 'K', ',');	/* 8x= 8 I K , */
	row(rom, ')', 'O', 'L', '.');	/* 9x= 9 O L . */
	row(rom, '=', 'P',0xD1, '-');	/* Ax= 0 P Ñ - */
	row(rom, '?', '^',0xA8,0x02);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,0xBF, '*',0xC7,0x06);	/* Cx= ¡ + Ç right */
	row(rom,0x08,0x0D,0x0B,0x0A);	/* Dx= BS, CR, up, down */
	row(rom,0x1B,0x7F,0x19,0x16);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* CONTROL with or without CAPS LOCK */
/* basic keys follow PASK standard, currently undetermined values are 00 */
	row(rom,  00,  00,  00,0x80);	/* 0x= º Tab < NBSP */
	row(rom, '+',0x11,0x01,0x1A);	/* 1x= 1 Q A Z */
	row(rom,0x27,0x17,0x13,0x18);	/* 2x= 2 W S X */
	row(rom, '.',0x05,0x04,0x03);	/* 3x= 3 E D C */
	row(rom, ',',0x12,0x06,0x16);	/* 4x= 4 R F V */
	row(rom, ':',0x14,0x07,0x02);	/* 5x= 5 T G B */
	row(rom, ';',0x19,0x08,0x0E);	/* 6x= 6 Y H N */
	row(rom, '-',0x15,0x0A,0x0D);	/* 7x= 7 U J M */
	row(rom, '<',0x09,0x0B,  00);	/* 8x= 8 I K , */
	row(rom, '>',0x0F,0x0C,  00);	/* 9x= 9 O L . */
	row(rom, '_',0x10,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

	row(rom,  00,  00,  00,0x80);	/* 0x= º Tab < NBSP */
	row(rom, '+',0x11,0x01,0x1A);	/* 1x= 1 Q A Z */
	row(rom,0x27,0x17,0x13,0x18);	/* 2x= 2 W S X */
	row(rom, '.',0x05,0x04,0x03);	/* 3x= 3 E D C */
	row(rom, ',',0x12,0x06,0x16);	/* 4x= 4 R F V */
	row(rom, ':',0x14,0x07,0x02);	/* 5x= 5 T G B */
	row(rom, ';',0x19,0x08,0x0E);	/* 6x= 6 Y H N */
	row(rom, '-',0x15,0x0A,0x0D);	/* 7x= 7 U J M */
	row(rom, '<',0x09,0x0B,  00);	/* 8x= 8 I K , */
	row(rom, '>',0x0F,0x0C,  00);	/* 9x= 9 O L . */
	row(rom, '_',0x10,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* CONTROL-SHIFT with CAPS LOCK */
	row(rom,  00,  00,  00,  00);	/* 0x= º Tab < Space (should ctrl-shift-space render $20?) */
	row(rom,0x1B,0xBD,0xC2,0x87);	/* 1x= 1 Q A Z */
	row(rom,0x1C,0x81,0x85,0x8B);	/* 2x= 2 W S X */
	row(rom,0x1D,0xCA,0x8A,0x8D);	/* 3x= 3 E D C */
	row(rom,0x1E,0x86,0x8F,0x8E);	/* 4x= 4 R F V */
	row(rom,0x1F,0x89,0xC3,0x83);	/* 5x= 5 T G B */
	row(rom, '^',0x82,0xC6,0x8C);	/* 6x= 6 Y H N */
	row(rom, '?',0xDB,0x88,0x0D);	/* 7x= 7 U J M */
	row(rom, '[',0xCE,0xD5,  00);	/* 8x= 8 I K , */
	row(rom, ']',0xD4,0xC5,  00);	/* 9x= 9 O L . */
	row(rom,0x7F,0x84,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* CONTROL-SHIFT without CAPS LOCK */
	row(rom,  00,  00,  00,  00);	/* 0x= º Tab < Space (should ctrl-shift-space render $20?) */
	row(rom,0x1B,0xBD,0xE2,0x87);	/* 1x= 1 Q A Z */
	row(rom,0x1C,0x81,0x85,0x8B);	/* 2x= 2 W S X */
	row(rom,0x1D,0xEA,0x8A,0x8D);	/* 3x= 3 E D C */
	row(rom,0x1E,0x86,0x8F,0x8E);	/* 4x= 4 R F V */
	row(rom,0x1F,0x89,0xC3,0x83);	/* 5x= 5 T G B */
	row(rom, '^',0x82,0xC6,0x8C);	/* 6x= 6 Y H N */
	row(rom, '?',0xFB,0x88,0x0D);	/* 7x= 7 U J M */
	row(rom, '[',0xEE,0xD5,  00);	/* 8x= 8 I K , */
	row(rom, ']',0xF4,0xC5,  00);	/* 9x= 9 O L . */
	row(rom,0x7F,0x84,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* ALT plus CAPS LOCK */
	row(rom,  00,  00,  00,0xA0);	/* 0x= º Tab < Space */
	row(rom, '|',0xD8,0xC1,0xDE);	/* 1x= 1 Q A Z */
	row(rom, '@',0x9A,0xA7,0xD7);	/* 2x= 2 W S X */
	row(rom, '#',0xC9,0xD0,0xC7);	/* 3x= 3 E D C */
	row(rom,0xA4,0x95,  00,0x91);	/* 4x= 4 R F V */
	row(rom,0xBA,0x97,0xC3,0xDF);	/* 5x= 5 T G B */
	row(rom,0xAC,0xDD,0xC6,0xD1);	/* 6x= 6 Y H N */
	row(rom,0xA6,0xDA,  00,0xB5);	/* 7x= 7 U J M */
	row(rom, '{',0xCD,0xD5,  00);	/* 8x= 8 I K , */
	row(rom, '}',0xD3,0xC5,  00);	/* 9x= 9 O L . */
	row(rom, '~',0xB6,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* ALT unshifted */
	row(rom,  00,  00,  00,0xA0);	/* 0x= º Tab < Space */
	row(rom, '|',0xF8,0xE1,0xFE);	/* 1x= 1 Q A Z */
	row(rom, '@',0xB8,0xA7,0xD7);	/* 2x= 2 W S X */
	row(rom, '#',0xE9,0xF0,0xE7);	/* 3x= 3 E D C */
	row(rom,0xA4,0x95,  00,0x91);	/* 4x= 4 R F V */
	row(rom,0xBA,0x97,0xE3,0xDF);	/* 5x= 5 T G B */
	row(rom,0xAC,0xFD,0xE6,0xF1);	/* 6x= 6 Y H N */
	row(rom,0xA6,0xFA,  00,0xB5);	/* 7x= 7 U J M */
	row(rom, '{',0xED,0xF5,  00);	/* 8x= 8 I K , */
	row(rom, '}',0xF3,0xE5,  00);	/* 9x= 9 O L . */
	row(rom, '~',0xB6,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* ALT-SHIFT with or without CAPS LOCK */
	row(rom,  00,  00,  00,  00);	/* 0x= º Tab < Space */
	row(rom,0xA1,0xD8,0xC1,0xDE);	/* 1x= 1 Q A Z */
	row(rom,  00,0x9A,0x9F,  00);	/* 2x= 2 W S X */
	row(rom,0xBC,0xC9,0xD0,0xC7);	/* 3x= 3 E D C */
	row(rom,0xA3,0xB0,  00,  00);	/* 4x= 4 R F V */
	row(rom,0xAA,0xA8,0xC2,  00);	/* 5x= 5 T G B */
	row(rom,0xB4,0xDD,0xCA,0xD1);	/* 6x= 6 Y H N */
	row(rom,'\\',0xDA,0xCE,  00);	/* 7x= 7 U J M */
	row(rom,0xAB,0xCD,0xD4,  00);	/* 8x= 8 I K , */
	row(rom,0xBB,0xD3,0xDB,  00);	/* 9x= 9 O L . */
	row(rom,0x9D,  00,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

	row(rom,  00,  00,  00,  00);	/* 0x= º Tab < Space */
	row(rom,0xA1,0xD8,0xC1,0xDE);	/* 1x= 1 Q A Z */
	row(rom,  00,0x9A,0x9F,  00);	/* 2x= 2 W S X */
	row(rom,0xBC,0xC9,0xD0,0xC7);	/* 3x= 3 E D C */
	row(rom,0xA3,0xB0,  00,  00);	/* 4x= 4 R F V */
	row(rom,0xAA,0xA8,0xC2,  00);	/* 5x= 5 T G B */
	row(rom,0xB4,0xDD,0xCA,0xD1);	/* 6x= 6 Y H N */
	row(rom,'\\',0xDA,0xCE,  00);	/* 7x= 7 U J M */
	row(rom,0xAB,0xCD,0xD4,  00);	/* 8x= 8 I K , */
	row(rom,0xBB,0xD3,0xDB,  00);	/* 9x= 9 O L . */
	row(rom,0x9D,  00,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* ALT-CONTROL with CAPS LOCK */
	row(rom,  00,  00,  00,   0);	/* 0x= º Tab < Space */
	row(rom,0x2A,  00,0xC4,0x99);	/* 1x= 1 Q A Z */
	row(rom,0xA2,  00,0x94,0x90);	/* 2x= 2 W S X */
	row(rom,0xB1,0xCB,0x9B,0xA9);	/* 3x= 3 E D C */
	row(rom,0xA5,0xAE,  00,0xB9);	/* 4x= 4 R F V */
	row(rom,0xF7,0x92,0xC0,  00);	/* 5x= 5 T G B */
	row(rom, '`',0xFF,0xC8,0xBE);	/* 6x= 6 Y H N */
	row(rom,0xBF,0xDC,0xCC,0x9E);	/* 7x= 7 U J M */
	row(rom,0x96,0xCF,0xD2,  00);	/* 8x= 8 I K , */
	row(rom,0x98,0xD6,0xD9,  00);	/* 9x= 9 O L . */
	row(rom,0xAD,0x93,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* ALT-CONTROL, unshifted otherwise */
	row(rom,  00,  00,  00,   0);	/* 0x= º Tab < Space */
	row(rom,0x2A,  00,0xE4,0x99);	/* 1x= 1 Q A Z */
	row(rom,0xA2,  00,0x94,0x90);	/* 2x= 2 W S X */
	row(rom,0xB1,0xEB,0x9B,0xA9);	/* 3x= 3 E D C */
	row(rom,0xA5,0xAE,  00,0xB9);	/* 4x= 4 R F V */
	row(rom,0xF7,0x92,0xE0,  00);	/* 5x= 5 T G B */
	row(rom, '`',0xFF,0xE8,0xBE);	/* 6x= 6 Y H N */
	row(rom,0xBF,0xFC,0xEC,0x9E);	/* 7x= 7 U J M */
	row(rom,0x96,0xEF,0xF2,  00);	/* 8x= 8 I K , */
	row(rom,0x98,0xF6,0xF9,  00);	/* 9x= 9 O L . */
	row(rom,0xAD,0x93,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

/* ALT-CONTROL-SHIFT, with or without CAPS LOCK */
	row(rom,  00,  00,  00,  00);	/* 0x= º Tab < Space */
	row(rom,  00,  00,0xC4,  00);	/* 1x= 1 Q A Z */
	row(rom,0xB2,  00,  00,  00);	/* 2x= 2 W S X */
	row(rom,0xB3,0xCB,  00,  00);	/* 3x= 3 E D C */
	row(rom,  00,  00,  00,  00);	/* 4x= 4 R F V */
	row(rom,  00,  00,0xC0,  00);	/* 5x= 5 T G B */
	row(rom,  00,  00,0xC8,  00);	/* 6x= 6 Y H N */
	row(rom,  00,0xDC,0xCC,  00);	/* 7x= 7 U J M */
	row(rom,0x9C,0xCF,0xD2,  00);	/* 8x= 8 I K , */
	row(rom,  00,0xD6,0xD9,  00);	/* 9x= 9 O L . */
	row(rom,0xAF,  00,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

	row(rom,  00,  00,  00,  00);	/* 0x= º Tab < Space */
	row(rom,  00,  00,0xC4,  00);	/* 1x= 1 Q A Z */
	row(rom,0xB2,  00,  00,  00);	/* 2x= 2 W S X */
	row(rom,0xB3,0xCB,  00,  00);	/* 3x= 3 E D C */
	row(rom,  00,  00,  00,  00);	/* 4x= 4 R F V */
	row(rom,  00,  00,0xC0,  00);	/* 5x= 5 T G B */
	row(rom,  00,  00,0xC8,  00);	/* 6x= 6 Y H N */
	row(rom,  00,0xDC,0xCC,  00);	/* 7x= 7 U J M */
	row(rom,0x9C,0xCF,0xD2,  00);	/* 8x= 8 I K , */
	row(rom,  00,0xD6,0xD9,  00);	/* 9x= 9 O L . */
	row(rom,0xAF,  00,  00,  00);	/* Ax= 0 P Ñ - */
	row(rom,  00,  00,  00,  00);	/* Bx= apostrophe, backtick, acute accent, cursor left */
	row(rom,  00,  00,  00,  00);	/* Cx= ¡ + Ç right */
	row(rom,  00,  00,  00,  00);	/* Dx= BS, CR, up, down */
	row(rom,  00,  00,  00,  00);	/* Ex= ESC, DEL, PgUp, PgDown */
	row(rom,   0,   0,   0,   0);	/* Fx (MODIFIERS)= CapsLock, Shift, Control, Alt */

	fclose(rom);

/* *********************
 * *** control EPROM ***
 * ********************* */
	rom=fopen("iox-ctl.bin", "wb");
	if (rom==NULL) {
		printf("*** Can't write to control ROM ***\n\n");
		return -1;
	}

/* this is hard
 * D7...D0 = /MOD, ALT, CTL, SHIFT, /CAPS, (NC), /STB, /ACK
 * STB is not used currently (might be generated from /ACK, although will send NUL on CAPS LOCK)
 * ACK stops the clock, whenever a valid key press will generate a char (CAPS will enable it too)
 * MOD detects the modifier column, latching the modifier key combo as a new address range
 * note these latched modifiers come from the control EPROM, addressed by the keyboard rows
 * 
 * thus, /ACK is 0 on any valid char, 1 otherwise, except...
 * CAPS LOCK, when pressed, generates /ACK too, although char code is NUL
 * /STB (only used by a Centronics/VIA interface) is the same as /ACK except 1 on CAPS LOCK
 * /CAPS reflects the status of A8, toggling when the CAPS LOCK key is pressed
 * since the clock is stopped, toggling A8 should keep D7 constant, thus no more latching is done
 * SHIFT, CTL, ALT will be latched upon /MOD, affecting A9, A10 and A11
 * */

	fclose(rom);

	return 0;
}

