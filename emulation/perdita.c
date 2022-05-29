/* Perdita 65C02 Durango-S emulator!
 * (c)2007-2022 Carlos J. Santisteban
 * last modified 20220528-1251
 * */

#include <stdio.h>

/* global variables */
		int mem[65536]		// unified memory map

		int a, x, y, s, p;	// 8-bit registers
		long pc;			// program counter
		int run, ver;		// emulator control
				
/* old hardware methods, just for reference
 * 
		void cargarROM(void);			// eso...
		int peek(long dir);				// acceso memoria
		void poke(long dir, int v);
		void put(int c)		{ term[indi++] = c; }	// puerto serie

		// depuración
		
		void vdu(void);					// ver pantalla
		void serie(void);				// ver lo que salió por ACIA

// *** keep this! ***
		void stat(void)		{ printf("<PC=%d (%p), A=%d, X=%d, Y=%d>\n", pc-1, pc-1, a, x, y); }


		// señales externas
		
		void reset(void);
		void nmi(void);
		void irq(void);
		
		// operaciones internas
		

// *** keep these! ***
		void push(int b)	{ poke(0x100 + s--, b); }
		int pop(void)		{ return peek(++s + 0x100); }


		void rel(int off);
		void bits_nz(int b);
		void lrot_p(int *d);
		void adc(int d);
		void asl(int *d);
		void cmp(int d);
		void lsr(int *d);
		void rol(int *d);
		void ror(int *d);
		void sbc(int d);

		int exec(void);	// ejecuta lo que esté en (PC), devuelve número de períodos
};
*/

/* ******************* startup ******************* */
int main (int argc, char * const argv[]) {
	long t, periodos = 0;
	
	reset();
	
	do
	{
		periodos += exec();	// velocidad emulador: x2.2
		if (periodos >= 10240000)		// t++ cada 6200 son unos 50 Hz
		{
			run = t = 0;
			printf("\nTIMOTEO!! ");
			// irq();
			// vdu();
		}
	} while (run);
	
	printf(" CPU detenida: %d períodos ejecutados\n", periodos);
	stat();		
	vdu();
	serie();
	
    return 0;
}
//***********************************************

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
	ver = 0;					// 0 = nada, 1 = saltos, 2 = auto, 3 = todo 
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
	mem[32768+0x18] = 0x8D; // STA abs
	mem[32768+0x19] = 0xA0; // donde
	mem[32768+0x1A] = 0xDF;
	mem[32768+0x1B] = 0xAA; // TAX
	mem[32768+0x1C] = 0x9D;	// STA abs, X
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

int peek(long dir)
{
	long db, cb, rom, reg6845, mex;
	int d = 0xEA;
	
	db = dir - 16384;
	cb = dir - 32768;
	rom = dir - 49152;
	
	mex = rom - 0x1F80;
	
	if (dir>=0 && dir<16384)				// RAM estática 16 KB
		d = mem[dir];
	
	if (db>=0 && db<16384)					// dBank
	{
		if (pia1[0] == 0 && pia1[1] == 32)	// bloque $20 => VRAM
			if (db < 2048)
				d = vram[db];
		if (pia1[0] < 2 && pia1[1] == 0)	// bloque $00, bancos 0...1 => 32K RAM expandida
			d = mem_exp[db + 16384 * pia1[0]];
	}

	if (cb>=0 && cb<16384)					// cBank
	{
		if (pia2[0] == 0 && pia2[1] == 47)	// bloque $2F => control VDU
		{
			d = vdu_ctl[cb];
			if (cb == 16383)				// lectura regsitro CRTC
			{
				reg6845 = vdu_ctl[16382];
				d = crtc[reg6845];
			}
		}
		if (pia2[0] < 2 && pia2[1] == 0)	// bloque $00, bancos 0...1 => 32K RAM expandida
			d = mem_exp[cb + 16384 * pia2[0]];
	}
	
	if (rom>=0 && rom<16384)	// EPROM
	{
		d = mem[32768+rom];
		if (mex >= 0 && mex < 128)		// área E/S
		{
			if (mex < 16)				// VIA 6522
				d = via[mex];
			if (mex >= 32 && mex < 36)	// ACIA 6551
			{
				d = acia[mex - 32];
				if (mex == 32)		acia[1] &= 0xF7;	// listo para recibir otra vez...
			}
			if (mex >= 64 && mex < 68)	// PIA 6821 (A)
				d = pia1[mex - 64];
			if (mex >= 80 && mex < 84)	// PIA 6821 (B)
				d = pia1[mex - 80];
		}
	}
	
	return d;
}

