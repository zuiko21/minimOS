/* Perdita 65C02 Durango-S emulator!
 * (c)2007-2022 Carlos J. Santisteban
 * last modified 20220627-2023
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

	const char flag[8]="NV·BDIZC";	// flag names

/* function prototypes */
	void stat(byte psr);	// display processor status
	byte peek(word dir);			// read memory or I/O
	void poke(word dir, byte v);	// write memory or I/O
	void push(byte b);		{ poke(0x100 + s--, b); }		// standard stack ops
	byte pop(void);			{ return peek(++s + 0x100); }

	void rel(byte off);		// relative branches
	void bits_nz(byte b);	// set N&Z flags
	void lrot_p(byte *d);	// ??? 
	void adc(byte d);		// add with carry
	void asl(byte *d);		// shift left
	void cmp(byte d);		// compare
	void lsr(byte *d);		// shift right
	void rol(byte *d);		// rotate left
	void ror(byte *d);		// rotate right
	void sbc(byte d);

	int exec(void);
	void reset(void);
	void nmi(void);
	void irq(void);

/* convert these to functions, or inline them
	op_l = peek(pc);
	op_w = peek(pc + 1);
	
	am_a = op_l + 256*op_h;
	am_ix = peek(op_l + x) + 256*peek(op_l + x + 1);
	am_iy = peek(op_l) + 256*peek(op_l + 1) + y;
	am_zx = op_l + x;
	am_zy = op_l + y;
	am_ax = am_a + x;
	am_ay = am_a + y;
	am_ai = peek(am_a) + 256*peek(am_a + 1);
	am_aix = peek(am_a + x) + 256*peek(am_a + x + 1);
	am_iz = am_iy - y;
*/

/* ******************* startup ******************* */
int main (int argc, char * const argv[]) {
	long cont = 0;			// total elapsed cycles
	int cyc, t=0;			// instruction and interrupt cycle counter
	
	reset();
	
	do
	{
		cyc = exec();		// count elapsed clock cycles
		cont += cyc;
		t += cyc;
		if (t >= 6144)		// 250 Hz interrupt @ 1.536 MHz
		{
			t -= 6144;		// restore for next
			if (mem[0xDFA0] & 1) {	// are hardware interrupts enabled?
				irq();				// maybe update screen as well
			}
		}
	} while (run);
	
	printf(" *** CPU halted after %d clock cycles ***\n", cont);
	stat(p);					// display end status

	return 0;
}

/* support function definitions */
void stat(byte psr)	{		// display CPU status
	int i;

	printf("<PC=%04X, A=%02X, X=%02X, Y=%02X, S=%02X>\n<PSR: ", pc-1, a, x, y, s);
	for (i=0; i<8; i++) {
		if (psr&128)	printf("%c", flags[i]);
		else			printf("·");
		psr<=1;				// next flag
	}
	printf(">\n");
}

/* constructor is no more
_65c02(void)
{
	int i;
	cargarROM();
	
	vdu_ctl[0] = 0;				// VDU estándar
	for(i=1; i<16382; i++)
		vdu_ctl[i] = 0xEA;		// zona VDU al aire
	
// *** take these into main() ***
	run = 1;
	ver = 0;					// verbosity mode, 0 = none, 1 = jumps, 2 = auto?, 3 = all 
}
* */

void cargarROM(void)	// kernel.rom  y  monitor.rom
{
	FILE *f;
	int c, b = 0;
	
	f = fopen("a.o65", "rb");	// será 'kernel.rom'
	if(f != NULL)
	{
		do
		{
			c = fgetc(f);
			//printf("%p ",c);
			mem[32768+b++] = c;
		} while( c != EOF);
		fclose(f);
		printf("kernel.rom: %d bytes cargados\n", b);
	}
	else	printf("*** No he podido cargar 'kernel.rom' ***\n");
	
	mem[32768+0x3ffc] = 0x16; // vector RESET, provisional
	mem[32768+0x3ffd] = 0xc0; // vector RESET, provisional
	mem[32768+0x3ffe] = 0x00;//FF; // depurador
	
/*	mem[32768+0x16] = 0xA9; // LDA #
	mem[32768+0x17] = '=';
	mem[32768+0x18] = 0x8D; // STA am_a
	mem[32768+0x19] = 0xA0; // donde
	mem[32768+0x1A] = 0xDF;
	mem[32768+0x1B] = 0xAA; // TAX
	mem[32768+0x1C] = 0x9D;	// STA am_a, X
	mem[32768+0x1D] = 0x00;	//
	mem[32768+0x1E] = 0x40;	//
	mem[32768+0x1F] = 0xCA;	// DEX
	mem[32768+0x20] = 0xD0;	// BNE
	mem[32768+0x21] = 0xFA;	//
	// provisional
	mem[32768+0x22] = 0x4C; // JMP ***infinito***
	mem[32768+0x23] = 0x22;
	mem[32768+0x24] = 0xc0;
*/
		
}

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

