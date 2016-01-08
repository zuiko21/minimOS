#include <stdio.h>
#include <stdlib.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char c, opcode, flag;
	int ptr=0, oldptr, siz, count, scan;

	arch=fopen("65C02.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List '65C02.bin'!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(rom,siz,1,arch);			// read all

	arch=fopen("test.bin","rb");	// code to disassemble
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening CODE!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(ram,siz,1,arch);			// read all

	do {
		opcode=ram[ptr];	// get opcode
		
		printf("%04x: %02x... ", ptr, opcode);	// print initial values
		count = 0;			// skipped strings
		scan = 0;			// opcode list pointer
//		oldptr = ptr;		// keep opcode pointer
		while (opcode != count) {
			while (rom[scan]<128)
				scan++;		// fetch next terminator
			scan++;			// go to next entry
			count++;		// another opcode skipped
		}
		do {
			flag	= rom[scan] & 128;	// bit 7 will exit after processing
			c		= rom[scan] & 127;	// mask bit 7 out
			switch(c) {
				case '@':				// single byte operand
					printf("$%02x", ram[++ptr]);				// print operand in hex
					break;
				case '&':				// word operand
					printf("$%04x", ram[++ptr]+256*ram[++ptr]);	// print address in hex
					break;
				default:				// generic character
					printf("%c", c);	// print it
			}							// end of switch
			scan++;						// next character!
		} while (!flag);				// until terminator
		ptr++;							// next opcode!
		printf("\n");
	} while (ram[ptr]);	// until BRK!

	return 0;
}