void poke(long dir, int v)
{
	long db, cb, reg6845, mex;
	
	db = dir - 16384;
	cb = dir - 32768;
	mex = dir - 0xDF80;
	
	if (dir>=0 && dir<16384)
		mem[dir] = v;
	
	if (db>=0 && db<16384)					// dBank
	{
		if (pia1[0] == 0 && pia1[1] == 32)	// bloque $20 => VRAM
			if (db < 2048)
			{
				vram[db] = v;
				if (ver > 1)	printf("(%c)", v);		// enviado a la VRAM
			}
		if (pia1[0] < 2 && pia1[1] == 0)	// bloque $00, bancos 0...1 => 32K RAM expandida
			mem_exp[db + 16384 * pia1[0]] = v;

	}
	

	if (cb>=0 && cb<16384)					// cBank
	{
		if (pia2[0] == 0 && pia2[1] == 47)	// bloque $2F => control VDU
		{
			if (cb == 16383)				// escritura registro CRTC
			{
				reg6845 = vdu_ctl[16382];
				crtc[reg6845] = v;
			}
			else	vdu_ctl[cb] = v;
		}
		if (pia2[0] < 2 && pia2[1] == 0)	// bloque $00, bancos 0...1 => 32K RAM expandida
			mem_exp[cb + 16384 * pia2[0]] = v;

	}
	
	if (mex >= 0 && mex < 128)		// área E/S
	{
		if (mex < 16)				// VIA 6522
			via[mex] = v;
		if (mex >= 32 && mex < 36)	// ACIA 6551
		{
			if (mex == 33)		// RESET
			{
				acia[1] = 0x10;
				acia[0] = acia [2] = acia[3] = 0;
			}
			else	acia[mex - 32] = v;
			if (mex == 32)
			{
				put(v);				// sale por ACIA
				if (ver > 1)	printf("{%c}", v);
				acia[1] |= 0x10;	// libre otra vez
			}
			
		}
		if (mex >= 64 && mex < 68)	// PIA 6821 (A) *** controlar registros internos...
			pia1[mex - 64] = v;
		if (mex >= 80 && mex < 84)	// PIA 6821 (B) *** controlar registros internos...
			pia2[mex - 80] = v;
	}
}

