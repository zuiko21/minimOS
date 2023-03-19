/* ROM signer with Fletcher-16 checksum *
 * (c) 2021-2023 Carlos J. Santisteban  *
 * last modified 20230319-2241          */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
	int rom[32768];				/* maximum ROM size */
	int sum, check;				/* computed sums    */
	int sig_s, sig_c;			/* signature values at $FFDE-$FFDF (in 6502 space) */
	int size;					/* ROM size         */
	int skip;					/* I/O page to be skipped                          */
	int offset;					/* position of signature (default $7FD4 for 32K)   */
	int target;					/* preliminary sum */
	int i, j;
	FILE* f;

	if (argc == 1) {			/* no arguments, asking for help */
		printf("Fletcher-16 signer for minimOS ROM files\n");
		printf("USAGE: %s file [skip [offset]]\n", argv[0]);
		printf("\tfile   = filename (duh), max. 32 kiB\n");
		printf("\tskip   = I/O page to skip (usually 223, $DF)\n");
		printf("\toffset = negative position of signature (default: 44, $FFD4 in 6502 space)\n");
		return -1;				/* did nothing */
	}

/* open file and load it into array */
	f=fopen(argv[1],"rb+");		/* read/write file */
	if (f==NULL) {
		printf("\n*** NO FILE! ***\n\n");
		return -2;				/* no such file    */
	}
	fseek(f, 0, SEEK_END);		/* go to the end   */
	size=ftell(f);				/* compute size    */
	fseek(f, 0, SEEK_SET);		/* back to start   */
	if (size>32768) {
		printf("\n*** File too large ***\n\n");
		fclose(f);
		return -3;				/* too large       */
	}
	printf("ROM size: %d ($%04X) bytes\n", size, size);
	target=0;
	for (i=0; i<size; i++) {
		rom[i]=fgetc(f);		/* get contents    */
		target += rom[i];		/* preliminary sum */
	}
	if (argc>3) {
		offset = size-atoi(argv[3]);
		printf("Signature at $%04X on image\n", offset);
	} else {
		offset=size-44;			/* default offset  */
		if (offset<0) {
			printf("\n*** Won't allow default offset ***\n\n");
			fclose(f);
			return -4;			/* wrong offset    */
		}
	}
	if (argc>2) {
		skip = atoi(argv[2]);	/* I/O page to skip */
		printf("I/O page: $%02X\n", skip);
	} else {
		skip = 256;				/* impossible value */
		printf("DOWNLOADABLE ROM, no page skipped\n");
	}
	skip = size-((256-skip)<<8);	/* convert page into offset */
	target -= rom[offset];		/* subtract reserved values */
	target -= rom[offset+1];
	target &= 255;
	target = 256-target;		/* expected sum    */
	printf("Original signature: $%02X%02X\n", rom[offset], rom[offset+1]);
	rom[offset]		=0;
	rom[offset+1]	=0;			/* clear them too  */

	check=sum=0;				/* precheck values */
/*	for(i=0;i<size;i++) {
		sum += rom[i];
		sum &= 255;
		check += sum;
		check &= 255;
	}
	printf("ORIGINAL: %d, %d ($%02x%02x)\n", sum, check, check, sum);*/
	printf("TARGET: %d\n", target);

	check = 256;
	j=0;
	while (j<256 && check!=0) {
		rom[offset]=j;					/* preload candidates */
		rom[offset+1]=(target-j) & 255;	/* as defined from preliminary sum */
		check=sum=0;
		for(i=0;i<size;i++) {
			if (i==skip)	i+=256;		/* skip I/O page */
			sum += rom[i];
			sum &= 255;
			check += sum;
			check &= 255;
		}
//		if(check==0)	printf("%d.%d: SUM=%d, CHECK=%d\n", j, rom[offset+1], sum, check);
		j++;
	}
	if (check) {
		printf("\n*** No way! Try another offset ***\n\n");
		return -5;
	}
	printf("%d attempts\n", j);
	printf("ROM signature: $%02X%02X\n", rom[offset], rom[offset+1]);
//.......update values in disk
	fseek(f, offset, SEEK_SET);
	fputc(rom[offset],   f);
	fputc(rom[offset+1], f);
	fclose(f);
	printf("Done!\n\n");
	
	return 0;
}
