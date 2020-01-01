/* disassembler for minimOS 0.5a1
 * (c) 2015-2020 Carlos J. Santisteban
 * last modified 20151201-1347
 * */
 
#include <stdio.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char c, opcode, flag;
	int ptr, oldptr, siz, count, scan;

	arch=fopen("opcodes.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(rom,siz,1,arch);			// read all

	ptr=0;					// code begins here

	arch=fopen("test.bin","rb");	// code to disassemble
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening CODE!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(&(ram[ptr]),siz,1,arch);	// read all there

	printf("Go!\n");
	do {
		opcode = ram[ptr];	// get opcode
		oldptr = ptr;		// before increasing
		printf("%04x: ", ptr);	// print initial address
		count = 0;			// skipped strings
		scan = 0;			// opcode list pointer
		while (opcode != count && count<256) {
			while (rom[scan]<128)
				scan++;		// fetch next terminator
			scan++;			// go to next entry
			count++;		// another opcode skipped
		}
		siz = 1;			// bytes to be dumped
		do {
			flag	= rom[scan] & 128;	// bit 7 will exit after processing
			c		= rom[scan] & 127;	// mask bit 7 out
			switch(c) {
				case '%':				// relative addressing
										// currently does the same as single-byte operands
				case '@':				// single byte operand
					printf("$%02x", ram[++ptr]);				// print operand in hex
					siz = 2;			// 2-byte opcode
					break;
				case '&':				// word operand
					printf("$%04x", ram[++ptr]+256*ram[++ptr]);	// print address in hex
					siz = 3;			// 3-byte opcode
					break;
				default:				// generic character
					printf("%c", c);	// print it
			}							// end of switch
			scan++;						// next character!
		} while (!flag);				// until terminator
		ptr++;							// next opcode!
		printf("  [ ");					// tabulate!
		for (count=0; count<siz; count++) {
			printf("%02x ", ram[oldptr+count]);		// dump byte
		}
		printf("]\n");
	} while (ram[ptr]);	// until BRK!

	return 0;
}