void reset(void)
{
	int i;
	
	a &= 0xFF;		// sólo 8 bits
	x &= 0xFF;
	y &= 0xFF;
	s &= 0xFF;
	
	pc = peek(0xfffc) + 256*peek(0xfffd);	// vector RESET
	
	printf(" RESET: PC=%d (%p)\n", pc, pc);
	
	p &= 0xF7;		// CLD en 65C02
	p |= 0x20;		// siempre a 1
	
	for (i = 0; i < 17; i++)	crtc[i] = 0;
	for (i = 0; i < 16; i++)	via[i] = 0;
	for (i = 0; i < 4; i++)		acia[i] = 0;
	acia[1] = 0x10;	// libre pa transmitir
	
/*	pia1[0] = 0;	// *** para que funcione el miniDock ***
	pia1[1] = 32;
	pia2[0] = 0;	// *** para que funcione el miniDock ***
	pia2[1] = 47;
	for (i = 2; i < 4; i++)		pia1[i] = pia2[i] = 0;
*/	
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
	int opcode, b1, b2, temp, per = 2;
	long abs, ix, iy, zx, zy, ax, ay;
	long ai, aix, iz; 
	
	opcode = peek(pc++);
	
	b1 = peek(pc);
	b2 = peek(pc + 1);
	
	abs = b1 + 256*b2;
	ix = peek(b1 + x) + 256*peek(b1 + x + 1);
	iy = peek(b1) + 256*peek(b1 + 1) + y;
	zx = b1 + x;
	zy = b1 + y;
	ax = abs + x;
	ay = abs + y;
	ai = peek(abs) + 256*peek(abs + 1);
	aix = peek(abs + x) + 256*peek(abs + x + 1);
	iz = iy - y;
	
	switch(opcode)
	{
		case 0x69:						// *** ADC: Add Memory to Accumulator with Carry ***
			adc(b1);
			if (ver > 1) printf("[ADC#]");
			pc++;
			break;
		case 0x6D:
			adc(peek(abs));
			if (ver > 1) printf("[ADCa]");
			pc += 2;
			per = 4;
			break;
		case 0x65:
			adc(peek(b1));
			if (ver > 1) printf("[ADCz]");
			pc++;
			per = 3;
			break;
		case 0x61:
			adc(peek(ix));
			if (ver > 1) printf("[ADC(x)]");
			pc++;
			per = 6;
			break;
		case 0x71:
			adc(peek(iy));
			if (ver > 1) printf("[ADC(y)]");
			pc++;
			per = 5;
			break;
		case 0x75:
			adc(peek(zx));
			if (ver > 1) printf("[ADCzx]");
			pc++;
			per = 4;
			break;
		case 0x7D:
			adc(peek(ax));
			if (ver > 1) printf("[ADCx]");
			pc += 2;
			per = 4;
			break;
		case 0x79:
			adc(peek(ay));
			if (ver > 1) printf("[ADCy]");
			pc += 2;
			per = 4;
			break;
		case 0x72:	// exclusiva CMOS
			adc(peek(iz));
			if (ver > 1) printf("[ADC(z)]");
				pc++;
			per = 5;
			break;
		case 0x29:						// *** AND: "And" Memory with Accumulator ***
			a &= b1;
			bits_nz(a);
			if (ver > 1) printf("[AND#]");
			pc++;
			break;
		case 0x2D:
			a &= peek(abs);
			bits_nz(a);
			if (ver > 1) printf("[ANDa]");
			pc += 2;
			per = 4;
			break;
		case 0x25:
			a &= peek(b1);
			bits_nz(a);
			if (ver > 1) printf("[ANDz]");
			pc++;
			per = 3;
			break;
		case 0x21:
			a &= peek(ix);
			bits_nz(a);
			if (ver > 1) printf("[AND(x)]");
			pc++;
			per = 6;
			break;
		case 0x31:
			a &= peek(iy);
			bits_nz(a);
			if (ver > 1) printf("[AND(y)]");
			pc++;
			per = 5;
			break;
		case 0x35:
			a &= peek(zx);
			bits_nz(a);
			if (ver > 1) printf("[ANDzx]");
			pc++;
			per = 4;
			break;
		case 0x3D:
			a &= peek(ax);
			bits_nz(a);
			if (ver > 1) printf("[ANDx]");
			pc += 2;
			per = 4;
			break;
		case 0x39:
			a &= peek(ay);
			bits_nz(a);
			if (ver > 1) printf("[ANDy]");
			pc += 2;
			per = 4;
			break;
		case 0x32:	// exclusiva CMOS
			a &= peek(iz);
			bits_nz(a);
			if (ver > 1) printf("[AND(z)]");
				pc++;
			per = 5;
			break;
		case 0x0E:						// *** ASL: Shift Left one Bit (Memory or Accumulator) ***
			temp = peek(abs);
			asl(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[ASLa]");
			pc += 2;
			per = 6;
			break;
		case 0x06:
			temp = peek(b1);
			asl(&temp);
			poke(b1, temp);
			if (ver > 1) printf("[ASLz]");
			pc++;
			per = 5;
			break;
		case 0x0A:
			asl(&a);
			if (ver > 1) printf("[ASL]");
			break;
		case 0x16:
			temp = peek(zx);
			asl(&temp);
			poke(zx, temp);
			if (ver > 1) printf("[ASLzx]");
			pc++;
			per = 6;
			break;
		case 0x1E:
			temp = peek(ax);
			asl(&temp);
			poke(ax, temp);
			if (ver > 1) printf("[ASLx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
			break;
		case 0x90:						// *** BCC: Branch on Carry Clear ***
			pc++;
			if(!(p & 0x01))
			{
				rel(b1);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BCC]");
			break;
		case 0xB0:						// *** BCS: Branch on Carry Set ***
			pc++;
			if(p & 0x01)
			{
				rel(b1);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BCS]");
			break;
		case 0xF0:						// *** BEQ: Branch on Result Zero ***
			pc++;
			if(p & 0x02)
			{
				rel(b1);
				per = 3;
			}				
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BEQ]");
			break;
		case 0x2C:						// *** BIT: Test Bits in Memory with Accumulator (?) ***
			temp = peek(abs);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** acabar el bit ***
			printf("[BITa]");
			pc += 2;
			per = 4;
			break;
		case 0x24:
			temp = peek(b1);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** acabar el bit ***
			printf("[BITz]");
			pc++;
			per = 3;
			break;
		case 0x89:	// exclusiva CMOS
			temp = b1;
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** acabar el bit ***
			printf("[BIT#]");
			pc++;
			break;
		case 0x3C:	// exclusiva CMOS
			temp = peek(ax);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
// *** acabar el bit ***
			printf("[BITx]");
			pc += 2;
			per = 4;
			break;
		case 0x34:	// exclusiva CMOS
			temp = peek(zx);
			if (temp & 0x80)
				p |= 0x80;
			else
				p &= 0x7F;
			if (temp & 0x40)
				p |= 0x40;
			else
				p &= 0xBF;
			// *** acabar el bit ***
			printf("[BITzx]");
			pc++;
			per = 4;
			break;
		case 0x30:						// *** BMI: Branch on Result Minus ***
			pc++;
			if(p & 0x80)
			{
				rel(b1);
				per = 3;
			}		
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BMI]");
			break;
		case 0xD0:						// *** BNE: Branch on Result Not Zero ***
			pc++;
			if(!(p & 0x02))
			{
				rel(b1);
				per = 3;
			}				
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BNE]");
			break;
		case 0x10:						// *** BPL: Branch on Result Plus ***
			pc++;
			if(!(p & 0x80))
			{
				rel(b1);
				per = 3;
			}			
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BPL]");
			break;
		case 0x80:						// exclusiva CMOS: *** BRA ***
			pc++;
			rel(b1);
			per = 3;
			if (ver > 1) printf("[BRA]");
			break;
		case 0x00:						// *** BRK: Force Break ***
			printf("[BRK]");
