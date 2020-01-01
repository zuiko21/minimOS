/* (c) 2015-2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char b, opcode, c, exit=0;
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
	do {
		printf("%04x: ", ptr);		// prompt
		gets(buf);					// read input buffer
//		printf(" >>> %s\n", buf);	// for testing
		scan = 0;					// initial list position
		opcode = 0;					// byte to be generated
		do {
			index = 0;				// scanning the input
			exit = 0;				// no exit yet
			do {
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
	return 0;
}
