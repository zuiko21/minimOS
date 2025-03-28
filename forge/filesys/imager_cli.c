/* Durango Imager - CLI, non-interactive version
 * (C) 2023-2025 Carlos J. Santisteban
 * last modified 20250328-0953
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
// Max number of files into volume
#define		MAXFILES	100
// bytes per header/page
#define		HD_BYTES	256
// Max volume name length
#define		VOL_NLEN	220
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
// Error codes
#define		NO_VOLUME	-1
#define		OUT_MEMORY	-2
#define		EMPTY_VOL	-3
#define		FILE_LIM	-4
#define		NO_FILE		-5
#define		EMPTY_FILE	-6
#define		MISALGINED	-7
#define		BAD_SELECT	-8
#define		NO_CREATE	-9
#define		ABORTED		-10
#define		FREE_ERR	-11

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

/* Global variables */
byte*	ptr[MAXFILES];		// pointer to dynamically stored header (and file)
int		used;				// actual number of files
dword	space;				// free space after contents (in 256-byte pages)
bool	verbose = FALSE;	// flag needed for message display

/* Function prototypes */
void	init(void);								// Init stuff
void	bye(void);								// Clean up
int		open(char* volume);						// Open volume
int		list(char* result);						// List volume contents
int		add(char* name);						// Add file to volume
int		extract(char* name);					// Extract file from volume
int		delete(char* name);						// Delete file from volume
int		setfree(int kb);						// Select free space to be appended
int		generate(char* volume);					// Generate volume
int		getheader(byte* p, struct header* h);	// Extract header specs, returns 0 if not valid
void	makeheader(byte* p, struct header* h);	// Generate header from struct
int		signature(struct header* h);			// Return file type from coded signature
void	info(struct header* h, char* result);	// Display info about header
int		choose(char* name);						// Choose file from list
int		confirm(char* name);					// Request confirmation for dangerous actions, returns ABORTED if rejected
int		empty(void);							// Returns 0 unless it's empty
void	display(int err);						// Display error text

/* ** main code ** */
int main (void) {
	int		err;
	char	name[VOL_NLEN];	// volume and file name storage CHECK SIZE!
	char	cadena[2000];

// if -v
	{
		printf("\nDurango-X volume creator, v1.1a1 by @zuiko21\n");	// return 0;
	}
// if -e
	{
		verbose=TRUE;		// enable extended info -- maybe integrated with -v
	}
	init();					// Init things
// if -i, fetch name, otherwise new volume
	{
strcpy(name, "durango.av\0");
		err = open(name);
		display(err);
	}
// if -l
	{
		list(cadena);
		printf("\n%s\n", cadena);
	}
// for each loose file, fetch name				// add(name);
// if -x, fetch name		// extract(name);
// if -d, fetch name		// delete(name);
// if -f, fetch size		// setfree(size);
// if -o, fetch name, else name='durango.av'
	{
		strcpy(name, "durango.av\0");
	}
	generate(name);
	bye();						// Clean up
	if (verbose)				printf("Bye!\n");

	return	0;
}

/* ** Function definitions ** */
void	init(void) {			// Init stuff
	int		i;

	used =	0;					// empty array, nothing stored in heap
	for (i=0; i<MAXFILES; i++) {
		ptr[i] =	NULL;		// reset all empty pointers
	} 
}

void	bye(void) {				// Release heap memory * * * VERY IMPORTANT * * *
	int		i;

	for (i=0; i<MAXFILES; i++) {
		if (ptr[i] != NULL)		free(ptr[i]);	// release this block-
		ptr[i] =	NULL;		// EEEEEEK
	}
	used = 0;					// all clear
}

