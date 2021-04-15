#include <stdio.h>

int main(void) {
	long s17, bit;
	int  i, a, y;

	s17 = 0x8988;	// seed

	for (i=0; i<260; i++) {
		bit = (s17 & 0x200)>>7;	// bit 9, where bit 2 is
		bit ^= (s17 & 2);	// XOR bit 2
		if (bit)	bit = 0x10000;	// sets bit 16
		s17 |= bit;
		s17 >>= 1;		// right shift
		printf("%X\t", s17);
	}

	return 0;
}

// from: https://meatfighter.com/nintendotetrisai/#Picking_Tetriminos