// **** hacerla ****
			run = 0;
// ¿qué pasa con PC?
			per = 7;
			break;
		case 0x50:						// *** BVC: Branch on Overflow Clear ***
			pc++;
			if(!(p & 0x40))
			{
				rel(b1);
				per = 3;
			}
			else if (ver == 1)	ver = 2;
			if (ver > 1) printf("[BVC]");
			break;
		case 0x70:						// *** BVC: Branch on Overflow Set ***
			pc++;
			if(p & 0x40)
			{
				rel(b1);
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
			cmp(a - b1);
			if (ver > 1) printf("[CMP#]");
			pc++;
			break;
		case 0xCD:
			temp = peek(abs);
			cmp(a - temp);
			if (ver > 1) printf("[CMPa]");
			pc += 2;
			per = 4;
			break;
		case 0xC5:
			temp = peek(b1);
			cmp(a - temp);
			if (ver > 1) printf("[CMPz]");
			per = 3;
			pc++;
			break;
		case 0xC1:
			temp = peek(ix);
			cmp(a - temp);
			if (ver > 1) printf("[CMP(x)]");
			pc++;
			per = 6;
			break;
		case 0xD1:
			temp = peek(iy);
			cmp(a - temp);
			if (ver > 1) printf("[CMP(y)]");
			pc++;
			per = 5;
			break;
		case 0xD5:
			temp = peek(zx);
			cmp(a - temp);
			if (ver > 1) printf("[CMPzx]");
			pc++;
			per = 4;
			break;
		case 0xDD:
			temp = peek(ax);
			cmp(a - temp);
			if (ver > 1) printf("[CMPx]");
			pc += 2;
			per = 4;
			break;
		case 0xD9:
			temp = peek(ay);
			cmp(a - temp);
			if (ver > 1) printf("[CMPy]");
			pc += 2;
			per = 4;
			break;
		case 0xD2:	// exclusiva CMOS
			temp = peek(iz);
			cmp(a - temp);
			if (ver > 1) printf("[CMP(z)]");
			pc++;
			per = 5;
			break;
		case 0xE0:						// *** CPX: Compare Memory And Index X ***			¿¿¿ o al revés ???
			cmp(x - b1);
			if (ver > 1) printf("[CPX#]");
			pc++;
			break;
		case 0xEC:
			temp = peek(abs);
			cmp(x - temp);
			if (ver > 1) printf("[CPXa]");
			pc += 2;
			per = 4;
			break;
		case 0xE4:
			temp = peek(b1);
			cmp(x - temp);
			if (ver > 1) printf("[CPXz]");
			pc++;
			per = 3;
			break;
		case 0xC0:						// *** CPY: Compare Memory And Index Y ***				¿¿¿ o al revés ???
			cmp(y - b1);
			if (ver > 1) printf("[CPY#]");
			pc++;
			break;
		case 0xCC:
			temp = peek(abs);
			cmp(y - temp);
			if (ver > 1) printf("[CPYa]");
			pc += 2;
			per = 4;
			break;
		case 0xC4:
			temp = peek(b1);
			cmp(y - temp);
			if (ver > 1) printf("[CPYz]");
			pc++;
			per = 3;
			break;
		case 0xCE:						// *** DEC: Decrement Memory (or Accumulator) by One ***
			temp = peek(abs);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(abs, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECa]");
			pc += 2;
			per = 6;
			break;
		case 0xC6:
			temp = peek(b1);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(b1, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECz]");
			pc++;
			per = 5;
			break;
		case 0xD6:
			temp = peek(zx);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(zx, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECzx]");
			pc += 2;
			per = 6;
			break;
		case 0xDE:
			temp = peek(ax);
			temp--;
			if (temp == -1)
				temp = 255;
			poke(ax, temp);
			bits_nz(temp);
			if (ver > 1) printf("[DECx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
			break;
		case 0x3A:	// exclusiva CMOS
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
			a ^= b1;
			bits_nz(a);
			if (ver > 1) printf("[EOR#]");
			pc++;
			break;
		case 0x4D:
			a ^= peek(abs);
			bits_nz(a);
			if (ver > 1) printf("[EORa]");
			pc += 2;
			per = 4;
			break;
		case 0x45:
			a ^= peek(b1);
			bits_nz(a);
			if (ver > 1) printf("[EORz]");
			pc++;
			per = 3;
			break;
		case 0x41:
			a ^= peek(ix);
			bits_nz(a);
			if (ver > 1) printf("[EOR(x)]");
			pc++;
			per = 6;
			break;
		case 0x51:
			a ^= peek(iy);
			bits_nz(a);
			if (ver > 1) printf("[EOR(y)]");
			pc++;
			per = 5;
			break;
		case 0x55:
			a ^= peek(zx);
			bits_nz(a);
			if (ver > 1) printf("[EORzx]");
			pc++;
			per = 4;
			break;
		case 0x5D:
			a ^= peek(ax);
			bits_nz(a);
			if (ver > 1) printf("[EORx]");
			pc += 2;
			per = 4;
			break;
		case 0x59:
			a ^= peek(ay);
			bits_nz(a);
			if (ver > 1) printf("[EORy]");
			pc += 2;
			per = 4;
			break;
		case 0x52:	// exclusiva CMOS
			a ^= peek(iz);
			bits_nz(a);
			if (ver > 1) printf("[EOR(z)]");
				pc++;
			per = 5;
			break;
		case 0xEE:						// *** INC: Increment Memory (or Accumulator) by One ***
			temp = peek(abs);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(abs, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCa]");
			pc += 2;
			per = 6;
			break;
		case 0xE6:
			temp = peek(b1);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(b1, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCz]");
			pc++;
			per = 5;
			break;
		case 0xF6:
			temp = peek(zx);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(zx, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCzx]");
			pc++;
			per = 6;
			break;
		case 0xFE:
			temp = peek(ax);
			temp++;
			if (temp == 256)
				temp = 0;
			poke(ax, temp);
			bits_nz(temp);
			if (ver > 1) printf("[INCx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
			break;
		case 0x1A:	// exclusiva CMOS
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
			pc = abs;
			if (ver)	printf("[JMP]");
			per = 3;
			break;
		case 0x6C:
			pc = ai;
			if (ver)	printf("[JMP*]");
			per = 6;	// ¿¿¿ 5 en el 6502 NMOS ???
			break;
		case 0x7C:	// exclusiva CMOS
			pc = aix;
			if (ver)	printf("[JMP(x)]");
			per = 6;
			break;
		case 0x20:						// *** JSR: Jump to New Location Saving Return Address ***
			pc++;						// se queda en el MSB
			b1 = pc % 256;
			b2 = pc / 256;
			push(b2);
			push(b1);
			pc = abs;
			if (ver)	printf("[JSR]");
			per = 6;
			break;
		case 0xA9:						// *** LDA: Load Accumulator with Memory ***
			a = b1;
			bits_nz(a);
			if (ver > 1) printf("[LDA#]");
			pc++;
			break;
		case 0xAD:
			a = peek(abs);
			bits_nz(a);
			if (ver > 1) printf("[LDAa]");
			pc += 2;
			per = 4;
			break;
		case 0xA5:
			a = peek(b1);
			bits_nz(a);
			if (ver > 1) printf("[LDAz]");
			pc++;
			per = 3;
			break;
		case 0xA1:
			a = peek(ix);
			bits_nz(a);
			if (ver > 1) printf("[LDA(x)]");
			pc++;
			per = 6;
			break;
		case 0xB1:
			a = peek(iy);
			bits_nz(a);
			if (ver > 1) printf("[LDA(y)]");
			pc++;
			per = 5;
			break;
		case 0xB5:
			a = peek(zx);
			bits_nz(a);
			if (ver > 1) printf("[LDAzx]");
			pc++;
			per = 4;
			break;
		case 0xBD:
			a = peek(ax);
			bits_nz(a);
			if (ver > 1) printf("[LDAx]");
			pc += 2;
			per = 4;
			break;
		case 0xB9:
			a = peek(ay);
			bits_nz(a);
			if (ver > 1) printf("[LDAy]");
			pc += 2;
			per = 4;
			break;
		case 0xB2:	// exclusiva CMOS
			a = peek(iz);
			bits_nz(a);
			if (ver > 1) printf("[LDA(z)]");
			pc++;
			per = 5;
			break;
		case 0xA2:						// *** LDX: Load Index X with Memory ***
			x = b1;
			bits_nz(x);
			if (ver > 1) printf("[LDX#]");
			pc++;
			break;
		case 0xAE:
			x = peek(abs);
			bits_nz(x);
			if (ver > 1) printf("[LDXa]");
			pc += 2;
			per = 4;
			break;
		case 0xA6:
			x = peek(b1);
			bits_nz(x);
			if (ver > 1) printf("[LDXz]");
			pc++;
			per = 3;
			break;
		case 0xB6:
			x = peek(zy);
			bits_nz(x);
			if (ver > 1) printf("[LDXzy]");
			pc++;
			per = 4;
			break;
		case 0xBE:
			x = peek(ay);
			bits_nz(x);
			if (ver > 1) printf("[LDXy]");
			pc += 2;
			per = 4;
			break;
		case 0xA0:						// *** LDY: Load Index Y with Memory ***
			y = b1;
			bits_nz(y);
			if (ver > 1) printf("[LDY#]");
			pc++;
			break;
		case 0xAC:
			y = peek(abs);
			bits_nz(y);
			if (ver > 1) printf("[LDYa]");
			pc += 2;
			per = 4;
			break;
		case 0xA4:
			y = peek(b1);
			bits_nz(y);
			if (ver > 1) printf("[LDYz]");
			pc++;
			per = 3;
			break;
		case 0xB4:
			y = peek(zx);
			bits_nz(y);
			if (ver > 1) printf("[LDYzx]");
			pc++;
			per = 4;
			break;
		case 0xBC:
			y = peek(ax);
			bits_nz(y);
			if (ver > 1) printf("[LDYx]");
			pc += 2;
			per = 4;
			break;
		case 0x4E:						// *** LSR: Shift One Bit Right (Memory or Accumulator) ***
			temp = peek(abs);
			lsr(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[LSRa]");
			pc += 2;
			per = 6;
			break;
		case 0x46:
			temp = peek(b1);
			lsr(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[LSRz]");
			pc++;
			per = 5;
			break;
		case 0x4A:
			lsr(&a);
			printf("[LSR]");
			break;
		case 0x56:
			temp = peek(zx);
			lsr(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[LSRzx]");
			pc++;
			per = 6;
			break;
		case 0x5E:
			temp = peek(ax);
			lsr(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[LSRx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
			break;
		case 0xEA:						// *** NOP: No Operation ***
			if (ver) printf("[NOP]");
			break;
		case 0x09:						// *** ORA: "Or" Memory with Accumulator ***
			a |= b1;
			bits_nz(a);
			if (ver > 1) printf("[ORA#]");
			pc++;
			break;
		case 0x0D:
			a |= peek(abs);
			bits_nz(a);
			if (ver > 1) printf("[ORAa]");
			pc += 2;
			per = 4;
			break;
		case 0x05:
			a |= peek(b1);
			bits_nz(a);
			if (ver > 1) printf("[ORAz]");
			pc++;
			per = 3;
			break;
		case 0x01:
			a |= peek(ix);
			bits_nz(a);
			if (ver > 1) printf("[ORA(x)]");
			pc++;
			per = 6;
			break;
		case 0x11:
			a |= peek(iy);
			bits_nz(a);
			if (ver > 1) printf("[ORA(y)]");
			pc++;
			per = 5;
			break;
		case 0x15:
			a |= peek(zx);
			bits_nz(a);
			if (ver > 1) printf("[ORAzx]");
			pc++;
			per = 4;
			break;
		case 0x1D:
			a |= peek(ax);
			bits_nz(a);
			if (ver > 1) printf("[ORAx]");
			pc += 2;
			per = 4;
			break;
		case 0x19:
			a |= peek(ay);
			bits_nz(a);
			if (ver > 1) printf("[ORAy]");
			pc += 2;
			per = 4;
			break;
		case 0x12:	// exclusiva CMOS
			a |= peek(iz);
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
		case 0xDA:						// exclusiva CMOS: *** PHX ***
			push(x);
			if (ver > 1) printf("[PHX]");
			per = 3;
			break;
		case 0x5A:						// exclusiva CMOS: *** PHY ***
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
		case 0xFA:						// exclusiva CMOS: *** PLX ***
			x = pop();
			if (ver > 1) printf("[PLX]");
			per = 4;
			break;
		case 0x7A:						// exclusiva CMOS: *** PLY ***
			y = pop();
			if (ver > 1) printf("[PLY]");
			per = 4;
			break;
		case 0x2E:						// *** ROL: Rotate One Bit Left (Memory or Accumulator) ***
			temp = peek(abs);
			rol(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[ROLa]");
			pc += 2;
			per = 6;
			break;
		case 0x26:
			temp = peek(b1);
			rol(&temp);
			poke(b1, temp);
			if (ver > 1) printf("[ROLz]");
			pc++;
			per = 5;
			break;
		case 0x36:
			temp = peek(zx);
			rol(&temp);
			poke(zx, temp);
			if (ver > 1) printf("[ROLzx]");
			pc++;
			per = 6;
			break;
		case 0x3E:
			temp = peek(ax);
			rol(&temp);
			poke(ax, temp);
			if (ver > 1) printf("[ROLx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
			break;
		case 0x2A:
			rol(&a);
			if (ver > 1) printf("[ROL]");
			pc++;
			break;
		case 0x6E:						// *** ROR: Rotate One Bit Right (Memory or Accumulator) ***
			temp = peek(abs);
			ror(&temp);
			poke(abs, temp);
			if (ver > 1) printf("[RORa]");
			pc += 2;
			per = 6;
			break;
		case 0x66:
			temp = peek(b1);
			ror(&temp);
			poke(b1, temp);
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
			temp = peek(zx);
			ror(&temp);
			poke(zx, temp);
			if (ver > 1) printf("[RORzx]");
			pc++;
			per = 6;
			break;
		case 0x7E:
			temp = peek(ax);
			ror(&temp);
			poke(ax, temp);
			if (ver > 1) printf("[RORx]");
			pc += 2;
			per = 6;	// 7 en el 6502 NMOS
			break;
		case 0x40:						// *** RTI: Return from Interrupt ***
			p = pop();
			b1 = pop();
			b2 = pop();
			pc = b1 + 256*b2 + 1;		// ojo que se quedó en MSB
			if (ver)	printf("[RTI]");
			per = 6;
			break;
		case 0x60:						// *** RTS: Return from Subroutine ***
			b1 = pop();
			b2 = pop();
			pc = b1 + 256*b2 + 1;		// ojo que se quedó en MSB
			if (ver)	printf("[RTS]");
			per = 6;
			break;
		case 0xE9:						// *** SBC: Subtract Memory from Accumulator with Borrow ***
			sbc(b1);
			if (ver > 1) printf("[SBC#]");
			pc++;
			break;
		case 0xED:
			sbc(peek(abs));
			if (ver > 1) printf("[SBCa]");
			pc += 2;
			per = 4;
			break;
		case 0xE5:
			sbc(peek(b1));
			if (ver > 1) printf("[SBCz]");
			pc++;
			per = 3;
			break;
		case 0xE1:
			sbc(peek(ix));
			if (ver > 1) printf("[SBC(x)]");
			pc++;
			per = 6;
			break;
		case 0xF1:
			sbc(peek(iy));
			if (ver > 1) printf("[SBC(y)]");
			pc++;
			per = 5;
			break;
		case 0xF5:
			sbc(peek(zx));
			if (ver > 1) printf("[SBCzx]");
			pc++;
			per = 4;
			break;
		case 0xFD:
			sbc(peek(ax));
			if (ver > 1) printf("[SBCx]");
			pc += 2;
			per = 4;
			break;
		case 0xF9:
			sbc(peek(ay));
			if (ver > 1) printf("[SBCy]");
			pc += 2;
			per = 4;
			break;
		case 0xF2:	// exclusiva CMOS
			sbc(peek(iz));
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
			poke(abs, a);
			if (ver > 1) printf("[STAa]");
			pc += 2;
			per = 4;
			break;
		case 0x85:
			poke(b1, a);
			if (ver > 1) printf("[STAz]");
			pc++;
			per = 3;
			break;
		case 0x81:
			poke(ix, a);
			if (ver > 1) printf("[STA(x)]");
			pc++;
			per = 6;
			break;
		case 0x91:
			poke(iy, a);
			if (ver > 1) printf("[STA(y)]");
			pc++;
			per = 6;	// ...y no 5, como sería lógico
			break;
		case 0x95:
			poke(zx, a);
			if (ver > 1) printf("[STAzx]");
			pc++;
			per = 4;
			break;
		case 0x9D:
			poke(ax, a);
			if (ver > 1) printf("[STAx]");
			pc += 2;
			per = 5;	// ...y no 4, como sería lógico
			break;
		case 0x99:
			poke(ay, a);
			if (ver > 1) printf("[STAy]");
			pc += 2;
			per = 5;	// ...y no 4, como sería lógico
			break;
		case 0x92:	// exclusiva CMOS
			poke(iz, a);
			if (ver > 1) printf("[STA(z)]");
			pc++;
			per = 5;
			break;
		case 0x8E:						// *** STX: Store Index X in Memory ***
			poke(abs, x);
			if (ver > 1) printf("[STXa]");
			pc += 2;
			per = 4;
			break;
		case 0x86:
			poke(b1, x);
			if (ver > 1) printf("[STXz]");
			pc++;
			per = 3;
			break;
		case 0x96:
			poke(zy, x);
			if (ver > 1) printf("[STXzy]");
			pc++;
			per = 4;
			break;
		case 0x8C:						// *** STY: Store Index Y in Memory ***
			poke(abs, y);
			if (ver > 1) printf("[STYa]");
			pc += 2;
			per = 4;
			break;
		case 0x84:
			poke(b1, y);
			if (ver > 1) printf("[STYz]");
			pc++;
			per = 3;
			break;
		case 0x94:
			poke(zx, y);
			if (ver > 1) printf("[STYzx]");
			pc++;
			per = 4;
			break;
		case 0x9C:						// exclusiva CMOS: *** STZ ***
			poke(abs, 0);
			if (ver > 1) printf("[STZa]");
			pc += 2;
			per = 4;
			break;
		case 0x64:
			poke(b1, 0);
			if (ver > 1) printf("[STZz]");
			pc++;
			per = 3;
			break;
		case 0x74:
			poke(zx, 0);
			if (ver > 1) printf("[STZzx]");
			pc++;
			per = 4;
			break;
		case 0x9E:
			poke(ax, 0);
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
		case 0x1C:						// exclusiva CMOS: *** TRB ***
			temp = peek(abs);
			temp &= !a;
			poke(abs, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TRBa]");
			pc += 2;
			per = 6;
			break;
		case 0x14:
			temp = peek(b1);
			temp &= !a;
			poke(b1, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TRBz]");
			pc++;
			per = 5;
			break;
		case 0x0C:						// exclusiva CMOS: *** TSB ***
			temp = peek(abs);
			temp |= a;
			poke(abs, temp);
			if (temp == 0)
				p |= 0x02;
			else
				p &= 0xFD;			
			if (ver > 1) printf("[TSBa]");
			pc += 2;
			per = 6;
			break;
		case 0x04:
			temp = peek(b1);
			temp |= a;
			poke(b1, temp);
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
		case 0xFF:						// ******** muestra estado ********
			printf(" ...estado ");
			stat();
			break;
		default:						// ******** parar CPU ********
			printf("\n*** (%p) opcode ilegal %p ***\n", pc-1, opcode);
			run = 0;
	}
	if (pc>=65536)
		run = 0;
	
	return per;
}