void poke(long dir, int v)
{
	if (dir>=0 && dir<32768)			// 32 KiB static RAM
		mem[dir] = v;

	if (dir>=0xDF80 && dir<=0xDFFF) {	// I/O
		if (dir<=0xDF87)				// video mode?
			mem[0xDF80] = v;			// canonical address
		else if (dir<=0xDF8F)			// sync flags?
// *** not writable
		else if (dir<=0xDF9F)			// expansion port?
			mem[dir] = v;				// *** is this OK?
		else if (dir<=0xDFAF)			// interrupt control?
			mem[0xDFA0] = v;			// canonical address, only D0 matters
		else if (dir<=0xDFBF)			// beeper?
			mem[0xDFB0] = v;			// canonical address, only D0 matters *** anything else?
		else
			mem[dir] = v;				// otherwise is cartridge I/O *** anything else?
	}
}

void reset(void)
{
	pc = peek(0xFFFC) + 256*peek(0xFFFD);	// RESET vector

	printf(" RESET: PC=>%04X\n", pc);

	p &= 0b11110011;						// CLD & SEI on 65C02
	p |= 0b00110000;						// these always 1
}

void nmi(void)
{
	if (ver)	printf("<NMI>");
	// implementar...
	//pc = peek(0xfffa) + 256*peek(0xfffb);	// vector NMI
}

void irq(void)
{
	if (ver)	printf("<IRQ>");
	// implementar...
	//pc = peek(0xfffe) + 256*peek(0xffff);	// vector IRQ/BRK
}

void rel(int off)
{
	pc += off;
	if (off >= 128)
	{
		pc -= 256;
		if (ver) printf(".");
		if (ver == 2)	ver = 1;
	}
}

void bits_nz(int b)
{
	if (b >= 0x80)
		p |= 0x80;
	else
		p &= 0x7F;
	if (b == 0)
		p |= 0x02;
	else
		p &= 0xFD;
}

void lrot_p(int *d)
{
	if (*d >= 256)
	{
		p |= 0x01;
		(*d) &= 0xFF;
	}
	else	p &= 0xFE;
	bits_nz(*d);
}

void adc(int d)	// ¿¿¿ OVERFLOW, aquí ???
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

void asl(int *d)
{
	(*d) << 1;
	lrot_p(d);
}

void cmp(int d)
{
	bits_nz(d);
	if (d < 0)
		p |= 0x01;
	else
		p &= 0xFE;
}

void lsr(int *d)
{
	if ((*d) & 0x01)
		p |= 0x01;
	else
		p &= 0xFE;
	(*d) >> 1;
	bits_nz(*d);

}

void rol(int *d)
{
	(*d) << 1;
	(*d) |= (p & 0x01);
	lrot_p(d);
}

void ror(int *d)
{
	if (p & 0x01)		(*d) |= 0x100;
	if ((*d) & 0x01)	p |= 0x01;
	else				p &= 0xFE;
	(*d) >> 1;
	bits_nz(*d);
}

void sbc(int d)
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

