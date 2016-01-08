/* 65C02 symbolic assembler module for minimOS
 * last modified 20151113-1047
 * (c) Carlos J. Santisteban
 * */
 
#include <stdio.h>

/* Global variables */
	char buf[80];					// input buffer
	unsigned char rom[1500];
	unsigned char ram[65536];
	unsigned char opcode, c, x, i;
	char b;
	int ptr=0, oldptr, siz, count, tmp[2];
	int cursor, scan, oldscan;

	FILE* arch;

/* function prototypes */
	char getNextChar(void);		// get next valid character in input
	void getNextOpL(void);			// get next valid character in opcode list
	char hex2Nibble(char b);		// convert one hex cipher into nibble (should be repeated)
	void checkParsed(void);		// make sure all of the input line was parsed

/* main programme */
int main(void) {

	arch=fopen("65C02.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List '65C02.bin'!***\n");
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
			b = getNextChar();		// get next valid character in input
			getNextOpL();			// get next valid character in opcode list
// check out what to look for
			switch(c) {
/* keep comment here to disable operand read */
				case '@':		// get one byte
					tmp[1] = 0;				// reset accumulator, LSB only
					for(i=0;i<2;i++) {		// get two nibbles
						b = hex2Nibble(b);	// convert one hex cipher into nibble (should be repeated)
						// b is 0...15 unless wrong cipher
						if (b<0) {			//***ERROR, not valid cipher***
//							cursor--;		// try to reprocess this char
							break;
						}
						tmp[1] *= 16;		// older value was MSN
						tmp[1] += b;		// add LSN
						cursor++;			// EEEEEEK go for next
						b = getNextChar();	// go for next digit
					}
					scan++;			// continue parsing if possible
					checkParsed();	// make sure all of the input line was parsed
					break;
				case '&':		// get two bytes
					tmp[0] = 0;				// reset accumulator
					tmp[1] = 0;
// convert one hex cipher into nibble (should be repeated)
					for(i=0;i<4;i++) {		// get four nibbles
						b = hex2Nibble(b);	// convert one hex cipher into nibble (should be repeated)
						// b is 0...15 unless wrong cipher
						if (b<0) {			//***ERROR, not valid cipher***
//							cursor--;		// try to reprocess this char
							break;
						}// else {
							tmp[i/2] *= 16;		// older value was MSN
							tmp[i/2] += b;		// add LSN
							cursor++;			// EEEEEEEK go for next
							b = getNextChar();	// get char
						//}
					}
					scan++;			// continue parsing if possible
					checkParsed();	// make sure all of the input line was parsed
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
						checkParsed();	// make sure all of the input line was parsed
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

	char getNextChar(void) {			// get next valid character in input
		char b;
		
		while (buf[cursor]==' ')		cursor++;	// skip spaces in input
		b = buf[cursor];							// get char
		if (b>='a' && b<='z')		b &= 223;	// all uppercase
		
		return b;								// fetched character
	}

	void getNextOpL(void) {						// get next valid character in opcode list
		while (rom[scan]==' ')		scan++;		// skip spaces in opcode list, last won't do anyway
		c = rom[scan] & 127;	// filtered from opcode list
		x = rom[scan] & 128;	// terminator
	}

	void checkParsed(void) {	// make sure all of the input line was parsed
		if (x==128) {			// opcode ended at list, but...
			while (buf[cursor]==' ')		cursor++;	// skip spaces in input
			if (buf[cursor]) {	// some chars remain in input, not this one
				oldscan=scan;	// point to start
				opcode++;		// try next
				cursor = 0;		// reset index
				x = 0;			// don't exit yet!
			}
		}
	}

	char hex2Nibble(char b) {		// convert one hex cipher into nibble *** redone 151113
		b -= '0';	// convert to number
		if (b>9) {								// should be alpha
			b -= 'A'-'0'-10;					// add alpha cipher
		}
		if (b<0 || b>15) {						// invalid number
			//***ERROR, not valid cipher***
			b=-1;							// invalid value
		}

		return b;								// exit with positive value, if valid
	}
