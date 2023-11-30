/* Durango file information - CLI version
 * (C)2023 Carlos J. Santisteban
 * last modified 20231130-1900
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>

/* Constants */
// bytes per header/page
#define		HD_BYTES	256
// Header offsets
#define		H_MAGIC1	0
#define		H_SIGNATURE	1
#define		H_LOAD		3
#define		H_EXECUTE	5
#define		H_MAGIC2	7
#define		H_NAME		8
#define		H_LIB		230
#define		H_COMMIT	238
#define		H_VERSION	246
#define		H_TIME		248
#define		H_DATE		250
#define		H_SIZE		252
#define		H_MAGIC3	255
// Signature types
#define		SIG_UNKN	0
#define		SIG_FREE	1
#define		SIG_ROM		2
#define		SIG_POCKET	3
#define		SIG_FILE	4
#define		SIG_HIRES	5
#define		SIG_COLOUR	6
#define		SIG_H_RLE	7
#define		SIG_C_RLE	8

/* Custom types */
typedef	u_int8_t		byte;
typedef	u_int16_t		word;
typedef u_int32_t		dword;

struct	header {
	char	signature[2];	// [1-2]
	word	ld_addr;		// [3-4]
	word	ex_addr;		// [5-6]
	char	name[220];		// [8-]
	char	comment[220];	// name and comment together cannot be over 220 chars
	char	lib[8];			// [230-237]
	char	commit[8];		// [238-245]
	byte	version;		// [246-247]
	byte	revision;
	char	phase;			// (a)lpha-(b)eta-(R)elease candidate-(f)inal
	byte	build;
	byte	hour;			// [248-249]
	byte	minute;
	byte	second;
	byte	year;			// [250-251]
	byte	month;
	byte	day;
	dword	size;			// [252-254] bytes including this 256-byte header
};

/* Function prototypes */
int		getheader(byte* p, struct header* h);		// Extract header specs, returns 0 if not valid
int		signature(struct header* h);				// Return file type from coded signature
void	info(struct header* h);						// Display info about header

/* ** main code ** */
int main (int argc, char* argv[]) {
	byte			buffer[HD_BYTES];
	struct header	h;
	FILE*			file;

	if ((file = fopen(argv[1], "rb")) == NULL) {
		printf("\n\tFile NOT found\n\n");
		return	-1;
	}
	if (fread(buffer, HD_BYTES, 1, file) != 1) {		// get header into buffer
		printf("\n\t*** No header ***\n\n");			// not even space for a header
		fclose(file);
		return	-1;
	}
	if (getheader(buffer, &h)) {						// check header and get metadata
		info(&h);										// display it
	} else {
		printf("\n\tBad header, probably NOT a Durango file...");
		fseek(file, -256, SEEK_END);
		fread(buffer, HD_BYTES, 1, file);				// try reading the very last page
		if (buffer[0xd6]=='D' && buffer[0xd7]=='m' && buffer[0xd8]=='O' && buffer[0xd9]=='S') {
			printf("\n\t...but SEEMS to be a header-less ROM image");
			if (buffer[0xe1]==0x6c && buffer[0xe2]==0xfc && buffer[0xe3]==0xff) {
				printf(" with devCart support!");
			}
		} 
	}
	printf("\n\n");
	fclose(file);

	return	0;
}

