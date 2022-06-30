/* Perdita 65C02 Durango-S emulator!
 * (c)2007-2022 Carlos J. Santisteban
 * last modified 20220630-1254
 * */

#include <stdio.h>

/* type definitions */
	typedef u_int8_t byte;
	typedef u_int16_t word;

/* global variables */
	byte mem[65536]			// unified memory map

	byte a, x, y, s, p;		// 8-bit registers
	word pc;				// program counter
	int run, ver;			// emulator control
	long cont = 0;			// total elapsed cycles

	const char flag[8]="NV·BDIZC";	// flag names

/* function prototypes */
	void stat(byte psr);	// display processor status
	byte peek(word dir);			// read memory or I/O
	void poke(word dir, byte v);	// write memory or I/O

	void push(byte b);		{ poke(0x100 + s--, b); }		// standard stack ops
	byte pop(void);			{ return peek(++s + 0x100); }

	void intack(void);		// save status for interrupt acknowledge
	void reset(void);		// RESET & hardware interrupts
	void nmi(void);
	void irq(void);

	void rel(byte off);		// relative branches
	void bits_nz(byte b);	// set N&Z flags

	void asl(byte *d);		// shift left
	void lsr(byte *d);		// shift right
	void rol(byte *d);		// rotate left
	void ror(byte *d);		// rotate right

	void adc(byte d);		// add with carry
	void sbc(byte d);
	void cmp(byte d);		// compare

	int exec(void);			// execute one opcode, returning number of cycles
	void load(cost char name[], word adr);					// load firmware

	word am_a(void)			{ return  peek(pc) | (peek(pc+1) <<8);      pc+=2; }
	word am_ax(void)		{ return (peek(pc) | (peek(pc+1) <<8)) + x; pc+=2; }		// add penalty unless STore
	word am_ay(void)		{ return (peek(pc) | (peek(pc+1) <<8)) + y; pc+=2; }		// add penalty unless STore
	byte am_zx(void)		{ return (peek(pc++) + x) & 255; }
	byte am_zy(void)		{ return (peek(pc++) + y) & 255; }
	word am_ix(void)		{ return (peek(peek(pc)+x)|(peek(peek(pc)+x+1)<<8));     pc++; }	// wrap?***plus penalty unless STore?
	word am_iy(void)		{ return (peek(peek(pc))  |(peek(peek(pc)+1)  <<8)) + y; pc++; }	// plus penalty unless STore
	word am_iz(void)		{ return  peek(peek(pc))  |(peek(peek(pc)+1)  <<8) ;     pc++; }
	word am_ai(void)		{ word j=am_a(); return peek(j)  |(peek(j+1)  <<8) ; }		// not broken
	word am_aix(void)		{ word j=am_a(); return peek(j+x)|(peek(j+x+1)<<8) ; }

/* ******************* startup ******************* */
int main (int argc, char * const argv[]) {
	int cyc=0, t=0;			// instruction and interrupt cycle counter

	run = 1;				// allow execution
	ver = 0;				// verbosity mode, 0 = none, 1 = jumps, 2 = auto?, 3 = all 

	load("rom.bin", 0x8000);		// preload 32K firmware at ROM area

	reset();				// startup!

	while (run) {
		cyc = exec();		// count elapsed clock cycles for this instruction
		cont += cyc;		// add last instruction cycle count
		t += cyc;			// advance interrupt counter
		if (t >= 6144)		// 250 Hz interrupt @ 1.536 MHz
		{
			t -= 6144;		// restore for next
// *** maybe get keypresses from SDL here
			if (mem[0xDFA0] & 1) {
				irq();		// if hardware interrupts are enabled, send signal to CPU
			}
		}
/*		if (irq_flag) {		// 'spurious' cartridge interrupt emulation!
 			irq();
 		}
*/
		if (nmi_flag) {		// *** get somewhere from SDL
			nmi();			// NMI gets executed always
		}
		if (stat_flag) {	// *** get from SDL
			stat(p);
		}
	}

	printf(" *** CPU halted after %d clock cycles ***\n", cont);
	stat(p);				// display end status

	return 0;
}

/* **************************** */
/* support function definitions */
/* **************************** */

/* display any value as CPU status */
void stat(byte psr)	{ 
	int i;

	printf("<PC=%04X, A=%02X, X=%02X, Y=%02X, S=%02X>\n<PSR: ", pc-1, a, x, y, s);
	for (i=0; i<8; i++) {
		if (psr&128)	printf("%c", flags[i]);
		else			printf("·");
		psr<=1;				// next flag
	}
	printf(">\n");
}

/* load firmware, usually into ROM area */
void load(cost char name[], word adr) {
	FILE *f;
	int c, b = 0;
	
	f = fopen(name, "rb");
	if(f != NULL) {
		do {
			c = fgetc(f);
			mem[adr+(b++)] = c;	// load one byte
		} while( c != EOF);

		fclose(f);
		printf("%s: %d bytes loaded at %04X\n", name, b, adr);
	}
	else {
		printf("*** Could not load ROM ***\n");
		run = 0;
	}
}

