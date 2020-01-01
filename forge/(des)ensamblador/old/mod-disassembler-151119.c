/* 65C02 disassembler module for minimOS
 * last modified 20151119-1328
 * (c) 2015-2020 Carlos J. Santisteban
 * */

/* for standalone compilation */
#include <stdio.h>

// Global variables
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char c, x;
	int dir, oldscan, siz, count, scan, tmp[3];

// Function prototypes
void disassemble(void);		// disassemble for one opcode

// Main function
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

	dir=0;					// code begins here

	arch=fopen("test.bin","rb");	// code to disassemble
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening CODE!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(&(ram[dir]),siz,1,arch);	// read all there

	printf("Go!\n");
	do {
/* repeat this whatever number of lines */
		disassemble();
/* end of module */
	} while (ram[dir]);	// until BRK!

	return 0;
}

// Function definitions
void disassemble(void) {		// disassemble for one opcode
// do not use lines, i
// use dir instead of ptr
// change opcode for tmp[2]
		tmp[2] = ram[dir];	// get opcode
		oldscan = dir;		// before increasing
		printf("%04x: ", dir);	// print initial address
		count = 0;			// skipped strings
		scan = 0;			// opcode list pointer
		while (tmp[2] != count && count<256) {
			while (rom[scan]<128)
				scan++;		// fetch next terminator
			scan++;			// go to next entry
			count++;		// another opcode skipped
		}
		siz = 1;			// bytes to be dumped
		do {
			x	= rom[scan] & 128;	// bit 7 will exit after processing
			c	= rom[scan] & 127;	// mask bit 7 out
			switch(c) {
				case '@':				// single byte operand
					printf("$%02x", ram[++dir]);				// print operand in hex
					siz = 2;			// 2-byte opcode
					break;
				case '&':				// word operand
					printf("$%04x", ram[++dir]+256*ram[++dir]);	// print address in hex
					siz = 3;			// 3-byte opcode
					break;
				default:				// generic character
					printf("%c", c);	// print it
			}							// end of switch
			scan++;						// next character!
		} while (!x);				// until terminator
		dir++;							// next opcode!
		printf("  [ ");					// tabulate!
		for (count=0; count<siz; count++) {
			printf("%02x ", ram[oldscan+count]);		// dump byte
		}
		printf("]\n");
}