int		open(char* volume) {					// Open volume
	FILE*			file;
	byte			buffer[HD_BYTES];			// temporary header fits into a full page
	struct header	h;							// metadata storage

	if (verbose)			printf("Opening %s...", volume);
	if ((file = fopen(volume, "rb")) == NULL) 		return NO_VOLUME;	// ERROR -1: source volume not found
	if (verbose)			printf(" OK\nReading headers...");
//	bye();										// free up dynamic memory
	while (!feof(file)) {
		if (fread(buffer, HD_BYTES, 1, file) != 1)	break;				// get header into buffer
		if (!getheader(buffer, &h)) {									// check header and get metadata
			printf("\n\t* Bad header *\n");
			break;
		}
		if (signature(&h) == SIG_FREE) {
			if (verbose)	printf("\n(Skipping free space)");
			fseek(file, h.size-HD_BYTES, SEEK_CUR);						// just skip free space!
			continue;													// EEEEEEEK
		}
		if (verbose) {
			printf("\nFound %s (%-5.2f KiB): Allocating", h.name, h.size/1024.0);
			printf("[%x]",used);										// entry to be allocated
		}
		if (h.size & 511) {	// uneven size in header, must be rounded up as was padded in volume BEFORE ALLOCATING EEEEEEEEEEEEEEEEKKKKKKKK
			h.size = (h.size + 512) & 0xFFFFFE00;						// sector-aligned size
		}
		if ((ptr[used] = malloc(h.size)) == NULL) {						// Allocate dynamic memory
			fclose(file);												// eeek
			return OUT_MEMORY;											// ERROR -2: out of memory
		}
		if (verbose)		printf(", Header");
		memcpy(ptr[used], buffer, HD_BYTES);							// copy preloaded header
//		for (i=0; i<HD_BYTES; i++)		ptr[used][i] = buffer[i];		// * * * B A D * * * EEEEK
		if (verbose)
			if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf(", Code");
			else																printf(", Data");
		if (fread(ptr[used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {			// read remaining bytes 
			printf("\n*** READ ERROR! ***\n");
			free(ptr[used]);
			ptr[used] = NULL;			// eeeeek
		} else {
			if (verbose)	printf(" OK");
			used++;						// another file into volume
		}
	}
	fclose(file);
	if (verbose)			printf("\n\nDone!\n");

	return	0;
}

int		list(char* result) {			// List volume contents
	int				i;
	struct header	h;

	result[0] = '\0';
	if (empty())	return EMPTY_VOL;	// ERROR -3: empty volume
	for (i=0; i<used; i++) {			// scan thru all stored headers
		if (verbose) {					// maybe use an specific flag?
			getheader(ptr[i], &h);		// get surely loaded header into local storage 
			sprintf(result, "%d: ", i+1);		// entry number (1-based)
			info(&h, result);			// display all info about the file
			sprintf(result, "\n--------\n");
		} else {
			sprintf(result, "%d) %s\n", i+1, ptr[i]+H_NAME);		// display SIMPLIFIED list of contents
		}
	}

	return	0;
}

int		add(char* name) {				// Add file to volume
	FILE*			file;
	byte			buffer[HD_BYTES];	// temporary header fits into a full page
	struct header	h;					// metadata storage
/* optional variables for timestamp fetching */
	struct tm*		stamp;
	struct stat		attrib;
/* ***************************************** */
	if (used >= MAXFILES) {
		return FILE_LIM;								// ERROR -4: no more files allowed
	}
	if (verbose)				printf("Opening %s... ", name);
	if ((file = fopen(name, "rb")) == NULL) {
		return NO_FILE;									// ERROR -5: no file to add
	}
	if (verbose)				printf("OK\nReading header... ");
	if (fread(buffer, HD_BYTES, 1, file) != 1) {		// get header into buffer
		if (!ftell(file)) {								// if it was a generic file, could be shorter than HD_BYTES
			fclose(file);
			return EMPTY_FILE;							// ERROR -6: empty file
		}
	}
	if (!getheader(buffer, &h)) {						// check header and get metadata
		if (verbose)			printf("GENERIC file");
		strcpy(h.name, name);							// place supplied filename
		h.comment[0]	= '\0';							// terminate comment EEEEK
		fseek(file, 0, SEEK_END);
		h.size			= ftell(file) + HD_BYTES;		// check actual file length PLUS new header EEEEEK
		rewind(file);									// after precomputed header, file on disk will be loaded in full
		h.signature[0]	= 'd';
		h.signature[1]	= 'A';							// generic file signature
		h.ld_addr		= 0x2A2A;
		h.ex_addr		= 0x2A2A;						// unused Pocket fields have '****'
		memcpy(h.lib,	"$$$$$$$$", 8);
		memcpy(h.commit,"$$$$$$$$", 8);					// unused commits
		h.version		= 0;
		h.revision		= 0;
		h.phase			= 'a';
		h.build			= 0;							// generic 0.0a0 version
/* timestamp fetching (don't know if it's portable) */
		stat(name, &attrib);
		stamp = localtime(&(attrib.st_mtime));
		h.year			= stamp->tm_year - 80;			// wtf?
		h.month			= stamp->tm_mon + 1;			// WTF?
		h.day			= stamp->tm_mday;
		h.hour			= stamp->tm_hour;
		h.minute		= stamp->tm_min;
		h.second		= stamp->tm_sec;				// is this OK?
/* ************************************************ */
		makeheader(buffer, &h);							// transfer header struct back into buffer
//		h.size -= HD_BYTES;								// eeeek
	}
	if (verbose)				printf("\nAdding %s (%-5.2f KiB): Allocating[%d]", h.name, h.size/1024.0, used);
	if ((ptr[used] = malloc(h.size)) == NULL) {			// Allocate dynamic memory
		fclose(file);
		return OUT_MEMORY;								// out of memory error
	}
	if (verbose)				printf(", Header");
	memcpy(ptr[used], buffer, HD_BYTES);				// copy preloaded header
	if ((signature(&h) == SIG_ROM) && (h.size & 511)) {	// check for misaligned ROM images
		free(ptr[used]);
		ptr[used] = NULL;								// unlikely to be a problem, but...
		fclose(file);
		return MISALGINED;								// ERROR -7: misaligned ROM image
	}
	if (verbose)
		if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf(", Code");
		else																printf(", Data");
	if (fread(ptr[used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {	// read remaining bytes after header (computed or preloaded)
		printf("\n*** READ ERROR! ***\n");
		free(ptr[used]);
		ptr[used] = NULL;				// eeeeek
	} else {
		if (verbose)		printf(" OK\n");
		used++;							// another file into volume
	}
	fclose(file);

	return	0;
}

int		extract(char* name) {			// Extract file from volume
	int				i, ext, skip;
	struct header	h;
	FILE*			file;

	if (empty())		return EMPTY_VOL;						// empty volume error
	ext = choose(name);
	if (ext < 0)		return BAD_SELECT;						// ERROR -8: invalid selection
	getheader(ptr[ext], &h);									// get info for candidate
	info(&h);
	if (signature(&h) == SIG_FILE)		skip = HD_BYTES;		// generic files trim headers
	else								skip = 0;
	if (verbose)		printf("\nWriting to file %s... ", h.name);
	if ((file = fopen(h.name, "wb")) == NULL) {
		return NO_CREATE;										// ERROR -9: can't create file
	}
	if (fwrite(ptr[ext]+skip, h.size-skip, 1, file) != 1) {		// note header removal option
		if (verbose)	printf("\n*** I/O error ***\n");
	} else {
		if (verbose)	printf(" Done!\n");	// finish without padding
	}
	fclose(file);

	return	0;
}

int		delete(char* name) {			// Delete file from volume
	int				i, del;
	struct header	h;

	if (empty())	return EMPTY_VOL;	// empty volume error
	del = choose(name);
	if (del < 0)	return BAD_SELECT;	// invalid selection error
	if (verbose) {
		getheader(ptr[del], &h);		// get info for candidate
		info(&h);						// display properties
		printf("\n");
	}
	if (confirm("Will REMOVE this file from volume"))	return ABORTED;	// make sure or ERROR -10: aborted operation
	// If arrived here, proceed to removal
	free(ptr[del]);						// actual removal
	used--;								// one less file!
	for (i=del; i<used; i++)			ptr[i] = ptr[i+1];				// shift down all remainin entries after deleted one
	ptr[i] = NULL;						// extra safety!
}

int		setfree(int kb) {				// Select free space to be appended
	int		req;

	if (kb > 16384)		return FREE_ERR;		// ERROR -11: invalid free size
	req = kb << 2						// times four
	req--;								// minus header page
	space = req;

	return	0;
}

int		generate(char* volume) {		// Generate volume
	const byte		pad = 0xFF;			// padding byte
	FILE*			file;
	byte			buffer[HD_BYTES];	// temporary header storage
	struct header	h;
	int				i, err;

	if (empty())		return EMPTY_VOL;		// empty volume error
	if (volume)			printf("Writing to %s...", volume);
	if ((file = fopen(volume, "wb")) == NULL) {
		return NO_CREATE;						// error creating file
	}
	if (verbose)		printf(" OK\nLinking files...\n");
	for (i=0; i<used; i++) {
		err = 0;
		getheader(ptr[i], &h);					// info about file to be added
		if (verbose) {
			printf("%s: ", h.name);
			if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf("Code");
			else																printf("Data");
		}
		if (fwrite(ptr[i], h.size, 1, file) != 1) {				// attempt to write whole file
			printf("\n*** WRITE FAIL ***\n");
			err++;
		}
		if (h.size & 511) {						// non-multiple of 512 needs padding
			if (Verbose)				printf(", Padding");
			while (h.size++ & 511) {							// pad with $FF until end of sector
				if (fwrite(&pad, 1, 1, file) != 1)	{
					printf("\n*** PADDING FAIL ***\n");
					err++;
					break;
				}
			}
		}
		if (!err)			if (verbose)	printf(" OK");
		else {
			fclose(file);
			return 0;	// CHECK CHECK CHECK
		}
		if (verbose)		printf("\n");
	}
	if (space) {
		if (verbose)		printf("Free space: ");
		h.name[0]		= '\0';
		h.comment[0]	= '\0';					// empty name and comment
		h.signature[0]	= 'd';
		h.signature[1]	= 'L';					// free space signature
		h.ld_addr		= 0x2A2A;
		h.ex_addr		= 0x2A2A;				// unused Pocket fields have '****'
		memcpy(h.lib,	"$$$$$$$$", 8);
		memcpy(h.commit,"$$$$$$$$", 8);			// unused commits
		h.version		= 0;
		h.revision		= 0;
		h.phase			= 'a';
		h.build			= 0;					// generic 0.0a0 version
		h.year			= 2022-1980;
		h.month			= 12;
		h.day			= 23;
		h.hour			= 19;
		h.minute		= 44;					// default timestamp is Durango-X unit #1 build date ;-)
		h.second		= 0;
		h.size			= space << 8;
		makeheader(buffer, &h);					// create free space header
		if (fwrite(buffer, HD_BYTES, 1, file) != 1)	
			if (verbose)	printf("Error! ");	// hopefully with no errors!
		if (verbose)		printf("Appending... ");
		err = 0;
		for (i=HD_BYTES; i<(space<<8); i++)
			if (fwrite(&pad, 1, 1, file) != 1)	err++;	// hopefully with no errors!
		if (!err)	if (verbose)	printf("OK");
		else 		printf("*** FAIL *** Do NOT use free space!!");
	}
	for (i=0; i<HD_BYTES; i++)
		fwrite(&pad, 1, 1, file);				// make best effort to add an invalid 'header' at the end
	fclose(file);
	printf("\nDone!\n");

	return 0;
}

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

void	makeheader(byte* p, struct header* h) {			// Generate header from struct
	int		src, dest;
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
	p[H_TIME]		=	((h->minute << 5) & 0xFF) | (h->second >> 1);
	p[H_TIME+1]		=	(h->hour << 3) | (h->minute >> 3);				// coded time
	p[H_DATE]		=	((h->month << 5) & 0xFF) | h->day;
	p[H_DATE+1]		=	(h->year << 1) | (h->month >> 3);				// coded date
	p[H_SIZE]		=	h->size & 0xFF;
	p[H_SIZE+1]		=	(h->size >> 8) & 0xFF;
	p[H_SIZE+2]		=	h->size >> 16;									// coded size
}

int		signature(struct header* h) {	// Returns file type from coded signature
	if (h->signature[0] == 'p') {		// pX Pocket executable should be the only possibility so far
		if (h->signature[1] == 'X') {
			return	SIG_POCKET;			// Pocket executable
		} else {
			return	SIG_UNKN;			// otherwise unsupported
		}
	} else if (h->signature[0] == 'd') {								// Standard Durango signature type
		switch (h->signature[1]) {
			case 'X':
				return	SIG_ROM;		// ROM image
			case 'A':
				return	SIG_FILE;		// Generic file
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

void	info(struct header* h, char* result) {					// Display info about header
	int		i;

	sprintf(result, "%s (%-5.2f KiB)", h->name, h->size/1024.0);			// Name and size
	sprintf(result, "\nType: ");
	switch(signature(h)) {
		case SIG_FREE:		// dL
			sprintf(result, "* Free space *");							// should never be loaded!
			break;
		case SIG_ROM:		// dX
			sprintf(result, "ROM image");
			break;
		case SIG_POCKET:	// pX
			sprintf(result, "Pocket executable [LOAD:$%04X, EXEC:$%04X]", h->ld_addr, h->ex_addr);
			break;
		case SIG_FILE:		// dA
			sprintf(result, "Generic file");
			break;
		case SIG_HIRES:		// dR
			sprintf(result, "HIRES screen dump");
			break;
		case SIG_COLOUR:	// dS
			sprintf(result, "Colour screen dump");
			break;
		case SIG_H_RLE:		// dr
			sprintf(result, "RLE-compressed HIRES screen dump");
			break;
		case SIG_C_RLE:		// ds
			sprintf(result, "RLE-compressed colour screen dump");
			break;
		default:
			sprintf(result, "* UNKNOWN (%c%c) *", h->signature[0], h->signature[1]);
	}
	sprintf(result, "\nLast modified: %d/%d/%d, %02d:%02d", 1980+h->year, h->month, h->day, h->hour, h->minute);	// Last modified
	if (signature(h) != SIG_FILE) {
		sprintf(result, " (v%d.%d%c%d)", h->version, h->revision, h->phase, h->build);	// Version
		sprintf(result, "\nUser field #1: ");
		for (i=0; i<8; i++)		sprintf(result, "%c", h->commit[i]);					// Main commit string
		sprintf(result, ", #2: ");
		for (i=0; i<8; i++)		sprintf(result, "%c", h->lib[i]);						// Lib commit string
		if (h->comment[0] != '\0')		sprintf(result, "\nComment: %s", h->comment);	// optional comment
	}
}

int		choose(char* name) {	// Locate file by name
	int		i;

	i = 0;						// try from first loaded file
	while (i<used) {			// do not look any further
		if (!strcmp(ptr[i]+H_NAME, name))	break;		// found file...
		i++;					// ... or try next
	}
	if (i >= used)				return	NO_FILE;

	return	i;					// make this 0-based...
}

int		confirm(char* msg) {	// Request confirmation for dangerous actions, returns ABORTED if rejected
	char	pass[80];

// if -y	return 0;
	printf("\t%s. Proceed? (Y/N) ", msg);
	scanf("%s", pass);			// just getting confirmation
	if ((pass[0]|32) != 'y') {	// either case
		return ABORTED;
	}

	return	0;					// if not aborted, proceed
}

int		empty(void) {			// returns 0 unless it's empty
	if (!used) {
		return	EMPTY_VOL;
	}

	return	0;					// found some stored headers, thus not empty
}

void	display(int err) {
	if (!err)	return;
	printf("\n*** ");
	switch(err) {
		case NO_VOLUME:
			printf("VOLUME FILE NOT FOUND");
			break;
		case OUT_MEMORY:
			printf("OUT OF MEMORY");
			break;
		case EMPTY_VOL:
			printf("VOLUME FILE IS EMPTY");
			break;
		case FILE_LIM:
			printf("NO MORE FILES ALLOWED");
			break;
		case NO_FILE:
			printf("FILE NOT FOUND");
			break;
		case EMPTY_FILE:
			printf("FILE IS EMPTY");
			break;
		case MISALIGNED:
			printf("MISALIGNED ROM IMAGE");
			break;
		case BAD_SELECT:
			printf("WRONG INDEX?");
			break;
		case NO_CREATE:
			printf("COULD NOT CREATE FILE");
			break;
		case ABORTED:
			printf("ABORTED OPERATION");
			break;
		case FREE_ERR:
			printf("ERROR ON FREE SPACE BLOCK");
			break;
		default:
			printf("- - -UNKNOWN ERROR- - -");
	}
	printf(" ***\n\n");
