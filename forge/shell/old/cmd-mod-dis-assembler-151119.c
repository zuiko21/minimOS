/* 65C02 non-symbolic (dis)assembler with monitor commands for minimOS
 * last modified 20151119-1330
 * (c) 2015-2022 Carlos J. Santisteban
 * */
 
#include <stdio.h>

/* Global variables */
	unsigned char rom[1500];
	unsigned char ram[65536];
	FILE* arch;

	unsigned char b, i, j, c, x, value;
	unsigned char lines = 4;					// number of lines #u to display
	unsigned char areg, xreg, yreg, psr, sp;	// 6502 registers
	char buf[80];								// input buffer
	int ptr=0, dir, count, tmp[3], scan, oldscan, cursor;
	int siz;	// temporarily for opcode list loading, later #n

/* Function prototypes */
void getNextChar(void);		// get next valid character in input
void getListChar(void);		// get next valid character in opcode list
void hex2nibble(void);		// convert one hex cipher into nibble (should be repeated)
void hex2byte(void);		// convert a pair of hex ciphers into byte (calls hex2nibble)
void checkEnd(void);		// check whether there's no more in the input line
void fetchWord(void);		// advance to the next two bytes, convert into tmp[0...1]
void disassemble(void);		// disassemble for one opcode

/* Main programme */
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
		scan=0;			// reset indexes
		oldscan=0;
		cursor=0;
		tmp[2] = 0;		// reset opcode to be detected
		getNextChar();	// get first valid character in input
// check for pseudo-opcodes
		if (b=='.') {			// pseudo-opcode
			cursor++;			// skip dot
			getNextChar();		// get the command itself
			cursor++;			// ready to get operand
			switch(b) {		// identify command
				case 'A':		// set accumulator as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					areg = value;	// store byte
					break;
				case 'B':		// store byte $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					ram[ptr++] = value;		// store byte
					break;
				case 'C':		// call $aaaa*
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];	// compute address
					printf("[JSR $%04x]\n", dir);
					break;
				case 'D':		// disassemble #u lines from $aaaa
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];	// compute base address
					for (i=0; i<lines; i++) {	// will show #u lines
						disassemble();			// decode one opcode
//						printf("[disassembly $%04x...]\n",dir++);
					}
					break;
				case 'E':		// dump #u lines from $aaaa
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];	// compute base address
					for (i=0; i<lines; i++) {	// will show #u lines
						printf("%04x [ ", dir);	// start address
						for (j=0; j<8; j++) {	// eight bytes per line
							printf("%02x ", ram[dir++]);	// show one byte
						}
						printf("] ");			// end hex dump, now in ascii
						for (j=8;j>0;j--) {		// rescan downwards
							c = ram[dir-j];		// gey byte again
							if (c<' ') {		// non-printable
								printf("·");	// interpunct as substitute
							} else {
								printf("%c", c);	// place ascii
							}
						}
						printf("\n");			// new line
					}
					break;
				case 'F':		// force cold boot
					printf("\n---[forced cold boot]---\n");
					return 0;	// go away!
					break;
				case 'G':		// set SP as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					sp = value;	// store byte
					break;
				case 'H':		// show command list
					printf("\nCommand list:\n");
					// ...
					break;
				case 'I':		// show symbol table
					printf("Symbol table:\n");
					// ...
					break;
				case 'J':		// jump to $aaaa*
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];	// compute address
					printf("[JMP $%04x]\n", dir);
					break;
				case 'K':		// set external device as $dd
				
					break;
				case 'L':		// load #n bytes at $aaaa
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];			// compute destination address
					oldscan = dir;
					for (count=0; count<siz; count++) {	// load #n bytes
						// load byte @dir++...
					}
					printf("---$%04x bytes loaded at $%04x---\n", siz, oldscan);	// show results
					break;
				case 'M':		// copy #n bytes from current to $aaaa
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];			// compute destination address
					oldscan = dir;						// save initial value
					scan = ptr;							// copy source address
					for (count=0; count<siz; count++) {	// copy #n bytes
						ram[dir++] = ram[scan++];		// copy from current to destination
					}
					printf("---$%04x bytes copied at $%04x---\n", siz, oldscan);	// show results
					break;
				case 'N':		// set #n as $dddd
					fetchWord();			// get next two bytes in tmp[]
					siz = tmp[1] + 256*tmp[0];	// compute number of bytes #n
					break;
				case 'O':		// set current address as $aaaa
					fetchWord();			// get next two bytes in tmp[]
					ptr = tmp[1] + 256*tmp[0];	// compute new address
					break;
				case 'P':		// set PSR as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					psr = value;	// store byte
					break;
				case 'Q':		// quit or poweroff*
					// check for undefined references
					return 0;	// go away!
					break;
				case 'R':		// reboot*
					// check for undefined references
					printf("\n---[system reboot]---\n");
					ptr = 0x400;	// apparent reset
					continue;
					break;
				case 'S':		// store immediate raw string until EOL
					while(c=buf[cursor++]) {	// get raw char until terminator
						ram[ptr++]=c;			// store in place
					}
					break;
				case 'T':		// save #n bytes from $aaaa
					fetchWord();			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];			// compute source address
					oldscan = dir;						// save for later
					for (count=0; count<siz; count++) {	// save #n bytes
						// save byte @dir++...
					}
					printf("---$%04x bytes saved from $%04x---\n", siz, oldscan);	// show results
					break;
					break;
				case 'U':		// set #u as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					lines = value;	// will show #u lines
					break;
				case 'V':		// view registers
					printf("\nPC:  A: X: Y: S: NV·bDIZC\n");
					printf("%04x %02x %02x %02x %02x 11·11111\n", ptr, areg, xreg, yreg, sp);
					// ...
					break;
				case 'W':		// store word $dddd
					fetchWord();			// get next two bytes in tmp[]
					ram[ptr++] = tmp[1];	// store LSB
					ram[ptr++] = tmp[0];	// store MSB
					break;
				case 'X':		// set X as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					xreg = value;	// store byte
					break;
				case 'Y':		// set Y as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					yreg = value;	// store byte
					break;
				case 'Z':		// poweroff or suspend
					printf("\n---suspend---\n\n");
					break;
				default:
					printf("***Bad command***\n");
			}
			continue;			// command ended, ask for another
		} //else printf("***Bad command***\n");	// *** REMOVE else with assembler
