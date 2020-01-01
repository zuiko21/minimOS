/* (c) 2015-2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char c, opcode, flag, exit=0;
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
		flag = 0;					// not found yet
		while (opcode<256 && !flag) {
			index = 0;				// scanning the input
			while (buf[index]!=(rom[scan]&127) && buf[index]) {
				index++;			// keep scanning chars
				scan++;
			}
			// ---check values---
			if (buf[index]==rom[scan]) {	// match!
				flag=1;
			} else {						// not this one
				while(rom[scan]>=128)	scan++;	// seek terminator
				scan++;							// get into next opcode
				opcode++;
			}
		}
		if (opcode<256)		printf("OPCODE: %02x\n", opcode);
	} while (!exit);				// until asked to leave

	return 0;
}
