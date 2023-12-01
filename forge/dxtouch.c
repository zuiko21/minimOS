/* Durango touch utility - CLI version
 * sets file timestamp into header!
 * (C)2023 Carlos J. Santisteban
 * last modified 20231201-1913
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
/* optional libraries for timestamp fetching */
#include	<sys/stat.h>
#include	<unistd.h>
#include	<time.h>
/* ***************************************** */

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

/* Custom types */
typedef	u_int8_t		byte;
typedef	u_int16_t		word;
typedef u_int32_t		dword;

struct	header {
	char	signature[2];	// [1-2]
	word	ld_addr;		// [3-4]
	word	ex_addr;		// [5-6]
	char	name[221];		// [8-]
	char	comment[221];	// name and comment together cannot be over 220 chars (plus both terminators)
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

/* ** main code ** */
int main (int argc, char* argv[]) {
	byte			buffer[HD_BYTES];
	struct header	h;
	FILE*			file;
/* variables for timestamp fetching */
	struct tm*		stamp;
	struct stat		attrib;
/* ******************************** */

	if ((file = fopen(argv[1], "r+b")) == NULL) {
		printf("\n\tFile NOT found\n\n");
		return	-1;
	}
	if (fread(buffer, HD_BYTES, 1, file) != 1) {// get header into buffer
		printf("\n\t*** No header ***\n\n");	// not even space for a header
		fclose(file);
		return	-1;
	}
/* timestamp fetching (don't know if it's portable) */
	stat(argv[1], &attrib);
	stamp = localtime(&(attrib.st_mtime));
	h.year			= stamp->tm_year - 80;		// wtf?
	h.month			= stamp->tm_mon + 1;		// WTF?
	h.day			= stamp->tm_mday;
	h.hour			= stamp->tm_hour;
	h.minute		= stamp->tm_min;
	h.second		= stamp->tm_sec;					// is this OK?
/* ************************************************ */
	printf("%d/%d/%d, %02d:%02d\n", h.year+1980, h.month, h.day, h.hour, h.minute);
	buffer[H_TIME]	=	((h.minute << 5) & 0xFF) | (h.second >> 1);
	buffer[H_TIME+1]=	(h.hour << 3) | (h.minute >> 3);		// coded time
	buffer[H_DATE]	=	((h.month << 5) & 0xFF) | h.day;
	buffer[H_DATE+1]=	(h.year << 1) | (h.month >> 3);			// coded date
	rewind(file);						// back to start, as will modify header
	if (fwrite(buffer, HD_BYTES, 1, file) != 1) {
		printf("\n*** FAIL ***\n\n");
	}
	fclose(file);						// done

	return	0;
}

/* ** Function definitions ** */
/*
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

	return	-1;				// header is valid
}

void	makeheader(byte* p, struct header* h) {		// Generate header from struct
	int		src, dest, skip;
	byte	bits;

	p[H_MAGIC1]			=	0;
	p[H_MAGIC2]			=	13;
	p[H_MAGIC3]			=	0;							// set magic numbers
	p[H_SIGNATURE]		=	h->signature[0];
	p[H_SIGNATURE+1]	=	h->signature[1];			// copy signature
	p[H_LOAD]			=	h->ld_addr & 0xFF;
	p[H_LOAD+1]			=	h->ld_addr >> 8;
	p[H_EXECUTE]		=	h->ex_addr & 0xFF;
	p[H_EXECUTE+1]		=	h->ex_addr >> 8;			// Pocket addresses (unused)
	dest = H_NAME;										// filename offset
	src = 0;
	while (h->name[src])
		p[dest++] = h->name[src++];						// copy filename
	p[dest++] = 0;										// ...and terminator (skipping it)
	src = 0;
	while (h->comment[src])
		p[dest++] = h->comment[src++];					// copy comment
	p[dest++] = 0;										// ...and terminator (skipping it)
	while (dest<H_LIB)		p[dest++] = 0xFF;			// safe padding
//	dest = H_LIB;										// library commit offset
	for (src=0;src<8;src++)	p[dest++] = h->lib[src];	// copy library commit
//	dest = H_COMMIT;									// main commit offset (already there)
	for (src=0;src<8;src++)	p[dest++] = h->commit[src];	// copy main commit afterwards
	switch(h->phase) {
		case 'a':
			bits = 0;		// alpha				%00hhbbbb
			break;
		case 'b':
			bits = 0x40;	// beta					%01hhbbbb
			break;
		case 'R':
			bits = 0x80;	// Release candidate	%10hhbbbb
			break;
		case 'f': 
		default:
			bits = 0xC0;	// final				%11hhbbbb
	}
	p[H_VERSION]	=	bits | (h->revision & 0x30)| h->build;
	p[H_VERSION+1]	=	(h->version << 4) | (h->revision & 0x0F);		// coded version number
	p[H_SIZE]		=	h->size & 0xFF;
	p[H_SIZE+1]		=	(h->size >> 8) & 0xFF;
	p[H_SIZE+2]		=	h->size >> 16;									// coded size
}
*/
