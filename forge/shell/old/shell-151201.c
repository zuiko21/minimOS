/* Symbolic (dis)assembler with monitor commands for minimOS
 * last modified 20151201-1409
 * (c) 2015-2020 Carlos J. Santisteban
 * */
 
#include <stdio.h>

/* Function prototypes */
void getNextChar(void);		// get next valid character in input
void getListChar(void);		// get next valid character in opcode list
void hex2byte(void);		// convert a pair of hex ciphers into byte (calls hex2nibble)
void checkEnd(void);		// check whether there's no more in the input line
void fetchValue(int bytes);	// advance to the next n bytes, convert into tmp[0...1]
void disassemble(void);		// disassemble for one opcode
void scanLabel(void);		// looks for a label in symbol table

/* Global variables */
	unsigned char rom[1500];
	unsigned char ram[65536];

	FILE* arch;

	unsigned char b, i, j, c, x, value;
	unsigned char lines = 4;					// number of lines #u to display
	unsigned char areg, xreg, yreg, psr, sp;	// 6502 registers
	char buf[80];								// input buffer
	int ptr=0, dir, count, tmp[3], scan, os, oldscan, cursor, si;
	int siz;	// temporarily for opcode list loading, later #n

//char undef=0, undfr=0, empty=0;	// *** uncomment if no symbolic assembler is used ***

/* ***for symbolic assembler only*** */
	unsigned char sym[256];	// symbol table: up to 6 chars, 2 of pointer
								// if bit7 of byte0, non-defined label, byte 6 points to linked list of previous references
								// byte 7 points to linked list of previous RELATIVE references
								// byte0.bit7 and any of bytes6-7 at 0 means no such kind of reference used
	unsigned char ref[256];		// linked list of undefined references
								// [n]=link to next, [n+1,n+2] = address of reference
	unsigned char rrf[256];		// linked list of undefined RELATIVE references
								// [n]=link to next, [n+1,n+2] = address of reference
	int empty = 0;				// first empty entry in symbol table (8*used symbols)
	unsigned char lref  = 0;	// last undefined reference offset
	unsigned char lrrf  = 0;	// last undefined RELATIVE reference offset
	unsigned char undef = 0;	// undefined references
	unsigned char undfr = 0;	// undefined RELATIVE references

