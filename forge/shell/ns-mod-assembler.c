/* non-symbolic assembler for minimOS
 * last modified 20151204-1407
 * (c) 2015-2022 Carlos J. Santisteban
 * */

#include <stdio.h>

/* Global variables */
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char b, i, opcode, c, x;
	char buf[80];					// input buffer
	int ptr=0, oldptr, siz, count, tmp[2], scan, oldscan, cursor;

/* Function prototypes */
void getNextChar(void);		// get next valid character in input
void getListChar(void);		// get next valid character in opcode list
void hex2nibble(void);			// convert one hex cipher into nibble (should be repeated)
void checkEnd(void);			// check whether there's no more in the input line

/* Main programme */
int main(void) {
	arch=fopen("opcodes.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(rom,siz,1,arch);			// read all

	printf(">0400[\n(press ^C to stop)\n");
	ptr = 0x400;					// set initial address
	do {							// main loop
		printf("%04x: ", ptr);		// prompt
		gets(buf);					// read input buffer
		scan=0;		// reset indexes
		oldscan=0;
		cursor=0;
		opcode = 0;		// reset opcode to be detected
		do {		// start processing line
// get next valid character in input
			getNextChar();
// get next valid character in opcode list
			getListChar();
// check out what to look for
			switch(c) {
/* keep comment here to disable operand read */
				case '%':				// relative addressing
										// currently does the same as single-byte operands
				case '@':		// get one byte
					tmp[1] = 0;	// reset accumulator
					for(i=0;i<2;i++) {		// do twice
						hex2nibble();		// convert one hex cipher into nibble (should be repeated)
						if (b==255)		break;		// 255 means there was no valid cipher
						// b is 0...15 unless wrong cipher
						tmp[1] *= 16;		// older value was MSN
						tmp[1] += b;		// add LSN
						// repeat above for next nibble
						cursor++;
						getNextChar();
					}
					scan++;
					checkEnd();				// check whether there's no more in the input line
					break;
				case '&':		// get two bytes
					tmp[0] = 0;	// reset accumulator
					tmp[1] = 0;
					for(i=0;i<4;i++) {		// do four times
						hex2nibble();		// convert one hex cipher into nibble (should be repeated)
						if (b==255)		break;		// 255 means there was no valid cipher
						// b is 0...15 unless wrong cipher
						tmp[i/2] *= 16;		// older value was MSN
						tmp[i/2] += b;		// add LSN
						// repeat above for next nibble
						cursor++;
						getNextChar();
					}
					scan++;
					checkEnd();				// check whether there's no more in the input line
					break;
/* this comment will resume operation if operand fetch is disabled */
				default:		// normal check
					if (b!=c) {				// difference found
// wrong, try next opcode
						while (rom[scan++]<128);	// seek terminator in opcode list
						oldscan=scan;	// point to start
						opcode++;		// try next
						if (!opcode) {	// checked all of them
							x = 1;		// special exit, no more opcodes
						} else {
							cursor = 0;		// reset index
							x = 0;			// don't exit yet!
						}
					} else {
// right, continue checking line
						cursor++;		// advance to next character
						scan++;
						checkEnd();		// check whether there's no more in the input line
					}
			}
		} while (!x);					// until match found or all opcodes compared
		if (x==128) {					// valid opcode found
			oldscan--;
			count = 1;					// bytes to be advanced for next opcode
			printf("[%02x] ", opcode);	// prints opcode hex
			do {
				c = rom[++oldscan] & 127;	// get char from opcode list
				switch(c) {
					case '%':				// relative addressing
											// currently does the same as single-byte operands
					case '@':
						printf("$%02x", tmp[1]);
						count++;			// two-byte instruction
						break;
					case '&':
						printf("$%02x%02x", tmp[0], tmp[1]);
						count += 2;			// three-byte instruction
						break;
					default:
						printf("%c", c);	// print chars in opcode list
				}
			} while (rom[oldscan]<128);		// until terminator is found
		} else {
			count = 0;					// stay here
			printf("***ERROR***");		// invalid string
		}
// should "poke" opcode, tmp[1], tmp[0] at ptr...ptr+2
		printf("\n");
		ptr += count;					// advance address
	} while (-1);

	return 0;
}

/* Function definitions */
void getNextChar(void) {							// get next valid character in input
			while (buf[cursor]==' ')	cursor++;	// skip spaces in input
			b = buf[cursor];						// get char
			if (b>='a' && b<='z')		b &= 223;	// all uppercase
}

void getListChar(void) {							// get next valid character in opcode list
			while (rom[scan]==' ')		scan++;		// skip spaces in opcode list, last won't do anyway
			c = rom[scan] & 127;					// filtered from opcode list
			x = rom[scan] & 128;					// terminator
}

void hex2nibble(void) {		// convert one hex cipher into nibble (should be repeated)
						b -= '0';	// convert to number
						if (b>=0 && b<10) {			// already a valid number
							// nothing to do???
						} else {					// check whether alpha
							if (b>='A'-'0' && b<='F'-'0') {		// valid hex cipher
								b -= 'A'-'0'-10;				// add alpha cipher
							} else {
								//***ERROR, not valid cipher***
								b=255;		// exit value, will trigger break outside
								cursor--;	// try to reprocess this char
							}
						}
}

void checkEnd(void) {			// check whether there's no more in the input line
						if (x==128) {		// opcode ended at list, but...
						while (buf[cursor]==' ')		cursor++;	// skip spaces in input
						if (buf[cursor]) {	// some chars remain in input, not this one
							oldscan=scan;	// point to start
							opcode++;		// try next
							cursor = 0;		// reset index
							x = 0;			// don't exit yet!
						}
					}
}