/* read from memory or I/O */
byte peek(word dir) {
	byte d = 0xFF;				// supposed floating databus value?

	if (dir>=0xDF80 && dir<=0xDFFF) {	// I/O
		if (dir<=0xDF87)		// video mode (readable)
			d = mem[0xDF80];
		else if (dir<=0xDF8F)	// sync flags
			d = mem[0xDF88];
		else if (dir<=0xDF9F)	// expansion port
			d = mem[dir];		// *** is this OK?
// interrupt control and beeper are NOT readable
		else if (dir>=0xDFC0)	// cartridge I/O
			d = mem[dir];		// *** is this OK?
	} else {
		d = mem[dir];			// default memory read, either RAM or ROM
	}

	return d;
}

/* write to memory or I/O */
void poke(long dir, int v) {
	if (dir>=0 && dir<32768)			// 32 KiB static RAM
		mem[dir] = v;

	if (dir>=0xDF80 && dir<=0xDFFF) {	// I/O
		if (dir<=0xDF87)				// video mode?
			mem[0xDF80] = v;			// canonical address
		else if (dir<=0xDF8F)			// sync flags?
			;							// *** not writable
		else if (dir<=0xDF9F)			// expansion port?
			mem[dir] = v;				// *** is this OK?
		else if (dir<=0xDFAF)			// interrupt control?
			mem[0xDFA0] = v;			// canonical address, only D0 matters
		else if (dir<=0xDFBF)			// beeper?
			mem[0xDFB0] = v;			// canonical address, only D0 matters *** anything else?
		else
			mem[dir] = v;				// otherwise is cartridge I/O *** anything else?
	}									// any other address is ROM, thus no much sense writing there?
}

/* acknowledge interrupt and save status */
void intack(void) {
	push(pc >> 8);							// stack standard status
	push(pc & 255);
	push(p);

	p |= 0b00000100;						// set interrupt mask

	cont += 7;								// interrupt acknowledge time
}

/* reset CPU, like !RES signal */
void reset(void) {
	pc = peek(0xFFFC) | peek(0xFFFD)<<8;	// RESET vector

	printf(" RESET: PC=>%04X\n", pc);

	p &= 0b11110011;						// CLD & SEI on 65C02
	p |= 0b00110000;						// these always 1

	cont = 0;								// reset global cycle counter?
}

/* emulate !NMI signal */
void nmi(void) {
	intack();								// acknowledge and save

	pc = peek(0xFFFA) | peek(0xFFFB)<<8;	// NMI vector
	if (ver)	printf(" NMI: PC=>%04X\n", pc);
}

/* emulate !IRQ signal */
void irq(void) {
	if (!(p & 4)) {								// if not masked...
		intack();								// acknowledge and save

		pc = peek(0xFFFE) | peek(0xFFFF)<<8;	// IRQ/BRK vector
		if (ver)	printf(" IRQ: PC=>%04X\n", pc);
	}
}

/* relative branch */
void rel(byte off) {//***may supress parameter
	pc += off;
	pc -= (off & 128)?256:0;				// check negative displacement
}

/* compute usual N & Z flags from value */
void bits_nz(byte b) {
	p &= 0b01111101			// pre-clear N & Z
	p |= (b & 128)			// set N as bit 7
	p |= (b==0)?2:0			// set Z accordingly
}

/* ASL, shift left */
void asl(byte *d)
{
	p &= 0b11111110;		// clear C
	p |= ((*d) & 128) >> 7;	// will take previous bit 7
	(*d) <<= 1;				// EEEEEEEEK
	bits_nz(*d);
}

/* LSR, shift right */
void lsr(byte *d)
{
	p &= 0b11111110;		// clear C
	p |= (*d) & 1;			// will take previous bit 0
	(*d) >>= 1;				// eeeek
	bits_nz(*d);
}

/* ROL, rotate left */
void rol(byte *d)
{
	byte temp = (p & 1);	// keep previous C

	p &= 0b11111110;		// clear C
	p |= ((*d) & 128) >> 7;	// will take previous bit 7
	(*d) <<= 1;				// eeeeeek
	(*d) |= temp;			// rotate C
	bits_nz(*d);
}

/* ROR, rotate right */
void ror(byte *d)
{
	byte temp = (p & 1)<<7;	// keep previous C (shifted)

	p &= 0b11111110;		// clear C
	p |= (*d) & 1;			// will take previous bit 0
	(*d) >>= 1;				// eeeek
	(*d) |= temp;			// rotate C
	bits_nz(*d);
}

void adc(byte d)	// ¿¿¿ OVERFLOW, aquí ???***
{

	a += d;
	if (p & 0x01)	a++;
	if (a >= 256)
	{
		a -= 256;
		p |= 0x01;
	}
	else	p &= 0xFE;
	bits_nz(a);
}	

void sbc(byte d)
{
	a -= d;
	if (p & 0x01)	a--;
	if (a < 0)
	{
		a += 256;
		p |= 0x01;
	}
	else	p &= 0xFE;
	bits_nz(a);
}

void cmp(byte d)
{
	bits_nz(d);
	if (d < 0)
		p |= 0x01;
	else
		p &= 0xFE;
}