/* ** Function definitions ** */
int		getheader(byte* p, struct header* h) {			// Extract header specs, return 0 if not valid
	static char	phasevec[4] = {'a', 'b', 'R', 'f'};
	int			src, dest;

	if ((p[H_MAGIC1] != 0) || (p[H_MAGIC2] != 13) || (p[H_MAGIC3] != 0))	return	0;	// invalid header
// otherwise extract header data
	h->signature[0] =	p[H_SIGNATURE];
	h->signature[1] =	p[H_SIGNATURE+1];
	h->ld_addr		=	p[H_LOAD] | p[H_LOAD+1]<<8;
	h->ex_addr		=	p[H_EXECUTE] | p[H_EXECUTE+1]<<8;
	src = H_NAME;										// filename offset
	dest = 0;
	while (p[src])		h->name[dest++] = p[src++];		// copy filename
	h->name[dest]	=	p[src];							// and terminator EEEEEK
	src++;												// skip terminator
	dest = 0;
	while (p[src])		h->comment[dest++] = p[src++];	// copy comment
	h->comment[dest]=	p[src];							// and terminator EEEEEK
	src = H_LIB;												// library commit offset
	for (dest=0;dest<8;dest++)		h->lib[dest] = p[src++];	// copy library commit
//	src = H_COMMIT;												// main commit offset (already there)
	for (dest=0;dest<8;dest++)		h->commit[dest] = p[src++];	// copy main commit afterwards
	h->version	=		p[H_VERSION+1]>>4;
	h->revision	=		(p[H_VERSION+1] & 0x0F) | (p[H_VERSION] & 0x30);
	h->phase	=		phasevec[p[H_VERSION]>>6];
	h->build	=		p[H_VERSION] & 0x0F;
	h->hour		=		p[H_TIME+1]>>3;
	h->minute	=		(p[H_TIME+1] & 0x07)<<3 | p[H_TIME]>>5;
	h->second	=		(p[H_TIME] & 0x1F)<<1;
	h->year		=		p[H_DATE+1]>>1;	// add 1980
	h->month	=		(p[H_DATE+1] & 1)<<3 | p[H_DATE]>>5;
	h->day		=		p[H_DATE] & 0x1F;
	h->size		=		p[H_SIZE] | p[H_SIZE+1]<<8 | p[H_SIZE+2]<<16;

	return	-1;				// all OK
}

int		signature(struct header* h) {	// Returns file type from coded signature
	if (h->signature[0] == 'p') {		// pX Pocket executable should be the only possibility so far
		if (h->signature[1] == 'X') {
			return	SIG_POCKET;		// Pocket executable
		} else {
			return	SIG_UNKN;		// otherwise unsupported
		}
	} else if (h->signature[0] == 'd') {						// Standard Durango signature type
		switch (h->signature[1]) {
			case 'X':
				return	SIG_ROM;	// ROM image
			case 'A':
				return	SIG_FILE;	// Generic file
			case 'R':
				return	SIG_HIRES;	// HIRES screen dump
			case 'S':
				return	SIG_COLOUR;	// Colour screen dump
			case 'r':
				return	SIG_H_RLE;	// RLE-compressed HIRES screen dump
			case 's':
				return	SIG_C_RLE;	// RLE-compressed colour screen dump
			case 'L':
				return	SIG_FREE;	// Free space, should never be loaded!
			default:
				return	SIG_UNKN;	// Unsupported signature
		}
	} else return	SIG_UNKN;		// Totally unknown signature
}

void	info(struct header* h) {								// Display info about header
	int		i;

	printf("%s (%-5.2f KiB)", h->name, h->size/1024.0);			// Name and size
	printf("\nType: ");
	switch(signature(h)) {
		case SIG_FREE:		// dL
			printf("* Free space *");							// should never be loaded!
			break;
		case SIG_ROM:		// dX
			printf("ROM image");
			break;
		case SIG_POCKET:	// pX
			printf("Pocket executable [LOAD:$%04X, EXEC:$%04X]", h->ld_addr, h->ex_addr);
			break;
		case SIG_FILE:		// dA
			printf("Generic file");
			break;
		case SIG_HIRES:		// dR
			printf("HIRES screen dump");
			break;
		case SIG_COLOUR:	// dS
			printf("Colour screen dump");
			break;
		case SIG_H_RLE:		// dr
			printf("RLE-compressed HIRES screen dump");
			break;
		case SIG_C_RLE:		// ds
			printf("RLE-compressed colour screen dump");
			break;
		default:
			printf("* UNKNOWN (%c%c) *", h->signature[0], h->signature[1]);
	}
	printf("\nLast modified: %d/%d/%d, %02d:%02d", 1980+h->year, h->month, h->day, h->hour, h->minute);	// Last modified
	if (signature(h) != SIG_FILE) {
		printf(" (v%d.%d%c%d)", h->version, h->revision, h->phase, h->build);	// Version
		printf("\nMain commit ");
		for (i=0; i<8; i++)		printf("%c", h->commit[i]);						// Main commit string
		printf(", Lib commit ");
		for (i=0; i<8; i++)		printf("%c", h->lib[i]);						// Lib commit string
		if (h->comment[0] != '\0')		printf("\nComment: %s", h->comment);	// optional comment
	}
}
