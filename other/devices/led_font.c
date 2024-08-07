/* (c) 2013-2022 Carlos J. Santisteban */
#include <stdio.h>

typedef		unsigned char	byt;

void pintar(byt c);
byt invert(byt c);

int main(void)
{
	byt	font[] = {
	 0x00, 0x61, 0x44, 0x7E, 0xB4, 0x4B, 0x3C, 0x04, 0x9C, 0xF0, 0x6C, 0x62, 0x08, 0x02, 0x01, 0x4A,
	 0xFC, 0x60, 0xDA, 0xF2, 0x66, 0xB6, 0xBE, 0xE0, 0xFE, 0xF6, 0x41, 0x50, 0x18, 0x12, 0x30, 0xCA,
	 0xF8, 0xEE, 0x3E, 0x9C, 0x7A, 0x9E, 0x8E, 0xBC, 0x6E, 0x0C, 0x78, 0x0E, 0x1C, 0xEC, 0x2A, 0xFC,
	 0xCE, 0xFD, 0xDA, 0xB6, 0x1E, 0x38, 0x4E, 0x7C, 0x92, 0x76, 0xD8, 0x9C, 0x26, 0xF0, 0xC0, 0x10,
	 0x40, 0xFA, 0x3E, 0x1A, 0x7A, 0xDE, 0x8E, 0xF6, 0x2E, 0x08, 0x70, 0x0E, 0x1C, 0xEC, 0x2A, 0x3A,
	 0xCE, 0xE6, 0x0A, 0x32, 0x1E, 0x38, 0x4D, 0x7C, 0x92, 0x76, 0xD8, 0x9C, 0x20, 0xF0, 0x80, 0x00 };

	int i;
	
	for (i=32; i<64; i++)
	{
		printf("\n___%c___\n", i);
		pintar(invert(font[i-32]));
	}


	return 0;
}

void pintar(byt c) {
	if (c & 0b00000001)		// top
		printf(" ----");
	printf("\n");
	if (c & 0b00100000)		// top left
		printf("|");
	else
		printf(" ");
	printf("    ");
	if (c & 0b00000010)		// top right
		printf("|");
	printf("\n");
	if (c & 0b01000000)		// middle
		printf(" ----");
	printf("\n");
	if (c & 0b00010000)		// bottom left
		printf("|");
	else
		printf(" ");
	printf("    ");
	if (c & 0b00000100)		// bottom right
		printf("|");
	printf("\n");
	if (c & 0b00001000)		// bottom
		printf(" ----");
	else
		printf("     ");
	if (c & 0b10000000)		// point
		printf(" x");
	printf("\n");
}

byt invert(byt c){
	int i;
	byt r = 0;
	
	for (i=0;i<8;i++)
	{
		r<<=1;
		if (c % 2)	r++;
		c>>=1;
	}
	
	return r;
}
