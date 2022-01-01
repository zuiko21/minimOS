/* (c) 2020-2022 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
	FILE* arch;		// file handler
	int i, siz, op;
	unsigned char m[32000];	// loaded file
	int count[256];		// stats
	int len[256] = {	// opcode lengths
		2,1,0,0,2,2,2,2,1,2,1,0,3,3,3,3,	//0x
		2,2,2,0,2,2,2,2,1,3,1,0,3,3,3,3,	//1x
		3,2,0,0,2,2,2,2,1,2,1,0,3,3,3,3,	//2x
		2,2,2,0,2,2,2,2,1,3,1,0,3,3,3,3,	//3x
		1,2,0,0,0,2,2,2,1,2,1,0,3,3,3,3,	//4x
		2,2,2,0,0,2,2,2,1,3,1,0,0,3,3,3,	//5x
		1,2,0,0,2,2,2,2,1,2,1,0,3,3,3,3,	//6x
		2,2,2,0,2,2,2,2,1,3,1,0,3,3,3,3,	//7x
		2,2,0,0,2,2,2,2,1,2,1,0,3,3,3,3,	//8x
		2,2,2,0,2,2,2,2,1,3,1,0,3,3,3,3,	//9x
		2,2,2,0,2,2,2,2,1,2,1,0,3,3,3,3,	//Ax
		2,2,2,0,2,2,2,2,1,3,1,0,3,3,3,3,	//Bx
		2,2,0,0,2,2,2,2,1,2,1,1,3,3,3,3,	//Cx
		2,2,2,0,0,2,2,2,1,3,1,1,0,3,3,3,	//Dx
		2,2,0,0,2,2,2,2,1,2,1,0,3,3,3,3,	//Ex
		2,2,2,0,0,2,2,2,1,3,1,0,0,3,3,3,	//Fx
	};
// init stuff
	for (i=0; i<256; i++)
		count[i] = 0;
printf("Init OK\n");
// load the file
	arch = fopen("a.o65", "rb");
printf("reading... ");
	for(i=0; (op=fgetc(arch)) != EOF; i++)
		m[i] = op;
	siz = i;
	fclose(arch);
printf("%d bytes\n", siz);

//for (i=0;i<100;i++) printf("%d[%d],",m[i],len[m[i]]);
printf("\n");
// compute instruction use
	i = 0;			// reset index
	do {
		op = m[i];	// read opcode
		count[op]++;	// update stats
//printf("%d(%d),",op,len[op]);
		i += len[op];	// advance to next opcode
	} while ((len[op] > 0) && (i < siz));
	printf("%d bytes processed\n", i);
// show results
	for (i=0; i<256; i++) {
		printf("Opcode %d: %d\n", i, count[i]);
	}

	return 0;
}