int exec(void)
{
	int per = 2;			// base cycle count
	byte opcode;
	word adr;

	opcode = peek(pc++);	// get opcode and point to next one (or operand)
	switch(opcode)
	{
		case 0x69:						// *** ADC: Add Memory to Accumulator with Carry ***
			adc(peek(pc++));
			if (ver > 1) printf("[ADC#]");
			break;
		case 0x6D:
			adc(peek(am_a()));
			if (ver > 1) printf("[ADCa]");
			per = 4;
			break;
		case 0x65:
			adc(peek(peek(pc++)));
			if (ver > 1) printf("[ADCz]");
			per = 3;
			break;
		case 0x61:
			adc(peek(am_ix()));
			if (ver > 1) printf("[ADC(x)]");
			per = 6;
			break;
		case 0x71:
			adc(peek(am_iy()));
			if (ver > 1) printf("[ADC(y)]");
			per = 5;
			break;
		case 0x75:
			adc(peek(am_zx()));
			if (ver > 1) printf("[ADCzx]");
			per = 4;
			break;
		case 0x7D:
			adc(peek(am_ax()));
			if (ver > 1) printf("[ADCx]");
			per = 4;
			break;
		case 0x79:
			adc(peek(am_ay()));
			if (ver > 1) printf("[ADCy]");
			per = 4;
			break;
		case 0x72:			// CMOS only
			adc(peek(am_iz()));
			if (ver > 1) printf("[ADC(z)]");
			per = 5;
			break;
		case 0x29:						// *** AND: "And" Memory with Accumulator ***
			a &= peek(pc++);
			bits_nz(a);
			if (ver > 1) printf("[AND#]");
			break;
		case 0x2D:
			a &= peek(am_a());
			bits_nz(a);
			if (ver > 1) printf("[ANDa]");
			per = 4;
			break;
		case 0x25:
			a &= peek(peek(pc++));
			bits_nz(a);
			if (ver > 1) printf("[ANDz]");
			per = 3;
			break;
		case 0x21:
			a &= peek(am_ix());
			bits_nz(a);
			if (ver > 1) printf("[AND(x)]");
			per = 6;
			break;
		case 0x31:
			a &= peek(am_iy());
			bits_nz(a);
			if (ver > 1) printf("[AND(y)]");
			per = 5;
			break;
		case 0x35:
			a &= peek(am_zx());
			bits_nz(a);
			if (ver > 1) printf("[ANDzx]");
			per = 4;
			break;
		case 0x3D:
			a &= peek(am_ax());
			bits_nz(a);
			if (ver > 1) printf("[ANDx]");
			per = 4;
			break;
		case 0x39:
			a &= peek(am_ay());
			bits_nz(a);
			if (ver > 1) printf("[ANDy]");
			per = 4;
			break;
		case 0x32:	// CMOS only
			a &= peek(am_iz());
			bits_nz(a);
			if (ver > 1) printf("[AND(z)]");
			per = 5;
			break;
		case 0x0E:						// *** ASL: Shift Left one Bit (Memory or Accumulator) ***
			adr = am_a();
			temp = peek(adr);
			asl(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[ASLa]");
			per = 6;
			break;
		case 0x06:
			temp = peek(peek(pc));
			asl(&temp);
			poke(peek(pc++), temp);
			if (ver > 1) printf("[ASLz]");
			per = 5;
			break;
		case 0x0A:
			asl(&a);
			if (ver > 1) printf("[ASL]");
			break;
		case 0x16:
			adr = am_zx();
			temp = peek(adr);
			asl(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[ASLzx]");
			per = 6;
			break;
		case 0x1E:
			adr = am_ax();
			temp = peek(adr);
			asl(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[ASLx]");
			per = 6;		// 7 for NMOS
			break;
		case 0x90:						// *** BCC: Branch on Carry Clear ***
			if(!(p & 0x01))
			{
				rel(peek(pc));//********maybe without parameter
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BCC]");
			break;
		case 0xB0:						// *** BCS: Branch on Carry Set ***
			if(p & 0x01)
			{
				rel(peek(pc));
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BCS]");
			break;
		case 0xF0:						// *** BEQ: Branch on Result Zero ***
			if(p & 0x02)
			{
				rel(peek(pc));
				per = 3;
			}				
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BEQ]");
			break;
		case 0x2C:						// *** BIT: Test Bits in Memory with Accumulator ***
			temp = peek(am_a());
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 1) printf("[BITa]");
			per = 4;
			break;
		case 0x24:
			temp = peek(peek(pc++));
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 1) printf("[BITz]");
			per = 3;
			break;
		case 0x89:			// CMOS only
			temp = peek(pc++);
			p &= 0b11111101;			// pre-clear Z only
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 1) printf("[BIT#]");
			break;
		case 0x3C:			// CMOS only
			temp = peek(am_ax());
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 1) printf("[BITx]");
			per = 4;
			break;
		case 0x34:			// CMOS only
			temp = peek(am_zx());
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 1) printf("[BITzx]");
			per = 4;
			break;
		case 0x30:						// *** BMI: Branch on Result Minus ***
			pc++;
			if(p & 0x80)
			{
				rel(peek(pc));
				per = 3;
			}		
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BMI]");
			break;
		case 0xD0:						// *** BNE: Branch on Result Not Zero ***
			pc++;
			if(!(p & 0x02))
			{
				rel(peek(pc));
				per = 3;
			}				
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BNE]");
			break;
		case 0x10:						// *** BPL: Branch on Result Plus ***
			pc++;
			if(!(p & 0x80))
			{
				rel(peek(pc));
				per = 3;
			}			
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BPL]");
			break;
		case 0x80:						// CMOS only: *** BRA ***
			pc++;
			rel(peek(pc));
			per = 3;
			if (ver > 1) printf("[BRA]");
			break;
		case 0x00:						// *** BRK: Force Break ***
			printf("[BRK]");
