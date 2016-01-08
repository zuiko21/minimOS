#include <stdio.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char b, opcode, c, x, exit=0;
	char buf[80];					// input buffer
	int ptr=0, oldptr, siz, count, scan, index;

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
//		printf(" >>> %s\n", buf);	// for testing
/*		scan = 0;					// initial list position
		opcode = 0;					// byte to be generated
		do {						// scan chars in line
			index = 0;				// reset cursor
			exit = 0;				// no exit yet
			do {					// find matching opcode
				while (buf[index]==' ') {	// skip spaces in bufffer
					index++;
				}
				while (rom[scan]==' ') {	// skip spaces in list, unless at end of token
					scan++;
				}
				b = buf[index];		// get input char
				if (b>='a' && b<='z') {		// alpha?
					b &= 223;				// go uppercase
				}
				c = rom[scan] && 127;		// get unterminated from list
*/
		scan=0;		// reset indexes
		index=0;
		opcode = 0;		// reset opcode to be detected
		do {		// scan each char in input line
		printf("Opcode%d?[",opcode);
			do {			// compare with opcode list
				while (buf[index]==' ')		index++;	// skip spaces in input
				b = buf[index++];	// get char
				if (b>='a' && b<='z')	b &= 223;		// all uppercase
				printf("%c",b);
				while (rom[scan]==' ')	scan++;		// skip spaces in opcode list
				c = rom[scan] & 127;				// mask out bit7
				x = rom[scan++] & 128;				// detect end of opcode
			} while (c == b && x);					// until full match or difference
		} while (!x && opcode<256 && c);		// until match is found or bust
		//**testing**
		if (c==b) {
			printf("Opcode (%02x) ", opcode);
			scan--;
			while (rom[--scan]<128);	// go backwards
			scan++;						// back to original opcode
			do {
				printf("%c", rom[scan++] & 127);	// print chars in opcode list
			} while (rom[scan]<128);
			printf("\n");
		} else {
			printf("(%02x) ???\n");
				index = 0;	// reset input buffer cursor
				while (rom[scan]<128)	scan++;	// reach terminator
				scan++;		// get into next opcode
				opcode++;
		}
	} while (-1);
	
	return 0;
}