int exec(void)
{
	int opcode, op_l, op_h, temp, per = 2;
	long am_a, am_ix, am_iy, am_zx, am_zy, am_ax, am_ay;
	long am_ai, am_aix, am_iz; 
	
	opcode = peek(pc++);
//inline these?	
	op_l = peek(pc);
	op_h = peek(pc + 1);
	
	am_a = op_l + 256*op_h;
	am_ix = peek(op_l + x) + 256*peek(op_l + x + 1);
	am_iy = peek(op_l) + 256*peek(op_l + 1) + y;
	am_zx = op_l + x;
	am_zy = op_l + y;
	am_ax = am_a + x;
	am_ay = am_a + y;
	am_ai = peek(am_a) + 256*peek(am_a + 1);
	am_aix = peek(am_a + x) + 256*peek(am_a + x + 1);
	am_iz = am_iy - y;
	
	switch(opcode)
	{
		case 0x69:						// *** ADC: Add Memory to Accumulator with Carry ***
			adc(op_l);
			if (ver > 1) printf("[ADC#]");
			pc++;
			break;
		case 0x6D:
			adc(peek(am_a));
			if (ver > 1) printf("[ADCa]");
			pc += 2;
			per = 4;
			break;
		case 0x65:
			adc(peek(op_l));
			if (ver > 1) printf("[ADCz]");
			pc++;
			per = 3;
			break;
		case 0x61:
			adc(peek(am_ix));
			if (ver > 1) printf("[ADC(x)]");
			pc++;
			per = 6;
			break;
		case 0x71:
			adc(peek(am_iy));
			if (ver > 1) printf("[ADC(y)]");
			pc++;
			per = 5;
			break;
		case 0x75:
			adc(peek(am_zx));
			if (ver > 1) printf("[ADCzx]");
			pc++;
			per = 4;
			break;
		case 0x7D:
			adc(peek(am_ax));
			if (ver > 1) printf("[ADCx]");
			pc += 2;
			per = 4;
			break;
		case 0x79:
			adc(peek(am_ay));
			if (ver > 1) printf("[ADCy]");
			pc += 2;
			per = 4;
			break;
		case 0x72:	// CMOS only
			adc(peek(am_iz));
			if (ver > 1) printf("[ADC(z)]");
				pc++;
			per = 5;
			break;
		case 0x29:						// *** AND: "And" Memory with Accumulator ***
			a &= op_l;
			bits_nz(a);
			if (ver > 1) printf("[AND#]");
			pc++;
			break;
		case 0x2D:
			a &= peek(am_a);
			bits_nz(a);
			if (ver > 1) printf("[ANDa]");
			pc += 2;
			per = 4;
			break;
		case 0x25:
			a &= peek(op_l);
			bits_nz(a);
			if (ver > 1) printf("[ANDz]");
			pc++;
			per = 3;
			break;
		case 0x21:
			a &= peek(am_ix);
			bits_nz(a);
			if (ver > 1) printf("[AND(x)]");
			pc++;
			per = 6;
			break;
		case 0x31:
			a &= peek(am_iy);
			bits_nz(a);
			if (ver > 1) printf("[AND(y)]");
			pc++;
			per = 5;
			break;
		case 0x35:
			a &= peek(am_zx);
			bits_nz(a);
			if (ver > 1) printf("[ANDzx]");
			pc++;
			per = 4;
			break;
		case 0x3D:
			a &= peek(am_ax);
			bits_nz(a);
			if (ver > 1) printf("[ANDx]");
			pc += 2;
			per = 4;
			break;
		case 0x39:
			a &= peek(am_ay);
			bits_nz(a);
			if (ver > 1) printf("[ANDy]");
			pc += 2;
			per = 4;
			break;
		case 0x32:	// CMOS only
			a &= peek(am_iz);
			bits_nz(a);
			if (ver > 1) printf("[AND(z)]");
				pc++;
			per = 5;
			break;
		case 0x0E:						// *** ASL: Shift Left one Bit (Memory or Accumulator) ***
			temp = peek(am_a);
			asl(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[ASLa]");
			pc += 2;
			per = 6;
			break;
		case 0x06:
			temp = peek(op_l);
			asl(&temp);
			poke(op_l, temp);
			if (ver > 1) printf("[ASLz]");
			pc++;
			per = 5;
			break;
		case 0x0A:
			asl(&a);
			if (ver > 1) printf("[ASL]");
			break;
		case 0x16:
			temp = peek(am_zx);
			asl(&temp);
			poke(am_zx, temp);
			if (ver > 1) printf("[ASLzx]");
			pc++;
			per = 6;
			break;
		case 0x1E:
			temp = peek(am_ax);
			asl(&temp);
			poke(am_ax, temp);
			if (ver > 1) printf("[ASLx]");
			pc += 2;
			per = 6;		// 7 for NMOS
			break;
		case 0x90:						// *** BCC: Branch on Carry Clear ***
			pc++;
			if(!(p & 0x01))
			{
				rel(op_l);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BCC]");
			break;
		case 0xB0:						// *** BCS: Branch on Carry Set ***
			pc++;
			if(p & 0x01)
			{
				rel(op_l);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BCS]");
			break;
		case 0xF0:						// *** BEQ: Branch on Result Zero ***
			pc++;
			if(p & 0x02)
			{
				rel(op_l);
				per = 3;
			}				
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BEQ]");
			break;
		case 0x2C:						// *** BIT: Test Bits in Memory with Accumulator (?) ***
			temp = peek(am_a);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** finish BIT ***
			printf("[BITa]");
			pc += 2;
			per = 4;
			break;
		case 0x24:
			temp = peek(op_l);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** finish BIT ***
			printf("[BITz]");
			pc++;
			per = 3;
			break;
		case 0x89:			// CMOS only
			temp = op_l;
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** finish BIT ***
			printf("[BIT#]");
			pc++;
			break;
		case 0x3C:			// CMOS only
			temp = peek(am_ax);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** finish BIT ***
			printf("[BITx]");
			pc += 2;
			per = 4;
			break;
		case 0x34:			// CMOS only
			temp = peek(am_zx);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
			// *** finish BIT ***
			printf("[BITzx]");
			pc++;
			per = 4;
			break;
		case 0x30:						// *** BMI: Branch on Result Minus ***
			pc++;
			if(p & 0x80)
			{
				rel(op_l);
				per = 3;
			}		
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BMI]");
			break;
		case 0xD0:						// *** BNE: Branch on Result Not Zero ***
			pc++;
			if(!(p & 0x02))
			{
				rel(op_l);
				per = 3;
			}				
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BNE]");
			break;
		case 0x10:						// *** BPL: Branch on Result Plus ***
			pc++;
			if(!(p & 0x80))
			{
				rel(op_l);
				per = 3;
			}			
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BPL]");
			break;
		case 0x80:						// CMOS only: *** BRA ***
			pc++;
			rel(op_l);
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
				rel(op_l);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BVC]");
			break;
		case 0x70:						// *** BVC: Branch on Overflow Set ***
			pc++;
			if(p & 0x40)
			{
				rel(op_l);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BVS]");
			break;
		case 0x18:						// *** CLC: Clear Carry Flag ***
			p &= 0xFE;
			if (ver > 1) printf("[CLC]");
			break;
		case 0xD8:						// *** CLD: Clear Decimal Mode ***
			p &= 0xF7;
			if (ver > 1) printf("[CLD]");
			break;
		case 0x58:						// *** CLI: Clear Interrupt Disable Bit ***
			p &= 0xFB;
			if (ver > 1) printf("[CLI]");
			break;
		case 0xB8:						// *** CLV: Clear Overflow Flag ***
			p &= 0xBF;
			if (ver > 1) printf("[CLV]");
			break;
		case 0xC9:						// *** CMP: Compare Memory And Accumulator ***		¿¿¿ o al revés ???
			cmp(a - op_l);
			if (ver > 1) printf("[CMP#]");
			pc++;
			break;
		case 0xCD:
			temp = peek(am_a);
			cmp(a - temp);
			if (ver > 1) printf("[CMPa]");
			pc += 2;
			per = 4;
			break;
		case 0xC5:
			temp = peek(op_l);
			cmp(a - temp);
			if (ver > 1) printf("[CMPz]");
			per = 3;
			pc++;
			break;
		case 0xC1:
			temp = peek(am_ix);
			cmp(a - temp);
			if (ver > 1) printf("[CMP(x)]");
			pc++;
			per = 6;
			break;
		case 0xD1:
			temp = peek(am_iy);
			cmp(a - temp);
			if (ver > 1) printf("[CMP(y)]");
			pc++;
			per = 5;
			break;
		case 0xD5:
			temp = peek(am_zx);
			cmp(a - temp);
			if (ver > 1) printf("[CMPzx]");
			pc++;
			per = 4;
			break;
		case 0xDD:
			temp = peek(am_ax);
			cmp(a - temp);
			if (ver > 1) printf("[CMPx]");
			pc += 2;
			per = 4;
			break;
		case 0xD9:
			temp = peek(am_ay);
			cmp(a - temp);
			if (ver > 1) printf("[CMPy]");
			pc += 2;
			per = 4;
			break;
		case 0xD2:			// CMOS only
			temp = peek(am_iz);
			cmp(a - temp);
			if (ver > 1) printf("[CMP(z)]");
			pc++;
			per = 5;
			break;
		case 0xE0:						// *** CPX: Compare Memory And Index X ***
			cmp(x - op_l);
			if (ver > 1) printf("[CPX#]");
			pc++;
			break;
		case 0xEC:
			temp = peek(am_a);
			cmp(x - temp);
			if (ver > 1) printf("[CPXa]");
			pc += 2;
			per = 4;
			break;
		case 0xE4:
			temp = peek(op_l);
			cmp(x - temp);
			if (ver > 1) printf("[CPXz]");
			pc++;
			per = 3;
			break;
		case 0xC0:						// *** CPY: Compare Memory And Index Y ***
			cmp(y - op_l);
			if (ver > 1) printf("[CPY#]");
			pc++;
			break;
		case 0xCC:
			temp = peek(am_a);
			cmp(y - temp);
			if (ver > 1) printf("[CPYa]");
			pc += 2;
			per = 4;
			break;
		case 0xC4:
			temp = peek(op_l);
			cmp(y - temp);
			if (ver > 1) printf("[CPYz]");
			pc++;
			per = 3;
			break;
		case 0xCE:						// *** DEC: Decrement Memory (or Accumulator) by One ***
			temp = peek(am_a);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(am_a, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECa]");
			pc += 2;
			per = 6;
			break;
		case 0xC6:
			temp = peek(op_l);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(op_l, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECz]");
			pc++;
			per = 5;
			break;
		case 0xD6:
			temp = peek(am_zx);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(am_zx, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECzx]");
			pc += 2;
			per = 6;
			break;
		case 0xDE:
			temp = peek(am_ax);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(am_ax, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
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
			a ^= op_l;
			bits_nz(a);
			if (ver > 1) printf("[EOR#]");
			pc++;
			break;
		case 0x4D:
			a ^= peek(am_a);
			bits_nz(a);
			if (ver > 1) printf("[EORa]");
			pc += 2;
			per = 4;
			break;
		case 0x45:
			a ^= peek(op_l);
			bits_nz(a);
			if (ver > 1) printf("[EORz]");
			pc++;
			per = 3;
			break;
		case 0x41:
			a ^= peek(am_ix);
			bits_nz(a);
			if (ver > 1) printf("[EOR(x)]");
			pc++;
			per = 6;
			break;
		case 0x51:
			a ^= peek(am_iy);
			bits_nz(a);
			if (ver > 1) printf("[EOR(y)]");
			pc++;
			per = 5;
			break;
		case 0x55:
			a ^= peek(am_zx);
			bits_nz(a);
			if (ver > 1) printf("[EORzx]");
			pc++;
			per = 4;
			break;
		case 0x5D:
			a ^= peek(am_ax);
			bits_nz(a);
			if (ver > 1) printf("[EORx]");
			pc += 2;
			per = 4;
			break;
		case 0x59:
			a ^= peek(am_ay);
			bits_nz(a);
			if (ver > 1) printf("[EORy]");
			pc += 2;
			per = 4;
			break;
		case 0x52:			// CMOS only
			a ^= peek(am_iz);
			bits_nz(a);
			if (ver > 1) printf("[EOR(z)]");
				pc++;
			per = 5;
			break;
		case 0xEE:						// *** INC: Increment Memory (or Accumulator) by One ***
			temp = peek(am_a);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(am_a, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCa]");
			pc += 2;
			per = 6;
			break;
		case 0xE6:
			temp = peek(op_l);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(op_l, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCz]");
			pc++;
			per = 5;
			break;
		case 0xF6:
			temp = peek(am_zx);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(am_zx, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCzx]");
			pc++;
			per = 6;
			break;
		case 0xFE:
			temp = peek(am_ax);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(am_ax, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
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
			pc = am_a;
			if (ver)	printf("[JMP]");
			per = 3;
			break;
		case 0x6C:
			pc = am_ai;
			if (ver)	printf("[JMP*]");
			per = 6;		// 5 for NMOS!
			break;
		case 0x7C:			// CMOS only
			pc = am_aix;
			if (ver)	printf("[JMP(x)]");
			per = 6;
			break;
		case 0x20:						// *** JSR: Jump to New Location Saving Return Address ***
			pc++;						// se queda en el MSB
			op_l = pc & 255;
			op_h = pc >> 8;
			push(op_h);
			push(op_l);
			pc = am_a;
			if (ver)	printf("[JSR]");
			per = 6;
			break;
		case 0xA9:						// *** LDA: Load Accumulator with Memory ***
			a = op_l;
			bits_nz(a);
			if (ver > 1) printf("[LDA#]");
			pc++;
			break;
		case 0xAD:
			a = peek(am_a);
			bits_nz(a);
			if (ver > 1) printf("[LDAa]");
			pc += 2;
			per = 4;
			break;
		case 0xA5:
			a = peek(op_l);
			bits_nz(a);
			if (ver > 1) printf("[LDAz]");
			pc++;
			per = 3;
			break;
		case 0xA1:
			a = peek(am_ix);
			bits_nz(a);
			if (ver > 1) printf("[LDA(x)]");
			pc++;
			per = 6;
			break;
		case 0xB1:
			a = peek(am_iy);
			bits_nz(a);
			if (ver > 1) printf("[LDA(y)]");
			pc++;
			per = 5;
			break;
		case 0xB5:
			a = peek(am_zx);
			bits_nz(a);
			if (ver > 1) printf("[LDAzx]");
			pc++;
			per = 4;
			break;
		case 0xBD:
			a = peek(am_ax);
			bits_nz(a);
			if (ver > 1) printf("[LDAx]");
			pc += 2;
			per = 4;
			break;
		case 0xB9:
			a = peek(am_ay);
			bits_nz(a);
			if (ver > 1) printf("[LDAy]");
			pc += 2;
			per = 4;
			break;
		case 0xB2:	// CMOS only
			a = peek(am_iz);
			bits_nz(a);
			if (ver > 1) printf("[LDA(z)]");
			pc++;
			per = 5;
			break;
		case 0xA2:						// *** LDX: Load Index X with Memory ***
			x = op_l;
			bits_nz(x);
			if (ver > 1) printf("[LDX#]");
			pc++;
			break;
		case 0xAE:
			x = peek(am_a);
			bits_nz(x);
			if (ver > 1) printf("[LDXa]");
			pc += 2;
			per = 4;
			break;
		case 0xA6:
			x = peek(op_l);
			bits_nz(x);
			if (ver > 1) printf("[LDXz]");
			pc++;
			per = 3;
			break;
		case 0xB6:
			x = peek(am_zy);
			bits_nz(x);
			if (ver > 1) printf("[LDXzy]");
			pc++;
			per = 4;
			break;
		case 0xBE:
			x = peek(am_ay);
			bits_nz(x);
			if (ver > 1) printf("[LDXy]");
			pc += 2;
			per = 4;
			break;
		case 0xA0:						// *** LDY: Load Index Y with Memory ***
			y = op_l;
			bits_nz(y);
			if (ver > 1) printf("[LDY#]");
			pc++;
			break;
		case 0xAC:
			y = peek(am_a);
			bits_nz(y);
			if (ver > 1) printf("[LDYa]");
			pc += 2;
			per = 4;
			break;
		case 0xA4:
			y = peek(op_l);
			bits_nz(y);
			if (ver > 1) printf("[LDYz]");
			pc++;
			per = 3;
			break;
		case 0xB4:
			y = peek(am_zx);
			bits_nz(y);
			if (ver > 1) printf("[LDYzx]");
			pc++;
			per = 4;
			break;
		case 0xBC:
			y = peek(am_ax);
			bits_nz(y);
			if (ver > 1) printf("[LDYx]");
			pc += 2;
			per = 4;
			break;
		case 0x4E:						// *** LSR: Shift One Bit Right (Memory or Accumulator) ***
			temp = peek(am_a);
			lsr(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[LSRa]");
			pc += 2;
			per = 6;
			break;
		case 0x46:
			temp = peek(op_l);
			lsr(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[LSRz]");
			pc++;
			per = 5;
			break;
		case 0x4A:
			lsr(&a);
			printf("[LSR]");
			break;
		case 0x56:
			temp = peek(am_zx);
			lsr(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[LSRzx]");
			pc++;
			per = 6;
			break;
		case 0x5E:
			temp = peek(am_ax);
			lsr(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[LSRx]");
			pc += 2;
			per = 6;		// 7 for NMOS
			break;
		case 0xEA:						// *** NOP: No Operation ***
			if (ver) printf("[NOP]");
			break;
		case 0x09:						// *** ORA: "Or" Memory with Accumulator ***
			a |= op_l;
			bits_nz(a);
			if (ver > 1) printf("[ORA#]");
			pc++;
			break;
		case 0x0D:
			a |= peek(am_a);
			bits_nz(a);
			if (ver > 1) printf("[ORAa]");
			pc += 2;
			per = 4;
			break;
		case 0x05:
			a |= peek(op_l);
			bits_nz(a);
			if (ver > 1) printf("[ORAz]");
			pc++;
			per = 3;
			break;
		case 0x01:
			a |= peek(am_ix);
			bits_nz(a);
			if (ver > 1) printf("[ORA(x)]");
			pc++;
			per = 6;
			break;
		case 0x11:
			a |= peek(am_iy);
			bits_nz(a);
			if (ver > 1) printf("[ORA(y)]");
			pc++;
			per = 5;
			break;
		case 0x15:
			a |= peek(am_zx);
			bits_nz(a);
			if (ver > 1) printf("[ORAzx]");
			pc++;
			per = 4;
			break;
		case 0x1D:
			a |= peek(am_ax);
			bits_nz(a);
			if (ver > 1) printf("[ORAx]");
			pc += 2;
			per = 4;
			break;
		case 0x19:
			a |= peek(am_ay);
			bits_nz(a);
			if (ver > 1) printf("[ORAy]");
			pc += 2;
			per = 4;
			break;
		case 0x12:			// CMOS only
			a |= peek(am_iz);
			bits_nz(a);
			if (ver > 1) printf("[ORA(z)]");
			pc++;
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
			temp = peek(am_a);
			rol(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[ROLa]");
			pc += 2;
			per = 6;
			break;
		case 0x26:
			temp = peek(op_l);
			rol(&temp);
			poke(op_l, temp);
			if (ver > 1) printf("[ROLz]");
			pc++;
			per = 5;
			break;
		case 0x36:
			temp = peek(am_zx);
			rol(&temp);
			poke(am_zx, temp);
			if (ver > 1) printf("[ROLzx]");
			pc++;
			per = 6;
			break;
		case 0x3E:
			temp = peek(am_ax);
			rol(&temp);
			poke(am_ax, temp);
			if (ver > 1) printf("[ROLx]");
			pc += 2;
			per = 6;		// 7 for NMOS
			break;
		case 0x2A:
			rol(&a);
			if (ver > 1) printf("[ROL]");
			pc++;
			break;
		case 0x6E:						// *** ROR: Rotate One Bit Right (Memory or Accumulator) ***
			temp = peek(am_a);
			ror(&temp);
			poke(am_a, temp);
			if (ver > 1) printf("[RORa]");
			pc += 2;
			per = 6;
			break;
		case 0x66:
			temp = peek(op_l);
			ror(&temp);
			poke(op_l, temp);
			if (ver > 1) printf("[RORz]");
			pc++;
			per = 5;
			break;
		case 0x6A:
			ror(&a);
			if (ver > 1) printf("[ROR]");
			pc++;
			break;			
		case 0x76:
			temp = peek(am_zx);
			ror(&temp);
			poke(am_zx, temp);
			if (ver > 1) printf("[RORzx]");
			pc++;
			per = 6;
			break;
		case 0x7E:
			temp = peek(am_ax);
			ror(&temp);
			poke(am_ax, temp);
			if (ver > 1) printf("[RORx]");
			pc += 2;
			per = 6;		// 7 for NMOS
			break;
		case 0x40:						// *** RTI: Return from Interrupt ***
			p = pop();
			op_l = pop();
			op_h = pop();
			pc = op_l + 256*op_h + 1;		// ojo que se quedó en MSB
			if (ver)	printf("[RTI]");
			per = 6;
			break;
		case 0x60:						// *** RTS: Return from Subroutine ***
			op_l = pop();
			op_h = pop();
			pc = op_l + 256*op_h + 1;		// ojo que se quedó en MSB
			if (ver)	printf("[RTS]");
			per = 6;
			break;
		case 0xE9:						// *** SBC: Subtract Memory from Accumulator with Borrow ***
			sbc(op_l);
			if (ver > 1) printf("[SBC#]");
			pc++;
			break;
		case 0xED:
			sbc(peek(am_a));
			if (ver > 1) printf("[SBCa]");
			pc += 2;
			per = 4;
			break;
		case 0xE5:
			sbc(peek(op_l));
			if (ver > 1) printf("[SBCz]");
			pc++;
			per = 3;
			break;
		case 0xE1:
			sbc(peek(am_ix));
			if (ver > 1) printf("[SBC(x)]");
			pc++;
			per = 6;
			break;
		case 0xF1:
			sbc(peek(am_iy));
			if (ver > 1) printf("[SBC(y)]");
			pc++;
			per = 5;
			break;
		case 0xF5:
			sbc(peek(am_zx));
			if (ver > 1) printf("[SBCzx]");
			pc++;
			per = 4;
			break;
		case 0xFD:
			sbc(peek(am_ax));
			if (ver > 1) printf("[SBCx]");
			pc += 2;
			per = 4;
			break;
		case 0xF9:
			sbc(peek(am_ay));
			if (ver > 1) printf("[SBCy]");
			pc += 2;
			per = 4;
			break;
		case 0xF2:			// CMOS only
			sbc(peek(am_iz));
			if (ver > 1) printf("[SBC(z)]");
			pc++;
			per = 5;
			break;
		case 0x38:						// *** SEC: Set Carry Flag ***
			p |= 0x01;
			if (ver > 1) printf("[SEC]");
			break;
		case 0xF8:						// *** SEC: Set Decimal Mode ***
			p |= 0x08;
			if (ver > 1) printf("[SED]");
			break;
		case 0x78:						// *** SEI: Set Interrupt Disable Status ***
			p |= 0x04;
			if (ver > 1) printf("[SEI]");
			break;
		case 0x8D:						// *** STA: Store Accumulator in Memory ***
			poke(am_a, a);
			if (ver > 1) printf("[STAa]");
			pc += 2;
			per = 4;
			break;
		case 0x85:
			poke(op_l, a);
			if (ver > 1) printf("[STAz]");
			pc++;
			per = 3;
			break;
		case 0x81:
			poke(am_ix, a);
			if (ver > 1) printf("[STA(x)]");
			pc++;
			per = 6;
			break;
		case 0x91:
			poke(am_iy, a);
			if (ver > 1) printf("[STA(y)]");
			pc++;
			per = 6;	// ...and not 5, as expected
			break;
		case 0x95:
			poke(am_zx, a);
			if (ver > 1) printf("[STAzx]");
			pc++;
			per = 4;
			break;
		case 0x9D:
			poke(am_ax, a);
			if (ver > 1) printf("[STAx]");
			pc += 2;
			per = 5;	// ...and not 4, as expected
			break;
		case 0x99:
			poke(am_ay, a);
			if (ver > 1) printf("[STAy]");
			pc += 2;
			per = 5;	// ...and not 4, as expected
			break;
		case 0x92:	// CMOS only
			poke(am_iz, a);
			if (ver > 1) printf("[STA(z)]");
			pc++;
			per = 5;
			break;
		case 0x8E:						// *** STX: Store Index X in Memory ***
			poke(am_a, x);
			if (ver > 1) printf("[STXa]");
			pc += 2;
			per = 4;
			break;
		case 0x86:
			poke(op_l, x);
			if (ver > 1) printf("[STXz]");
			pc++;
			per = 3;
			break;
		case 0x96:
			poke(am_zy, x);
			if (ver > 1) printf("[STXzy]");
			pc++;
			per = 4;
			break;
		case 0x8C:						// *** STY: Store Index Y in Memory ***
			poke(am_a, y);
			if (ver > 1) printf("[STYa]");
			pc += 2;
			per = 4;
			break;
		case 0x84:
			poke(op_l, y);
			if (ver > 1) printf("[STYz]");
			pc++;
			per = 3;
			break;
		case 0x94:
			poke(am_zx, y);
			if (ver > 1) printf("[STYzx]");
			pc++;
			per = 4;
			break;
		case 0x9C:						// CMOS only: *** STZ ***
			poke(am_a, 0);
			if (ver > 1) printf("[STZa]");
			pc += 2;
			per = 4;
			break;
		case 0x64:
			poke(op_l, 0);
			if (ver > 1) printf("[STZz]");
			pc++;
			per = 3;
			break;
		case 0x74:
			poke(am_zx, 0);
			if (ver > 1) printf("[STZzx]");
			pc++;
			per = 4;
			break;
		case 0x9E:
			poke(am_ax, 0);
			if (ver > 1) printf("[STZx]");
			pc += 2;
			per = 5;	// ...y no 4, como sería lógico
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
			temp = peek(am_a);
			temp &= !a;
			poke(am_a, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TRBa]");
			pc += 2;
			per = 6;
			break;
		case 0x14:
			temp = peek(op_l);
			temp &= !a;
			poke(op_l, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TRBz]");
			pc++;
			per = 5;
			break;
		case 0x0C:						// CMOS only: *** TSB ***
			temp = peek(am_a);
			temp |= a;
			poke(am_a, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TSBa]");
			pc += 2;
			per = 6;
			break;
		case 0x04:
			temp = peek(op_l);
			temp |= a;
			poke(op_l, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TSBz]");
				pc++;
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
		default:						// ******** parar CPU ********
			printf("\n*** ($%04X) Illegal opcode $%02X ***\n", pc-1, opcode);
			run = 0;
	}
	if (pc>=65536)
		run = 0;
	
	return per;
}