// **** TBD ****
			run = 0;
			per = 7;
			break;
		case 0x50:						// *** BVC: Branch on Overflow Clear ***
			pc++;
			if(!(p & 0x40))
			{
				rel(peek(pc));
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BVC]");
			break;
		case 0x70:						// *** BVC: Branch on Overflow Set ***
			pc++;
			if(p & 0x40)
			{
				rel(peek(pc));
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BVS]");
			break;
		case 0x18:						// *** CLC: Clear Carry Flag ***
			p &= 0b11111110;
			if (ver > 1) printf("[CLC]");
			break;
		case 0xD8:						// *** CLD: Clear Decimal Mode ***
			p &= 0b11110111;
			if (ver > 1) printf("[CLD]");
			break;
		case 0x58:						// *** CLI: Clear Interrupt Disable Bit ***
			p &= 0b11111011;
			if (ver > 1) printf("[CLI]");
			break;
		case 0xB8:						// *** CLV: Clear Overflow Flag ***
			p &= 0b10111111;
			if (ver > 1) printf("[CLV]");
			break;
		case 0xC9:						// *** CMP: Compare Memory And Accumulator ***		¿¿¿ o al revés ???
			cmp(a - peek(pc));//****************
			if (ver > 1) printf("[CMP#]");
			pc++;
			break;
		case 0xCD:
			temp = peek(am_a());
			cmp(a - temp);
			if (ver > 1) printf("[CMPa]");
			per = 4;
			break;
		case 0xC5:
			temp = peek(peek(pc++));
			cmp(a - temp);
			if (ver > 1) printf("[CMPz]");
			per = 3;
			break;
		case 0xC1:
			temp = peek(am_ix());
			cmp(a - temp);
			if (ver > 1) printf("[CMP(x)]");
			per = 6;
			break;
		case 0xD1:
			temp = peek(am_iy());
			cmp(a - temp);
			if (ver > 1) printf("[CMP(y)]");
			per = 5;
			break;
		case 0xD5:
			temp = peek(am_zx());
			cmp(a - temp);
			if (ver > 1) printf("[CMPzx]");
			per = 4;
			break;
		case 0xDD:
			temp = peek(am_ax());
			cmp(a - temp);
			if (ver > 1) printf("[CMPx]");
			per = 4;
			break;
		case 0xD9:
			temp = peek(am_ay());
			cmp(a - temp);
			if (ver > 1) printf("[CMPy]");
			per = 4;
			break;
		case 0xD2:			// CMOS only
			temp = peek(am_iz());
			cmp(a - temp);
			if (ver > 1) printf("[CMP(z)]");
			per = 5;
			break;
		case 0xE0:						// *** CPX: Compare Memory And Index X ***
			cmp(x - peek(pc++));
			if (ver > 1) printf("[CPX#]");
			break;
		case 0xEC:
			temp = peek(am_a());
			cmp(x - temp);
			if (ver > 1) printf("[CPXa]");
			per = 4;
			break;
		case 0xE4:
			temp = peek(peek(pc++));
			cmp(x - temp);
			if (ver > 1) printf("[CPXz]");
			per = 3;
			break;
		case 0xC0:						// *** CPY: Compare Memory And Index Y ***
			cmp(y - peek(pc++));
			if (ver > 1) printf("[CPY#]");
			break;
		case 0xCC:
			temp = peek(am_a());
			cmp(y - temp);
			if (ver > 1) printf("[CPYa]");
			per = 4;
			break;
		case 0xC4:
			temp = peek(peek(pc++));
			cmp(y - temp);
			if (ver > 1) printf("[CPYz]");
			per = 3;
			break;
		case 0xCE:						// *** DEC: Decrement Memory (or Accumulator) by One ***
			temp = peek(am_a());//***********
			temp--;
			if (temp == -1)
				temp = 255;
			poke(am_a(), temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECa]");
			pc += 2;
			per = 6;
			break;
		case 0xC6:
			temp = peek(peek(pc));
			temp--;
			if (temp == -1)
				temp = 255;
			poke(peek(pc), temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECz]");
			pc++;
			per = 5;
			break;
		case 0xD6:
			temp = peek(am_zx());
			temp--;
			if (temp == -1)
				temp = 255;
			poke(am_zx(), temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECzx]");
			pc += 2;
			per = 6;
			break;
		case 0xDE:
			temp = peek(am_ax());
			temp--;
			if (temp == -1)
				temp = 255;
			poke(am_ax(), temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECx]");
			pc += 2;
			per = 6;	// 7 for NMOS
			break;
		case 0x3A:	// CMOS only
			a--;
			if (a == -1)
				a = 255;
			bits_nz(a);
			if (ver > 1) printf("[DEC]");
			break;
		case 0xCA:						// *** DEX: Decrement Index X by One ***
			x--;
			if (x == -1)
				x = 255;
			bits_nz(x);
			if (ver > 1) printf("[DEX]");
			break;
		case 0x88:						// *** DEY: Decrement Index Y by One ***
			y--;
			if (y == -1)
				y = 255;
			bits_nz(y);
			if (ver > 1) printf("[DEY]");
			break;
		case 0x49:						// *** EOR: "Exclusive Or" Memory with Accumulator ***
			a ^= peek(pc++);
			bits_nz(a);
			if (ver > 1) printf("[EOR#]");
			break;
		case 0x4D:
			a ^= peek(am_a());
			bits_nz(a);
			if (ver > 1) printf("[EORa]");
			per = 4;
			break;
		case 0x45:
			a ^= peek(peek(pc++));
			bits_nz(a);
			if (ver > 1) printf("[EORz]");
			per = 3;
			break;
		case 0x41:
			a ^= peek(am_ix());
			bits_nz(a);
			if (ver > 1) printf("[EOR(x)]");
			per = 6;
			break;
		case 0x51:
			a ^= peek(am_iy());
			bits_nz(a);
			if (ver > 1) printf("[EOR(y)]");
			per = 5;
			break;
		case 0x55:
			a ^= peek(am_zx());
			bits_nz(a);
			if (ver > 1) printf("[EORzx]");
			per = 4;
			break;
		case 0x5D:
			a ^= peek(am_ax());
			bits_nz(a);
			if (ver > 1) printf("[EORx]");
			per = 4;
			break;
		case 0x59:
			a ^= peek(am_ay());
			bits_nz(a);
			if (ver > 1) printf("[EORy]");
			per = 4;
			break;
		case 0x52:			// CMOS only
			a ^= peek(am_iz());
			bits_nz(a);
			if (ver > 1) printf("[EOR(z)]");
			per = 5;
			break;
		case 0xEE:						// *** INC: Increment Memory (or Accumulator) by One ***
			temp = peek(am_a());//*****************
			temp++;
			if (temp == 256)
				temp = 0;
			poke(am_a(), temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCa]");
			per = 6;
			break;
		case 0xE6:
			temp = peek(peek(pc));
			temp++;
			if (temp == 256)
				temp = 0;
			poke(peek(pc++), temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCz]");
			per = 5;
			break;
		case 0xF6:
			temp = peek(am_zx());
			temp++;
			if (temp == 256)
				temp = 0;
			poke(am_zx(), temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCzx]");
			per = 6;
			break;
		case 0xFE:
			temp = peek(am_ax());
			temp++;
			if (temp == 256)
				temp = 0;
			poke(am_ax(), temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCx]");
			per = 6;	// 7 for NMOS
			break;
		case 0x1A:	// CMOS only
			a++;
			if (a == 256)
				a = 0;
			bits_nz(a);
			if (ver > 1) printf("[INC]");
			break;
		case 0xE8:						// *** INX: Increment Index X by One ***
			x++;
			if (x == 256)
				x = 0;
			bits_nz(x);
			if (ver > 1) printf("[INX]");
			break;
		case 0xC8:						// *** INY: Increment Index Y by One ***
			y++;
			if (y == 256)
				y = 0;
			bits_nz(y);
			if (ver > 1) printf("[INY]");
			break;
		case 0x4C:						// *** JMP: Jump to New Location ***
			pc = am_a();
			if (ver)	printf("[JMP]");
			per = 3;
			break;
		case 0x6C:
			pc = am_ai();
			if (ver)	printf("[JMP()]");
			per = 6;		// 5 for NMOS!
			break;
		case 0x7C:			// CMOS only
			pc = am_aix();
			if (ver)	printf("[JMP(x)]");
			per = 6;
			break;
		case 0x20:						// *** JSR: Jump to New Location Saving Return Address ***
			push((pc+1)>>8);			// stack one byte before return address, right at MSB
			push((pc+1)&255);
			pc = am_a();				// determine operand
			if (ver)	printf("[JSR]");
			per = 6;
			break;
		case 0xA9:						// *** LDA: Load Accumulator with Memory ***
			a = peek(pc++);
			bits_nz(a);
			if (ver > 1) printf("[LDA#]");
			break;
		case 0xAD:
			a = peek(am_a());
			bits_nz(a);
			if (ver > 1) printf("[LDAa]");
			per = 4;
			break;
		case 0xA5:
			a = peek(peek(pc++));
			bits_nz(a);
			if (ver > 1) printf("[LDAz]");
			per = 3;
			break;
		case 0xA1:
			a = peek(am_ix());
			bits_nz(a);
			if (ver > 1) printf("[LDA(x)]");
			per = 6;
			break;
		case 0xB1:
			a = peek(am_iy());
			bits_nz(a);
			if (ver > 1) printf("[LDA(y)]");
			per = 5;
			break;
		case 0xB5:
			a = peek(am_zx());
			bits_nz(a);
			if (ver > 1) printf("[LDAzx]");
			per = 4;
			break;
		case 0xBD:
			a = peek(am_ax());
			bits_nz(a);
			if (ver > 1) printf("[LDAx]");
			per = 4;
			break;
		case 0xB9:
			a = peek(am_ay());
			bits_nz(a);
			if (ver > 1) printf("[LDAy]");
			per = 4;
			break;
		case 0xB2:	// CMOS only
			a = peek(am_iz());
			bits_nz(a);
			if (ver > 1) printf("[LDA(z)]");
			per = 5;
			break;
		case 0xA2:						// *** LDX: Load Index X with Memory ***
			x = peek(pc++);
			bits_nz(x);
			if (ver > 1) printf("[LDX#]");
			break;
		case 0xAE:
			x = peek(am_a());
			bits_nz(x);
			if (ver > 1) printf("[LDXa]");
			per = 4;
			break;
		case 0xA6:
			x = peek(peek(pc++));
			bits_nz(x);
			if (ver > 1) printf("[LDXz]");
			per = 3;
			break;
		case 0xB6:
			x = peek(am_zy());
			bits_nz(x);
			if (ver > 1) printf("[LDXzy]");
			per = 4;
			break;
		case 0xBE:
			x = peek(am_ay());
			bits_nz(x);
			if (ver > 1) printf("[LDXy]");
			per = 4;
			break;
		case 0xA0:						// *** LDY: Load Index Y with Memory ***
			y = peek(pc++);
			bits_nz(y);
			if (ver > 1) printf("[LDY#]");
			break;
		case 0xAC:
			y = peek(am_a());
			bits_nz(y);
			if (ver > 1) printf("[LDYa]");
			per = 4;
			break;
		case 0xA4:
			y = peek(peek(pc++));
			bits_nz(y);
			if (ver > 1) printf("[LDYz]");
			per = 3;
			break;
		case 0xB4:
			y = peek(am_zx());
			bits_nz(y);
			if (ver > 1) printf("[LDYzx]");
			per = 4;
			break;
		case 0xBC:
			y = peek(am_ax());
			bits_nz(y);
			if (ver > 1) printf("[LDYx]");
			per = 4;
			break;
		case 0x4E:						// *** LSR: Shift One Bit Right (Memory or Accumulator) ***
			adr=am_a();
			temp = peek(adr);
			lsr(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[LSRa]");
			per = 6;
			break;
		case 0x46:
			temp = peek(peek(pc));
			lsr(&temp);
			poke(peek(pc++), temp);
			if (ver > 1) printf("[LSRz]");
			per = 5;
			break;
		case 0x4A:
			lsr(&a);
			printf("[LSR]");
			break;
		case 0x56:
			adr = am_zx();
			temp = peek(adr);
			lsr(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[LSRzx]");
			per = 6;
			break;
		case 0x5E:
			adr = am_ax();
			temp = peek(adr);
			lsr(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[LSRx]");
			per = 6;		// 7 for NMOS
			break;
		case 0xEA:						// *** NOP: No Operation ***
			if (ver > 1) printf("[NOP]");
			break;
		case 0x09:						// *** ORA: "Or" Memory with Accumulator ***
			a |= peek(pc++);
			bits_nz(a);
			if (ver > 1) printf("[ORA#]");
			break;
		case 0x0D:
			a |= peek(am_a());
			bits_nz(a);
			if (ver > 1) printf("[ORAa]");
			per = 4;
			break;
		case 0x05:
			a |= peek(peek(pc++));
			bits_nz(a);
			if (ver > 1) printf("[ORAz]");
			per = 3;
			break;
		case 0x01:
			a |= peek(am_ix());
			bits_nz(a);
			if (ver > 1) printf("[ORA(x)]");
			per = 6;
			break;
		case 0x11:
			a |= peek(am_iy());
			bits_nz(a);
			if (ver > 1) printf("[ORA(y)]");
			per = 5;
			break;
		case 0x15:
			a |= peek(am_zx());
			bits_nz(a);
			if (ver > 1) printf("[ORAzx]");
			per = 4;
			break;
		case 0x1D:
			a |= peek(am_ax());
			bits_nz(a);
			if (ver > 1) printf("[ORAx]");
			per = 4;
			break;
		case 0x19:
			a |= peek(am_ay());
			bits_nz(a);
			if (ver > 1) printf("[ORAy]");
			per = 4;
			break;
		case 0x12:			// CMOS only
			a |= peek(am_iz());
			bits_nz(a);
			if (ver > 1) printf("[ORA(z)]");
			per = 5;
			break;
		case 0x48:						// *** PHA: Push Accumulator on Stack ***
			push(a);
			if (ver > 1) printf("[PHA]");
			per = 3;
			break;
		case 0x08:						// *** PHP: Push Processor Status on Stack ***
			push(p);
			if (ver > 1) printf("[PHP]");
			per = 3;
			break;
		case 0xDA:						// CMOS only: *** PHX ***
			push(x);
			if (ver > 1) printf("[PHX]");
			per = 3;
			break;
		case 0x5A:						// CMOS only: *** PHY ***
			push(y);
			if (ver > 1) printf("[PHY]");
			per = 3;
			break;
		case 0x68:						// *** PLA: Pull Accumulator from Stack ***
			a = pop();
			if (ver > 1) printf("[PLA]");
			bits_nz(a);
			per = 4;
			break;
		case 0x28:						// *** PLP: Pull Processor Status from Stack ***
			p = pop();
			if (ver > 1) printf("[PLP]");
			per = 4;
			break;
		case 0xFA:						// CMOS only: *** PLX ***
			x = pop();
			if (ver > 1) printf("[PLX]");
			per = 4;
			break;
		case 0x7A:						// CMOS only: *** PLY ***
			y = pop();
			if (ver > 1) printf("[PLY]");
			per = 4;
			break;
		case 0x2E:						// *** ROL: Rotate One Bit Left (Memory or Accumulator) ***
			adr = am_a();
			temp = peek(adr);
			rol(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[ROLa]");
			per = 6;
			break;
		case 0x26:
			temp = peek(peek(pc));
			rol(&temp);
			poke(peek(pc++), temp);
			if (ver > 1) printf("[ROLz]");
			per = 5;
			break;
		case 0x36:
			adr = am_zx();
			temp = peek(adr);
			rol(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[ROLzx]");
			per = 6;
			break;
		case 0x3E:
			adr = am_ax();
			temp = peek(adr);
			rol(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[ROLx]");
			per = 6;		// 7 for NMOS
			break;
		case 0x2A:
			rol(&a);
			if (ver > 1) printf("[ROL]");
			break;
		case 0x6E:						// *** ROR: Rotate One Bit Right (Memory or Accumulator) ***
			adr = am_a();
			temp = peek(adr);
			ror(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[RORa]");
			per = 6;
			break;
		case 0x66:
			temp = peek(peek(pc));
			ror(&temp);
			poke(peek(pc++), temp);
			if (ver > 1) printf("[RORz]");
			per = 5;
			break;
		case 0x6A:
			ror(&a);
			if (ver > 1) printf("[ROR]");
			break;			
		case 0x76:
			adr = am_zx();
			temp = peek(adr);
			ror(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[RORzx]");
			per = 6;
			break;
		case 0x7E:
			adr = am_ax();
			temp = peek(adr);
			ror(&temp);
			poke(adr, temp);
			if (ver > 1) printf("[RORx]");
			per = 6;		// 7 for NMOS
			break;
		case 0x40:						// *** RTI: Return from Interrupt ***
			p = pop();
			pc = pop();					// extract LSB...
			pc |= (pop() << 8);			// ...and MSB, address is correct
			if (ver)	printf("[RTI]");
			per = 6;
			break;
		case 0x60:						// *** RTS: Return from Subroutine ***
			pc = pop();					// extract LSB...
			pc |= (pop() << 8);			// ...and MSB, but is one byte off
			pc++;						// return instruction address
			if (ver)	printf("[RTS]");
			per = 6;
			break;
		case 0xE9:						// *** SBC: Subtract Memory from Accumulator with Borrow ***
			sbc(peek(pc++));
			if (ver > 1) printf("[SBC#]");
			break;
		case 0xED:
			sbc(peek(am_a()));
			if (ver > 1) printf("[SBCa]");
			per = 4;
			break;
		case 0xE5:
			sbc(peek(peek(pc++)));
			if (ver > 1) printf("[SBCz]");
			per = 3;
			break;
		case 0xE1:
			sbc(peek(am_ix()));
			if (ver > 1) printf("[SBC(x)]");
			per = 6;
			break;
		case 0xF1:
			sbc(peek(am_iy()));
			if (ver > 1) printf("[SBC(y)]");
			per = 5;
			break;
		case 0xF5:
			sbc(peek(am_zx()));
			if (ver > 1) printf("[SBCzx]");
			per = 4;
			break;
		case 0xFD:
			sbc(peek(am_ax()));
			if (ver > 1) printf("[SBCx]");
			per = 4;
			break;
		case 0xF9:
			sbc(peek(am_ay()));
			if (ver > 1) printf("[SBCy]");
			per = 4;
			break;
		case 0xF2:			// CMOS only
			sbc(peek(am_iz()));
			if (ver > 1) printf("[SBC(z)]");
			per = 5;
			break;
		case 0x38:						// *** SEC: Set Carry Flag ***
			p |= 0b00000001;
			if (ver > 1) printf("[SEC]");
			break;
		case 0xF8:						// *** SEC: Set Decimal Mode ***
			p |= 0b00001000;
			if (ver > 1) printf("[SED]");
			break;
		case 0x78:						// *** SEI: Set Interrupt Disable Status ***
			p |= 0b00000100;
			if (ver > 1) printf("[SEI]");
			break;
		case 0x8D:						// *** STA: Store Accumulator in Memory ***
			poke(am_a(), a);
			if (ver > 1) printf("[STAa]");
			per = 4;
			break;
		case 0x85:
			poke(peek(pc++), a);
			if (ver > 1) printf("[STAz]");
			per = 3;
			break;
		case 0x81:
			poke(am_ix(), a);
			if (ver > 1) printf("[STA(x)]");
			per = 6;
			break;
		case 0x91:
			poke(am_iy(), a);
			if (ver > 1) printf("[STA(y)]");
			per = 6;	// ...and not 5, as expected
			break;
		case 0x95:
			poke(am_zx(), a);
			if (ver > 1) printf("[STAzx]");
			pc++;
			per = 4;
			break;
		case 0x9D:
			poke(am_ax(), a);
			if (ver > 1) printf("[STAx]");
			per = 5;	// ...and not 4, as expected
			break;
		case 0x99:
			poke(am_ay(), a);
			if (ver > 1) printf("[STAy]");
			per = 5;	// ...and not 4, as expected
			break;
		case 0x92:	// CMOS only
			poke(am_iz(), a);
			if (ver > 1) printf("[STA(z)]");
			per = 5;
			break;
		case 0x8E:						// *** STX: Store Index X in Memory ***
			poke(am_a(), x);
			if (ver > 1) printf("[STXa]");
			per = 4;
			break;
		case 0x86:
			poke(peek(pc++), x);
			if (ver > 1) printf("[STXz]");
			per = 3;
			break;
		case 0x96:
			poke(am_zy(), x);
			if (ver > 1) printf("[STXzy]");
			per = 4;
			break;
		case 0x8C:						// *** STY: Store Index Y in Memory ***
			poke(am_a(), y);
			if (ver > 1) printf("[STYa]");
			per = 4;
			break;
		case 0x84:
			poke(peek(pc++), y);
			if (ver > 1) printf("[STYz]");
			per = 3;
			break;
		case 0x94:
			poke(am_zx(), y);
			if (ver > 1) printf("[STYzx]");
			per = 4;
			break;
		case 0x9C:						// CMOS only: *** STZ ***
			poke(am_a(), 0);
			if (ver > 1) printf("[STZa]");
			per = 4;
			break;
		case 0x64:
			poke(peek(pc++), 0);
			if (ver > 1) printf("[STZz]");
			per = 3;
			break;
		case 0x74:
			poke(am_zx(), 0);
			if (ver > 1) printf("[STZzx]");
			per = 4;
			break;
		case 0x9E:
			poke(am_ax(), 0);
			if (ver > 1) printf("[STZx]");
			per = 5;	// ...and not 4, as expected
			break;
		case 0xAA:						// *** TAX: Transfer Accumulator to Index X ***
			x = a;
			bits_nz(x);
			if (ver > 1) printf("[TAX]");
			break;
		case 0xA8:						// *** TAY: Transfer Accumulator to Index Y ***
			y = a;
			bits_nz(y);
			if (ver > 1) printf("[TAY]");
			break;
		case 0x1C:						// CMOS only: *** TRB ***
			adr = am_a();
			temp = peek(adr);//***************
			temp &= !a;
			poke(adr, temp);
			if (temp == 0)//*********
				p |= 0x02;
			else
				p &= 0xFD;
			if (ver > 1) printf("[TRBa]");
			per = 6;
			break;
		case 0x14:
			temp = peek(peek(pc));
			temp &= !a;
			poke(peek(pc++), temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TRBz]");
			per = 5;
			break;
		case 0x0C:						// CMOS only: *** TSB ***
			adr = am_a();
			temp = peek(am_a());
			temp |= a;
			poke(adr, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TSBa]");
			per = 6;
			break;
		case 0x04:
			temp = peek(peek(pc));
			temp |= a;
			poke(peek(pc++), temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TSBz]");
			per = 5;
			break;
		case 0xBA:						// *** TSX: Transfer Stack Ponter to Index X ***
			x = s;
			bits_nz(x);
			if (ver > 1) printf("[TSX]");
			break;
		case 0x8A:						// *** TXA: Transfer Index X to Accumulator ***
			a = x;
			bits_nz(a);
			if (ver > 1) printf("[TXA]");
			break;
		case 0x9A:						// *** TXS: Transfer Index X to Stack Register ***
			s = x;
			bits_nz(s);
			if (ver > 1) printf("[TXS]");
			break;
		case 0x98:						// *** TYA: Transfer Index Y to Accumulator ***
			a = y;
			bits_nz(a);
			if (ver > 1) printf("[TYA]");
			break;
		case 0xFF:						// ******** display status ******** Rockwell opcodes NOT supported
			printf(" ...status:");
			stat(p);
			break;
		default:						// ******** halt CPU on illegal opcodes ********
			printf("\n*** ($%04X) Illegal opcode $%02X ***\n", pc-1, opcode);
			run = 0;
	}

	return per;
}