/* Main programme */
int main(void) {

/* ***initialize symbol table, if available*** */
	for(scan=0;scan<256;scan+=8) {	// one entry each 8 bytes
		sym[scan]=0;				// terminate string
		sym[scan+6]=0;				// reset link and pointer
		sym[scan+7]=0;
	}
	for (scan=0;scan<256;scan++) {	// clear whole reference list
		ref[scan]=0;
		rrf[scan]=0;
		//sym[scan]=0;	// let us clear it all, just in case
	}

/* ***fake symbols for testing*** /
sym[0]='a'+128;	//undefined test entry
sym[1]='x';
sym[2]=0;

sym[7]=1;		//first (and only) RELATIVE reference

rrf[1]=0x05;	//referenced at $0405 (relative)
rrf[2]=0x04;
lrrf=3;			//offset for future next relative undefined reference
undfr=1;		//one relative undefined reference, if goes down to zero should reset lrrf!
				//ditto with undef resetting lref!

sym[8]='l';		//test entry
sym[9]='o';
sym[10]='o';
sym[11]='p';
sym[12]=0;
sym[14]=0x34;
sym[15]=0x12;

sym[16]='a';	// another entry, partly matching another one
sym[17]='x';
sym[18]='o';
sym[19]='n';
sym[20]=0;

sym[22]=0xfe;
sym[23]=0xca;

sym[24]='z';	// zeropage reference
sym[25]='p';
sym[26]=0;

sym[30]=0xf8;
sym[31]=0;		//zeropage

empty=32;		// four entries
/* end of testing block */

// load files
	arch=fopen("opcodes.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(rom,siz,1,arch);			// read all

// start up things
	printf("minimOS 0.5b1 Symbolic 65C02 Assembler/Monitor\n");
	printf("(c)2015 Carlos J. Santisteban\n");
	ptr = 0x400;					// set initial address
	do {							// main loop
		printf("%04x: ", ptr);		// prompt
		gets(buf);					// read input buffer
		scan=0;			// reset indexes
		oldscan=0;
		cursor=0;
		tmp[2] = 0;		// reset opcode to be detected
		cursor--;		// undo first advance
		getNextChar();	// get first valid character in input
// check for pseudo-opcodes
		if (b=='.') {			// pseudo-opcode
			getNextChar();		// get the command itself
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
					if (undef|undfr) {		// some pending definition
						printf("***UNDEFINED LABELS***\n");
					} else {
						fetchValue(2);			// get next two bytes in tmp[]
						dir = tmp[1] + 256*tmp[0];	// compute address
						printf("[JSR $%04x]\n", dir);
					}
					break;
				case 'D':		// disassemble #u lines from $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];	// compute base address
					for (i=0; i<lines; i++) {	// will show #u lines
						disassemble();			// decode one opcode
					}
					printf("----\n");
					break;
				case 'E':		// dump #u lines from $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];	// compute base address
					for (i=0; i<lines; i++) {	// will show #u lines
						printf("%04x [ ", dir);	// start address
						for (j=0; j<8; j++) {	// eight bytes per line
							printf("%02x ", ram[dir++]);	// show one byte
						}
						printf("] ");			// end hex dump, now in ascii
						for (j=8;j>0;j--) {		// rescan downwards
							c = ram[dir-j];		// get byte again
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
/* ***only if symbolic assembler*** */
					printf("Symbol table:\n");
					i = 0;
					while(sym[i] && i!=1) {			// review all entries
						while(sym[i] && (i&7)<6) {	// read whole name
							c = sym[i] & 127;		// filter character
							if (!(i&7))	{			// first character
								x = sym[i] & 128;	// detect undefined
							}
							printf("%c", c);		// put filtered character
							i++;					// next character
						}
						while((i&7)<6) {			// fill remaining space
							printf(" ");
							i++;
						}
						i &= 0xF8;					// filter lower bits
						i |= 6;						// go to offset 6
						if (x) {					// undefined
							printf(" = ?\n");
						} else {					// show value
							printf(" = $%02x%02x\n", sym[i+1], sym[i]);	// little endian
						}
						i += 2;						// next entry
						if (!i) {					// wrapped to zero?
							i = 1;					// special exit value
						}
					}
/* end of symbol table display */
					printf("------\n");
					break;
				case 'J':		// jump to $aaaa*
					if (undef|undfr) {		// some pending definition
						printf("***UNDEFINED LABELS***\n");
					} else {
						fetchValue(2);			// get next two bytes in tmp[]
						dir = tmp[1] + 256*tmp[0];	// compute address
						printf("[JMP $%04x]\n", dir);
					}
					break;
				case 'K':		// set external device as $dd
				
					break;
				case 'L':		// load #n bytes at $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];			// compute destination address
					oldscan = dir;
					for (count=0; count<siz; count++) {	// load #n bytes
						// load byte @dir++...
					}
					printf("---$%04x bytes loaded at $%04x---\n", siz, oldscan);	// show results
					break;
				case 'M':		// copy #n bytes from current to $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];			// compute destination address
					oldscan = dir;						// save initial value
					scan = ptr;							// copy source address
					for (count=0; count<siz; count++) {	// copy #n bytes
						ram[dir++] = ram[scan++];		// copy from current to destination
					}
					printf("---$%04x bytes copied at $%04x---\n", siz, oldscan);	// show results
					break;
				case 'N':		// set #n as $dddd
					fetchValue(2);			// get next two bytes in tmp[]
					siz = tmp[1] + 256*tmp[0];	// compute number of bytes #n
					break;
				case 'O':		// set current address as $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
					ptr = tmp[1] + 256*tmp[0];	// compute new address
					break;
				case 'P':		// set PSR as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					psr = value;	// store byte
					break;
				case 'Q':		// quit or poweroff*
					if (undef|undfr) {		// some pending definition
						printf("***UNDEFINED LABELS***\n");
					} else {
						return 0;	// go away!
					}
					break;
				case 'R':		// reboot*
					if (undef|undfr) {		// some pending definition
						printf("***UNDEFINED LABELS***\n");
					} else {
						printf("\n---[system reboot]---\n");
						ptr = 0x400;	// apparent reset
						continue;
					}
					break;
				case 'S':		// store immediate raw string until EOL
					cursor++;	// skip the 'S'!
					while(c=buf[cursor++]) {	// get raw char until terminator
						ram[ptr++]=c;			// store in place
					}
					// does NOT store the termination byte, use cursor++ if desired
					break;
				case 'T':		// save #n bytes from $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
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
					printf("%04x %02x %02x %02x %02x ", ptr, areg, xreg, yreg, sp);
					for (i=128;i;i/=2) {	// binary backwards loop
						if (i==32) {
							i=16;			// skip unused bit
							printf("·");
						}
						if (psr&i) {		// check that bit
							printf("1");	// asserted
						} else {
							printf("0");	// negated
						}
					}
					printf("\n");
					break;
				case 'W':		// store word $dddd
					fetchValue(2);			// get next two bytes in tmp[]
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
		} //else printf("***Missing module***\n");	// *** REMOVE else with assembler
/* *** for symbolic assembler only *** */
		if (b=='_') {			// a label is being defined
			scanLabel();					// looks for a label in symbol table, (x) if found
			if (x) {						// match found
				if (sym[si&248] & 128) {	// was it pending definition?
					si &= 248;			// forget name offset
					sym[si] &= 127;		// no longer undefined
					si |= 6;				// add offset for pointer
					tmp[0] = sym[si];		// get offset for first absolute reference
					sym[si++] = ptr&255;	// store current LSB
					tmp[1] = sym[si];		// get offset for first relative reference
					sym[si] = ptr/256;	// store current MSB
					// define pending absolute references
					if (tmp[0]) {			// there were absolute references
						undef--;				// EEEEEEEEEEEEEEK!!!!!!!!!
						if (!undef) {			// all defined now?
							lref = 0;			// clear list of undefined absolute references
						}
					}
					while(tmp[0]) {			// run thru linked list
						dir = ref[tmp[0]]+256*ref[tmp[0]+1];	// pointer to undeclared reference
						ram[dir] = sym[si-1];					// copy LSB
						ram[dir+1] = sym[si];					// copy MSB
						tmp[0]=ref[tmp[0]-1];		// next item
					}
					// define pending RELATIVE references
					if (tmp[1]) {			// there were relative references
						undfr--;				// EEEEEEEEEEEEEEK!!!!!!!!!
						if (!undfr) {			// all defined now?
							lrrf = 0;			// clear list of undefined relative references
						}
					}
					while(tmp[1]) {			// run thru linked list
						dir = rrf[tmp[1]]+256*rrf[tmp[1]+1];	// pointer to undeclared reference
						ram[dir]=sym[si-1]+256*sym[si]-dir-1;	// compute relative offset
						tmp[1]=rrf[tmp[1]-1];		// next item
					}
				} else {					// no redeclaration allowed
					printf("***ALREADY DEFINED***\n");
				}
			} else {						// never referenced before
				if (si<256) {				// room for at least one more
					// create entry
					cursor = oldscan-1;		// go back to beginning of name
					getNextChar();
					while (b && ((si&7)<6)) {		// loop until terminator or 6-char limit
						sym[si++] = b|32;			// copy as lowercase
						getNextChar();				// go for next
					}
					if ((si&7)<6) {		// some space remaining
						sym[si]=0;		// terminate if less than 6 chars
					}
					si &= 248;			// forget name offset
					si |= 6;				// add offset for pointer
					sym[si++] = ptr&255;	// store current LSB
					sym[si++] = ptr/256;	// store current MSB
					empty = si;			// another entry exists
				} else  {					// no room
					printf("***NO MORE LABELS***");
				}
			}
			continue;			// get another input
		}
/* end of symbol definition */
/* ***disable if no assembler module is used*** */
		do {		// start processing line
// get next valid character in opcode list
			getListChar();
// check out what to look for
			switch(c) {
// keep C-comment here to disable operand read
				case '%':				// relative addressing
										// currently does the same as single-byte operands
				case '@':		// get one byte
					cursor--;				// back to value
					fetchValue(1);			// get whole number
					if (count!=1) {			// abort if wrong size
						cursor = 0;			// reset index
						x = 0;				// don't exit yet!
					} else {
						tmp[1]=tmp[0];		// correct endianness!!!
						scan++;
						checkEnd();			// check whether there's no more in the input line
					}
					break;
				case '&':		// get two bytes
					cursor--;				// back to value
					fetchValue(2);			// get whole word
					if (count!=2) {			// abort if wrong size
						cursor = 0;			// reset index
						x = 0;				// don't exit yet!
					} else {
						scan++;
						checkEnd();			// check whether there's no more in the input line
					}
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
			cursor--;					// correction needed???
			getNextChar();				// get next valid character in input
		} while (!x);					// until match found or all opcodes compared
		if (x==128) {					// valid opcode found
				oldscan--;
				count = 1;					// bytes to be advanced for next opcode
				printf("[%02x] ", tmp[2]);	// prints opcode hex
				do {
					c = rom[++oldscan] & 127;	// get char from opcode list
					switch(c) {
						case '%':				// relative addressing
												// currently does the same as single-byte operands
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
			do {
				cursor++;							// advance by default
			} while (buf[cursor]==' ' || buf[cursor]=='$');	// skip spaces AND RADIX in input
			b = buf[cursor];						// get char
			if (b>='a' && b<='z')		b &= 223;	// all uppercase
}

void getListChar(void) {							// get next valid character in opcode list
			while (rom[scan]==' ')		scan++;		// skip spaces in opcode list, last won't do anyway
			c = rom[scan] & 127;					// filtered from opcode list
			x = rom[scan] & 128;					// terminator
}

void hex2byte(void) {			// convert a pair of hex ciphers into byte (calls hex2nibble)
	int loop;

	value = 0;
	for (loop=0; loop<2; loop++) {			// two hex per byte
		b -= '0';	// convert to number
		if (b>=0 && b<10) {			// already a valid number
			// nothing to do???
		} else {					// check whether alpha
			if (b>='A'-'0' && b<='F'-'0') {		// valid hex cipher
				b -= 'A'-'0'-10;				// add alpha cipher
			} else {
				//***ERROR, not valid cipher***
				cursor--;	// try to reprocess this char
				break;
			}
		}
		// b is 0...15 unless wrong cipher (will not reach this anyway)
		value *= 16;		// older value was MSN
		value += b;			// add LSN
		getNextChar();		// go for next hex
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

void fetchValue(int bytes) {	// advance to the next n bytes, convert into tmp[0...1]
	getNextChar();				// advance to operand
/* symbolic reference */
	if (b=='_') {				// that is a symbolic reference
		scanLabel();			// check label, (x) if match found
		if (x) {						// match found
			if (sym[si&248] & 128) {	// was it pending definition?
				printf("*");
				// add to queue
				si &= 248;			// forget name offset
				si |= 6;				// add offset for pointer
				if (sym[si]) {			// if absolute...
					if (lref<255) {			// limit for the 85th undeclared reference
						tmp[0] = sym[si];		// get offset for first absolute reference
						while(tmp[0]) {			// run thru linked list
							dir = tmp[0]-1;		// keep last element linked
							tmp[0]=ref[dir];	// next item
						}
						ref[dir] = lref+1;				// point tail to new entry
						ref[lref++] = 0;				// this is new end of queue
						ref[lref++] = (ptr+1)&255;		// store LSB
						ref[lref++] = (ptr+1)/256;		// store MSB
						tmp[0] = 0xea;					// placeholder
						tmp[1] = 0xea;
						count  = 2;					// undefined references assumed to be outside zeropage
					} else {
						printf("***NO MORE ABSOLUTE REFERENCES***\n");	// no room for it
						count = 0;								// no bytes fetched
					}
				}
				if (sym[si+1]) {		// if RELATIVE...
					if (lrrf<255) {			// limit for the 85th undeclared reference
						tmp[1] = sym[si+1];		// get offset for first relative reference
						while(tmp[1]) {			// run thru linked list
							dir = tmp[1]-1;		// keep last element linked
							tmp[1]=rrf[dir];	// next item
						}
						rrf[dir] = lrrf+1;				// point tail to new entry
						rrf[lrrf++] = 0;				// this is new end of queue
						rrf[lrrf++] = (ptr+1)&255;		// store LSB
						rrf[lrrf++] = (ptr+1)/256;		// store MSB
						tmp[1] = 0xea;					// placeholder
						count  = 1;					// ???
					} else {
						printf("***NO MORE RELATIVE REFERENCES***\n");	// no room for it
						count = 0;								// no bytes fetched
					}
				}
			} else {					// already defined, just pick up value
				si &= 248;			// forget name offset
				si |= 6;				// add offset for value
				tmp[1] = sym[si++];	// get LSB
				tmp[0] = sym[si++];	// get MSB, will work if bytes=1
				if (tmp[0]) {			// check value size
					count = 2;			// MSB != 0 AND defined means word-sized
				} else {
					count = 1;			// byte-sized otherwise
				}
			}
		} else {			// not found, create new pending reference
			printf("*");
			si = empty;			// THIS is the key... hopefully
			if (si>255) {			// no room?
				printf("***NO MORE LABELS***\n");
				count=0;			// failed attempt
			} else {
				cursor = os-1;		// go back to beginning of name
				getNextChar();
				while (b && ((si&7)<6)) {		// loop until terminator or 6-char limit
					sym[si++] = b|32;			// copy as lowercase
					getNextChar();				// go for next
				}
				if ((si&7)<6) {		// some space remaining
					sym[si]=0;		// terminate if less than 6 chars
				}
				si &= 248;			// forget name offset
				sym[si] |= 128;		// mark as pending
				si |= 6;				// add offset for pointer
				// if absolute...
				sym[si++] = lref+1;		// point to new entry
				sym[si] = 0;				// clear other type?????
				ref[lref++] = 0;			// this is new end of queue
				ref[lref++] = (ptr+1)&255;	// store LSB
				ref[lref++] = (ptr+1)/256;	// store MSB
				undef++;					// undefined entry is made
				tmp[0] = 0xea;				// placeholder
				tmp[1] = 0xea;
				empty += 8;					// yes, another entry!
				// ...RELATIVE to do!
				count  = 2;					// undefined references assumed to be outside zeropage
			}
		}
	} else {						// direct number
/* end of symbolic reference */
		for(i=0;i<bytes;i++) {		// do number of bytes
			hex2byte();				// get whole byte
			tmp[i] = value;			// store converted value
		}
		count = i;					// size as supplied
	}	// *** remove this } if no symbols are to be detected
}

void disassemble(void) {		// disassemble for one opcode
		tmp[2] = ram[dir];	// get opcode
		oldscan = dir;		// before increasing
		printf("%04x: ", dir);	// print initial address
		count = 0;			// skipped strings
		scan = 0;			// opcode list pointer
		while (tmp[2] != count && count<256) {
			while (rom[scan]<128) {
				scan++;		// fetch next terminator
			}
			scan++;			// go to next entry
			count++;		// another opcode skipped
		}
		siz = 1;			// bytes to be dumped
		do {
			x	= rom[scan] & 128;	// bit 7 will exit after processing
			c	= rom[scan] & 127;	// mask bit 7 out
			switch(c) {
				case '%':				// relative addressing
										// currently does the same as single-byte operands
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

void scanLabel(void) {			// looks for a label in symbol table, (x) if found
			getNextChar();		// load it
			os = cursor;	// remember position in order to return
			si = 0;			// initial entry
			x = 0;				// no need to exit
			while(si<empty && !x) {		// read all existing entries
				while(b && ((b|32) == (sym[si]&127)) && ((si&7)<6)) {	// match in lowercase, first 6 chars only
					si++;					// next char in entries
					getNextChar();			// read next in buffer
				}
				if (((!sym[si])&&(!b)) || ((si&7)==6)) {	// full match
					// already referenced, check whether defined
					x = 128;	// special exit value: match found
				} else {
					// no match, go for next entry
					cursor = os-1;		// go back
					getNextChar();			// get first char again
					si &= 248;			// remove inter-entry bits
					si += 8;				// next entry
				}
			}
}
