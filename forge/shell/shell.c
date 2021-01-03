/* Symbolic (dis)assembler with monitor commands for minimOS
 * last modified 20151221-1443
 * (c) 2015-2021 Carlos J. Santisteban
 * */

#include <stdio.h>

/* Function prototypes */
void getNextChar(void);		// get next valid character in input
void getListChar(void);		// get next valid character in opcode list
void hex2byte(void);		// convert a pair of hex ciphers into byte (calls hex2nibble)
void checkEnd(void);		// check whether there's no more in the input line
void fetchValue(int bytes);	// advance to the next n bytes, convert into tmp[0...1]
void disassemble(void);		// disassemble for one opcode
void opcodePrint(void);		// prints instruction and hexdump
void scanLabel(void);		// looks for a label in symbol table
void init(void);			// initialize variables
void confUndf(void);		// check whether there are undefined symbols, (i) if OK by user

/* Global variables */
	int rom = 0xC000;	// start of emulated ROM
	unsigned char ram[65536];

	FILE* arch;

	unsigned char b, i, j, c, x, adrm, udfd, value, sal;
	unsigned char lines;						// number of lines #u to display
	unsigned char areg, xreg, yreg, psr, sp;	// 6502 registers
	char buf[80];								// input buffer
	int ptr, dir, count, tmp[3], scan, os, oldscan, cursor, si;	// several pointers
	int siz;	// temporarily for opcode list loading, later #n

//char undef=0, empty=0;	// *** uncomment if no symbolic assembler is used ***

/* ***for symbolic assembler only*** */
	unsigned char sym[256];	// symbol table: up to 6 chars, 2 of pointer
								// if bit7 of byte0, non-defined label, byte 6 points to linked list of previous references
								// byte7 might be used in future extensions
								// byte0.bit7 and BOTH of bytes6-7 at 0 means no pending references
	unsigned char ref[256];		// linked list of undefined references
								// [n]=link to next 'n+1', [n+1,n+2] = address of reference
								// [n+3]=FLAGS, 128 for byte-sized, 64 for absolute
								// [n]=0 means End of list
	int empty;					// first empty entry in symbol table (8*used symbols)
	int lref;					// last undefined reference offset
	int undef;					// number of undefined references