/* *** for symbolic assembler only *** */
		if (b=='_') {			// a label is being defined
			printf("[label definition]\n");	//***placeholder
			continue;			// get another input
		}
		do {		// start processing line
// get next valid character in opcode list
			getListChar();
// check out what to look for
			switch(c) {
// keep C-comment here to disable operand read
				case '@':		// get one byte
					hex2byte();				// get whole number
					tmp[1] = value;			// store converted value
					scan++;
					checkEnd();				// check whether there's no more in the input line
					break;
				case '&':		// get two bytes
					for(i=0;i<2;i++) {		// do couple of bytes
						hex2byte();			// get whole byte
						tmp[i] = value;		// store converted value
					}
					scan++;
					checkEnd();				// check whether there's no more in the input line
					break;
// this C-comment will resume operation if operand fetch is disabled
				default:		// normal check
					if (b!=c) {				// difference found
// wrong, try next opcode
						while (rom[scan++]<128);	// seek terminator in opcode list
						oldscan=scan;	// point to start
						tmp[2]++;		// try next opcode
						if (tmp[2]>255) {	// checked all of them
							x = 1;			// special exit, no more opcodes
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
			getNextChar();				// get next valid character in input
		} while (!x);					// until match found or all opcodes compared
		if (x==128) {					// valid opcode found
				oldscan--;
				count = 1;					// bytes to be advanced for next opcode
				printf("[%02x] ", tmp[2]);	// prints opcode hex
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
// should "poke" tmp[2], tmp[1], tmp[0] at ptr...ptr+2
		for(i=0;i<count;i++) {
			ram[ptr+i] = tmp[2-i];		// poke values
		}
		printf("\n");
		ptr += count;					// advance address
/* *** end of assembler module *** */
	} while (-1);

	return 0;
}

/* Function definitions */
void getNextChar(void) {							// get next valid character in input
			while (buf[cursor]==' ' || buf[cursor]=='$')	cursor++;	// skip spaces AND RADIX in input
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

void hex2byte(void) {			// convert a pair of hex ciphers into byte (calls hex2nibble)
	int loop;

	value = 0;
	for (loop=0; loop<2; loop++) {			// two hex per byte
		hex2nibble();		// convert one hex cipher into nibble (should be repeated)
		if (b==255)
			break;			// 255 means there was no valid cipher
		// b is 0...15 unless wrong cipher
		value *= 16;		// older value was MSN
		value += b;			// add LSN
		cursor++;			// go for next hex
		getNextChar();
	}
}

void checkEnd(void) {			// check whether there's no more in the input line
					if (x==128) {			// opcode ended at list, but...
						while (buf[cursor]==' ' || buf[cursor]=='$')		cursor++;	// skip spaces in input
						if (buf[cursor]) {	// some chars remain in input, not this one
							oldscan=scan;	// point to start
							tmp[2]++;		// try next opcode
							cursor = 0;		// reset index
							x = 0;			// don't exit yet!
						}
					}
}

void fetchWord(void) {		// advance to the next two bytes, convert into tmp[0...1]		
	getNextChar();			// advance to operand
	for(i=0;i<2;i++) {		// do couple of bytes
		hex2byte();			// get whole byte
		tmp[i] = value;		// store converted value
	}
}

void disassemble(void) {		// disassemble for one opcode
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
