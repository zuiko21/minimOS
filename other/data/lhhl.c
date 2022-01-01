/* LHHL test file creator             */
/* full 64K, trim as needed           */
/* (C)2021-2022 Carlos J. Santisteban */
/* last modified 20210902-2305        */

#include <stdio.h>

int main(void) {
	FILE*	f;
	long	i;				/* at least 16-bit unsigned */
	char	l, h;
	
	f=fopen("lhhl.bin", "wb");
	
	for (i=0; i<65536; i+=4) {
		l=i & 255;
		h=i >> 8;
		putc(l, f);
		putc(h, f);
		putc(h, f);
		putc(l+3, f);
	}

	fclose(f);
	
	return 0;
}
