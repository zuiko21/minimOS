/* Monitor shell for minimOS (simple version) 0.5b1
 * last modified 2016-03-02
 * (c) 2016-2021 Carlos J. Santisteban
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
//	int rom = 0xC000;	// start of emulated ROM
	unsigned char ram[65536];

	FILE* arch;

	unsigned char _A, i, j, c, x, value;	// value after hex2byte (A), b after GetNextChar (A), i loops (X)
//	unsigned char adrm, udfd, sal;
	unsigned char lines;						// number of lines #u to display
	unsigned char areg, xreg, yreg, psr, sp;	// 6502 registers
	char buf[80];								// input buffer
	int ptr, dir, count, tmp[3], scan, os, oldscan, cursor, si;	// several pointers
	int siz;	// temporarily for opcode list loading, later #n

	char undef=0, empty=0;	// *** uncomment if no symbolic assembler is used ***

/* Main programme */
int main(void) {


// start up things
	init();
	printf("minimOS 0.5b1 Monitor shell\n");
	printf("(c)2016 Carlos J. Santisteban\n");
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
		if (_A=='.') {			// pseudo-opcode
			getNextChar();		// get the command itself
			switch(_A) {		// identify command
				case 'A':		// set accumulator as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					areg = _A;	// store byte
					break;
				case 'B':		// store byte $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					ram[ptr++] = _A;		// store byte
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
					sp = _A;	// store byte
					break;
				case 'H':		// show command list
					printf("\nCommand list:\n");
					// ...
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
					psr = _A;	// store byte
					break;
				case 'Q':		// quit or poweroff*
					confUndf();		// check whether something pending
					if (_A) {
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
					lines = _A;	// will show #u lines
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
					xreg = _A;	// store byte
					break;
				case 'Y':		// set Y as $dd
					getNextChar();	// advance to operand
					hex2byte();		// convert to number
					yreg = _A;	// store byte
					break;
				case 'Z':		// poweroff or suspend
					printf("\n---suspend---\n\n");
					break;
				default:
					printf("***Bad command***\n");
			}
			continue;			// command ended, ask for another
		} else printf("***Missing module***\n");	
	} while (-1);

	return 0;
}

/* Function definitions */
void getNextChar(void) {							// get next valid character in input
			do {
				cursor++;							// advance by default
			} while (buf[cursor]==' ' || buf[cursor]=='$');	// skip spaces AND RADIX in input
			_A = buf[cursor];						// get char
			if (_A>='a' && _A<='z')		_A &= 223;	// all uppercase
}


void hex2byte(void) {			// convert a pair of hex ciphers into byte (calls hex2nibble)
	int loop;

	value = 0;
	for (loop=0; loop<2; loop++) {			// two hex per byte
		_A -= '0';	// convert to number
		if (_A>=0 && _A<10) {			// already a valid number
			// nothing to do???
		} else {					// check whether alpha
			if (_A>='A'-'0' && _A<='F'-'0') {		// valid hex cipher
				_A -= 'A'-'0'-10;				// add alpha cipher
			} else {
				//***ERROR, not valid cipher***
				cursor--;	// try to reprocess this char
				break;
			}
		}
		// _A is 0...15 unless wrong cipher (will not reach this anyway)
		value *= 16;		// older value was MSN
		value += _A;			// add LSN
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

		for(i=0;i<bytes;i++) {		// do number of bytes
			hex2byte();				// get whole byte
			tmp[i] = value;			// store converted value
		}
		count = i;					// size as supplied
}


void init(void) {		// initialize variables
	ptr = 0x400;			// set initial address
	siz = 0;				// copy/transfer size
	lines = 4;				// lines to disassemble/display

}

void confUndf(void) {		// check whether there are undefined symbols, (b) if OK by user
		_A = 1;		// OK to proceed
	
}
