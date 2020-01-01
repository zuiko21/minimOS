/* (c) 2015-2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char b, opcode, c, x, exit=0;
	char buf[80];					// input buffer
	int ptr=0, oldptr, siz, count, scan, oldscan, index;

	arch=fopen("65C02.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List '65C02.bin'!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(rom,siz,1,arch);			// read all
	
	ptr = 0x400;					// set initial address
	do {							// main loop
		printf("%04x: ", ptr);		// prompt
		gets(buf);					// read input buffer
		scan=0;		// reset indexes
		oldscan=0;
		index=0;
		opcode = 0;		// reset opcode to be detected
		do {		// start processing line
			while (buf[index]==' ')		index++;	// skip spaces in input
			while (rom[scan]==' ')		scan++;		// skip spaces in opcode list, last won't do anyway
			b = buf[index];			// get char
			if (b>='a' && b<='z')		b &= 223;	// all uppercase
			c = rom[scan] & 127;	// filtered from opcode list
			x = rom[scan] & 128;	// terminator
//							printf("%c",c);
			if (b!=c) {				// difference found
//							printf("(%02x)",opcode);	//****
				while (rom[scan++]<128);	// seek terminator in opcode list
				oldscan=scan;	// point to start
				opcode++;		// try next
				if (!opcode) {	// checked all of them
//							printf("...end\n");
					x = 1;		// special exit, no more opcodes
				} else {
					index = 0;		// reset index
					x = 0;			// don't exit yet!
				}
			} else {
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
		} while (!x);					// until match found or all opcodes compared
		if (x==128) {						// valid opcode found
			oldscan--;
			printf("[%02x] ", opcode);	// prints opcode hex
			do {
				printf("%c", rom[++oldscan] & 127);	// print chars in opcode list
			} while (rom[oldscan]<128);				// until terminator is found
		} else {
			printf("***ERROR***");		// invalid string
		}
		printf("\n");
		ptr++;					// advance address *********
	} while (-1);


	return 0;
}