/* Main programme */
int main(void) {
// load files
	arch=fopen("opcodes.bin","rb");	// opcode list
	if (arch==NULL) {				// not found?
		printf("\n***Problem opening Opcode List!***\n");
		return -1;					// ABORT
	}
	fseek(arch,0,SEEK_END);			// go to end
	siz=ftell(arch);				// get length
	fseek(arch,0,SEEK_SET);			// back to start
	fread(&(ram[rom]),siz,1,arch);			// read all

// start up things
	init();
	printf("minimOS 0.5b1 Symbolic 65C02 Assembler/Monitor\n");
	printf("(c)2015 Carlos J. Santisteban\n");
	do {							// main loop
		printf("%04x> ", ptr);		// prompt
		fgets(buf, 80, stdin);		// read input line
		scan=0;
		while(buf[scan++]!='\n' && scan<80);	// get terminating newline
		buf[--scan]=0;				// terminate instead
		// might call assembler module from here
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
					if (undef) {		// some pending definition
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
							if (c<' ' || c>'~') {	// non-printable
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
/* ***only if symbolic assembler*** /
					printf("Symbol table:\n");
					i = 0;
					x = 0;							// defined unless otherwise!!!
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
					if (undef) {		// some pending definition
						printf("***UNDEFINED LABELS***\n");
					} else {
						fetchValue(2);			// get next two bytes in tmp[]
						dir = tmp[1] + 256*tmp[0];	// compute address
						printf("[JMP $%04x]\n", dir);
					}
					break;
				case 'K':		// save #n bytes from $aaaa
					fetchValue(2);			// get next two bytes in tmp[]
					dir = tmp[1] + 256*tmp[0];			// compute source address
					oldscan = dir;						// save for later
					for (count=0; count<siz; count++) {	// save #n bytes
						// save byte @dir++...
					}
					printf("---$%04x bytes saved from $%04x---\n", siz, oldscan);	// show results
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
					if (dir<scan) {			// may copy forward
						for (count=0; count<siz; count++) {	// copy #n bytes
							ram[dir++] = ram[scan++];		// copy from current to destination
						}
					} else {
						for (count=siz-1; count>=0; count--) {	// copy #n bytes BACKWARDS
							ram[dir+count] = ram[scan+count];	// copy from current to destination
						}						
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
					confUndf();		// check whether something pending
					if (i) {
						return 0;	// go away!
					}
					break;
				case 'R':		// reboot*
					if (undef) {		// some pending definition
						printf("***UNDEFINED LABELS***\n");
					} else {
						printf("\n---[system restart]---\n");
						init();			// apparent reset
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
				case 'T':
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
/* *** for symbolic assembler only *** /
		if (b=='_') {			// a label is being defined
printf("\nDefining");
			scanLabel();					// looks for a label in symbol table, (sal) if found
			if (sal) {						// match found
printf(" found");
				si &= 248;				// forget name offset
				if (sym[si] & 128) {	// was it pending definition?
printf(" pending");
					sym[si] &= 127;		// no longer undefined
					si |= 6;				// add offset for pointer
					tmp[0] = sym[si];		// get offset for first undefined reference
					sym[si++] = ptr&255;	// store current LSB
//					tmp[1] = sym[si];		// reserved for MSB, should be zero
					sym[si] = ptr/256;	// store current MSB
					// define pending references
					if (tmp[0]) {			// there were absolute references
						undef--;				// EEEEEEEEEEEEEEK!!!!!!!!!
						if (!undef) {			// all defined now?
							lref = 0;			// clear list of undefined absolute references
						}
					}
					while(c=tmp[0]) {				// run thru linked list
printf(" solving");
						dir = ref[c]+256*ref[c+1];	// pointer to undeclared reference
						if (ref[c+2]&64) {			// if absolute...
printf(" absolute");
							ram[dir] = sym[si-1];		// copy LSB
							if (!(ref[c+2]&128)) {		// word-sized reference?
printf(" word");
								ram[dir+1] = sym[si];		// copy MSB too
							}
						} else {					// ...relative
printf(" relative");
							ram[dir] = sym[si-1]+256*sym[si]-dir-1;		// compute relative offset
						}
printf("\n");
						tmp[0]=ref[c-1];			// next item
					}
				} else {					// no redeclaration allowed
					printf("***ALREADY DEFINED***\n");
				}
			} else {						// never referenced before
printf(" never-used");
				if (si<256) {				// room for at least one more
printf("\nNew: '");
					// create entry
					cursor = os-1;			// go back to beginning of name
					getNextChar();
					while((((b&223) >='A' && (b&223) <='Z')||(b>='0' && b<='9')) && ((si&7)<6)) {	// store in lowercase, alphanumeric only, loop until terminator or 6-char limit
						if (b<'A') {	// must be a number
							sym[si++] = b;			// copy it raw
						} else {		// letter otherwise
							sym[si++] = b|32;		// copy as lowercase
						}
printf("%c",sym[si-1]);
						getNextChar();				// go for next
					}
printf("' entry\n");
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
				case '%':		// relative addressing...
					adrm= 128;		// always 8-bit
				case '@':		// ...gets one byte anyway
					if (c=='@')		// absolute short, really?
					{
						adrm = 192;			// 8-bit absolute otherwise
					}
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
					adrm = 64;				// 16-bit is always absolute!
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
						while (ram[rom+scan++]<128);	// seek terminator in opcode list
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
			count++;					// include opcode itself
			for(i=0;i<count;i++) {		// should "poke" tmp[2], tmp[1], tmp[0] at ptr...ptr+2
				ram[ptr+i] = tmp[2-i];		// poke values
			}
			dir = ptr;					// prepare dissasembly
			scan = oldscan;				// back to opcode entry
			oldscan = dir;				// EEEEEEK!!!
			opcodePrint();				// get the whole display
		} else {
			count = 0;					// stay here
			printf("***ERROR***\n");	// invalid string
		}
		if (count) {					// no error was made
			printf("\n");				// finish hex dump
		}
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
			while (ram[rom+scan]==' ')		scan++;		// skip spaces in opcode list, last won't do anyway
			c = ram[rom+scan] & 127;					// filtered from opcode list
			x = ram[rom+scan] & 128;					// terminator
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
	udfd = 0;					// assume defined value, this far
	getNextChar();				// advance to operand
/* symbolic reference /
	if (b=='_') {				// that is a symbolic reference
printf("\nSymbol:");
		scanLabel();			// check label, (x) if match found
		if (sal) {						// match found
printf(" found");
			si &= 248;					// forget name offset
			if (sym[si] & 128) {		// was it pending definition?
printf(" pending");
				udfd = 1;				// notify as such
				// add to queue
				si |= 6;				// add offset for pointer
				tmp[0] = sym[si];		// get offset for first undefined reference
				while(tmp[0]) {			// run thru linked list
printf(".");
					dir = tmp[0]	;	// keep last element linked
					tmp[0]=ref[dir-1];	// next item
				}
				if (lref<256) {			// room for one more reference
printf(" one-more\n");
					ref[dir-1] = lref+1;			// point tail to new entry
					ref[lref++] = 0;				// this is new end of queue
					ref[lref++] = (ptr+1)&255;		// store LSB
					ref[lref++] = (ptr+1)/256;		// store MSB
					ref[lref++] = adrm;				// store flags!
					tmp[0] = 0xea;					// placeholder
					tmp[1] = 0xea;
					count  = 2;					// undefined references assumed to be outside zeropage
				} else {
					printf("***NO MORE REFERENCES***\n");	// no room for it
					count = 0;								// no bytes fetched
				}
			} else {					// already defined, just pick up value
printf(" defined");
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
printf(" unknown");
			udfd = 1;			// notify as pending
			si = empty;			// THIS is the key... hopefully
			if (si>255) {			// no room?
				printf("***NO MORE LABELS***\n");
				count=0;			// failed attempt
			} else {
printf("\nCreating '");
				cursor = os-1;		// go back to beginning of name
				getNextChar();
				while((((b&223) >='A' && (b&223) <='Z')||(b>='0' && b<='9')) && ((si&7)<6)) {	// store in lowercase, alphanumeric only, loop until terminator or 6-char limit
					sym[si++] = b|32;			// copy as lowercase, OK with numbers
printf("%c",sym[si-1]);
					getNextChar();				// go for next
				}
				if ((si&7)<6) {		// some space remaining
					sym[si]=0;		// terminate if less than 6 chars
				}
				si &= 248;			// forget name offset
				sym[si] |= 128;		// mark as pending
				si |= 6;			// add offset for pointer
				sym[si++] = lref+1;			// point to new entry
				sym[si] = 0;				// clear reserved byte
				ref[lref++] = 0;			// this is new end of queue
				ref[lref++] = (ptr+1)&255;	// store LSB
				ref[lref++] = (ptr+1)/256;	// store MSB
				ref[lref++] = adrm;			// store flags!
				undef++;					// undefined entry is made
				tmp[0] = 0xea;				// placeholder
				tmp[1] = 0xea;
				empty += 8;					// yes, another entry!
				count  = 2;					// undefined references assumed to be outside zeropage
printf("'\n");
			}
		}
	} else {						// direct number
/* end of symbolic reference */
		for(i=0;i<bytes;i++) {		// do number of bytes
			hex2byte();				// get whole byte
			tmp[i] = value;			// store converted value
		}
		count = i;					// size as supplied
	//}	// *** remove this } if no symbols are to be detected
}

void disassemble(void) {		// disassemble for one opcode
		tmp[2] = ram[dir];	// get opcode
		oldscan = dir;		// before increasing
		count = 0;			// skipped strings
		scan = 0;			// opcode list pointer
		while (tmp[2] != count && count<256) {
			while (ram[rom+scan]<128) {
				scan++;		// fetch next terminator
			}
			scan++;			// go to next entry
			count++;		// another opcode skipped
		}
		udfd = 0;			// these will be fully defined
		opcodePrint();		// go for the text output
}

void opcodePrint(void) {		// prints instruction and hexdump
// needs proper value for scan, oldscan
		printf("_%04x: ", dir);		// address as label for most assemblers
		siz = 1;			// bytes to be dumped
		count = 0;			// now printed chars!
		do {
			x	= ram[rom+scan] & 128;	// bit 7 will exit after processing
			c	= ram[rom+scan] & 127;	// mask bit 7 out
			switch(c) {
				case '%':				// relative addressing
										// currently does the same as single-byte operands
										// might resolve as absolute destination address!!
				case '@':				// single byte operand
					if (udfd) {			// pending definition
						printf("**");
						count += 2;		// two chars were printed
					} else {			// otherwise it has the actual value
						printf("$%02x", ram[++dir]);	// print operand in hex
						count += 3;		// 3 more chars
					}
					siz = 2;			// 2-byte opcode
					break;
				case '&':				// word operand
					if (udfd) {			// pending definition
						printf("****");
						count += 4;		// 4 chars were printed
					} else {			// otherwise it has the actual value
						printf("$%02x%02x", ram[++dir], ram[++dir]);	// print address in hex
						count += 5;		// 5 more chars
					}
					siz = 3;			// 3-byte opcode
					break;
				default:				// generic character
					printf("%c", c);	// print it
					count++;			// single char
			}							// end of switch
			scan++;						// next character!
		} while (!x);				// until terminator
		dir++;							// next opcode!
		while (count<16) {				// tabulate!
			printf(" ");
			count++;
		}
		printf("; ");					// start tabulated dump
		for (count=0; count<siz; count++) {				// count ends as siz
			printf("%02x ", ram[oldscan+count]);		// dump byte
		}
		printf("\n");
}
/*
void scanLabel(void) {			// looks for a label in symbol table, (x) if found
			getNextChar();		// load it
			os = cursor;		// remember position in order to return
			si = 0;				// initial entry
			sal = 0;			// no need to exit
printf("[Label: ");
			while(si<empty && !sal) {		// read all existing entries
				while((((b&223) >='A' && (b&223) <='Z')||(b>='0' && b<='9'))  && ((b|32) == (sym[si]&127)) && ((si&7)<6)) {	// match in lowercase, first 6 chars only, alphanumeric only
printf("%c",b);
					si++;					// next char in entries
					getNextChar();			// read next in buffer
				}
				if (((sym[si]<'0' || sym[si]>'z' || (sym[si]>'9' && sym[si]<'a'))&&(!b)) || ((si&7)==6)) {	// full match
					// already referenced, check whether defined
					sal = 128;			// special exit value: match found
printf("=>full-match");
				} else {
					// no match, go for next entry
					cursor = os-1;		// go back
					getNextChar();			// get first char again
					si &= 248;			// remove inter-entry bits
					si += 8;				// next entry
printf(", ");
				}
			}
printf("]\n");
}
*/
void init(void) {		// initialize variables
	ptr = 0x400;			// set initial address
	siz = 0;				// copy/transfer size
	lines = 4;				// lines to disassemble/display

/* in case symbolic assembler is used /
	empty = 0;				// first empty entry in symbol table (8*used symbols)
	lref  = 0;				// last undefined reference offset
	undef = 0;				// number of undefined references
	
// initialize symbol table, if available
	for(scan=0;scan<256;scan+=8) {	// one entry each 8 bytes
		sym[scan]=0;				// terminate string
		sym[scan+6]=0;				// reset link and pointer
		sym[scan+7]=0;
	}
	for (scan=0;scan<256;scan+=4) {	// clear reference list, just the next-field?
		ref[scan]=0;
	}	
/* end of symbolic variables */
}

void confUndf(void) {		// check whether there are undefined symbols, (i) if OK by user
	if (undef) {		// some pending definition
		printf("***UNDEFINED LABELS*** Proceed (y/n)? ");
		scanf(" %c", &c);
		if ((c=='y' || c=='Y'))		i=1;	// user confirmed
		else						i=0;	// abort
	} else
	{
		i = 1;		// OK to proceed
	}
	
}
