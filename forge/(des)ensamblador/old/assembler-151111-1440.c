/* (c) 2015-2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char b, i, opcode, c, x, exit=0;
	char buf[80];					// input buffer
	int ptr=0, oldptr, siz, count, tmp, scan, oldscan, index;

	arch=fopen("65C02.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List '65C02.bin'!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(rom,siz,1,arch);			// read all

printf(">0400[\n");
	ptr = 0x400;					// set initial address
	do {							// main loop
		printf("%04x: ", ptr);		// prompt
		gets(buf);					// read input buffer
		scan=0;		// reset indexes
		oldscan=0;
		index=0;
		opcode = 0;		// reset opcode to be detected
		do {		// start processing line
// get next valid character in input
			while (buf[index]==' ')		index++;	// skip spaces in input
			b = buf[index];			// get char
			if (b>='a' && b<='z')		b &= 223;	// all uppercase
// get next valid character in opcode list
			while (rom[scan]==' ')		scan++;		// skip spaces in opcode list, last won't do anyway
			c = rom[scan] & 127;	// filtered from opcode list
			x = rom[scan] & 128;	// terminator
// check out what to look for
			switch(c) {
/* keep comment here to disable operand read */
				case '@':		// get one byte
					tmp = 0;	// reset accumulator
// convert one hex cipher into nibble (should be repeated)
					for(i=0;i<2;i++) {	//***do twice
						b -= '0';	// convert to number
						if (b>=0 && b<10) {			// already a valid number
							// nothing to do???
						} else {					// check whether alpha
							if (b>='A'-'0' && b<='F'-'0') {		// valid hex cipher
								b -= 'A'-'0'-10;				// add alpha cipher
							} else {
								//***ERROR, not valid cipher***
								b=-1;
								index--;	// try to reprocess this char
printf("?");
								break;
							}
						}
printf("\nNibble=%01x\n",b);
						// b is 0...15 unless wrong cipher
						tmp *= 16;		// older value was MSN
						tmp += b;		// add LSN
						// repeat above for next nibble
						index++;	//****repeat next input char fetch
						while (buf[index]==' ')		index++;	// skip spaces in input
						b = buf[index];			// get char
						if (b>='a' && b<='z')		b &= 223;	// all uppercase
					}
					scan++;
// ***check opcode list end here???
					if (x==128) {			// opcode ended at list, but...
						while (buf[index]==' ')		index++;	// skip spaces in input
						if (buf[index]) {	// some chars remain in input, not this one
							oldscan=scan;	// point to start
							opcode++;		// try next
							index = 0;		// reset index
							x = 0;			// don't exit yet!
						}
					}

					break;
				case '&':		// get two bytes
printf("word...");
					for(i=0;i<4;i++) {	//***do four times
						b -= '0';	// convert to number
						if (b>=0 && b<10) {			// already a valid number
							// nothing to do???
						} else {					// check whether alpha
							if (b>='A'-'0' && b<='F'-'0') {		// valid hex cipher
								b -= 'A'-'0'-10;				// add alpha cipher
							} else {
								//***ERROR, not valid cipher***
								b=-1;
								index--;	// try to reprocess this char
printf("?");
								break;
							}
						}
printf("\nNibble=%01x\n",b);
						// b is 0...15 unless wrong cipher
						// repeat above for next nibble
						index++;	//****repeat next input char fetch
						while (buf[index]==' ')		index++;	// skip spaces in input
						b = buf[index];			// get char
						if (b>='a' && b<='z')		b &= 223;	// all uppercase
					}
					scan++;
// ***check opcode list end here???
					if (x==128) {			// opcode ended at list, but...
						while (buf[index]==' ')		index++;	// skip spaces in input
						if (buf[index]) {	// some chars remain in input, not this one
							oldscan=scan;	// point to start
							opcode++;		// try next
							index = 0;		// reset index
							x = 0;			// don't exit yet!
						}
					}
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
							index = 0;		// reset index
							x = 0;			// don't exit yet!
						}
					} else {
// right, continue checking line
						index++;		// advance to next character
						scan++;
						if (x==128) {			// opcode ended at list, but...
							while (buf[index]==' ')		index++;	// skip spaces in input
							if (buf[index]) {	// some chars remain in input, not this one
								oldscan=scan;	// point to start
								opcode++;		// try next
								index = 0;		// reset index
								x = 0;			// don't exit yet!
							}
						}
					}
			}
		} while (!x);					// until match found or all opcodes compared
		if (x==128) {						// valid opcode found
			oldscan--;
			printf("[%02x] ", opcode);	// prints opcode hex
			do {
				c = rom[++oldscan] & 127;	// get char from opcode list
				switch(c) {
					case '@':
						printf("$%02x", tmp);
						break;
					case '&':
						//break:
					default:
						printf("%c", c);	// print chars in opcode list
				}
			} while (rom[oldscan]<128);				// until terminator is found
		} else {
			printf("***ERROR***");		// invalid string
		}
		printf("\n");
		ptr++;					// advance address *********
	} while (-1);


	return 0;
}
