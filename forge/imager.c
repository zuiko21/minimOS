/* Durango Imager - CLI version
 * (C)2023-2024 Carlos J. Santisteban
 * last modified 20240403-1223
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
#define		VOL_NLEN	80
// Magic numbers
#define		OPT_OPEN	1
#define		OPT_LIST	2
#define		OPT_ADD		3
#define		OPT_EXTR	4
#define		OPT_DEL		5
#define		OPT_SETF	6
#define		OPT_GEN		7
#define		OPT_EXIT	9
#define		OPT_NONE	0
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

/* Function prototypes */
void	init(void);			// Init stuff
void	bye(void);			// Clean up
int		menu(void);			// Show menu and choose action
void	open(void);			// Open volume
void	list(void);			// List volume contents
void	add(void);			// Add file to volume
void	extract(void);		// Extract file from volume
void	delete(void);		// Delete file from volume
void	setfree(void);		// Select free space to be appended
void	generate(void);		// Generate volume
int		getheader(byte* p, struct header* h);		// Extract header specs, returns 0 if not valid
void	makeheader(byte* p, struct header* h);		// Generate header from struct
int		signature(struct header* h);				// Return file type from coded signature
void	info(struct header* h);						// Display info about header
int		choose(char *msg);	// Choose file from list
int		confirm(char* msg);	// Request confirmation for dangerous actions, returns 0 if rejected
int		empty(void);		// Returns 0 unless it's empty

/* ** main code ** */
int main (void) {
	int		opt =	OPT_NONE;

	init();					// Init things
	printf("\nDurango-X volume creator, v1.0b2 by @zuiko21\n");
// Do actual stuff
	while (opt != OPT_EXIT) {
		opt =	menu();		// choose task
		switch(opt) {
			case OPT_OPEN:	// Open volume
				open();
				break;
			case OPT_LIST:	// List volume contents
				list();
				break;
			case OPT_ADD:	// Add file to volume
				add();
				break;
			case OPT_EXTR:	// Extract file from volume
				extract();
				break;
			case OPT_DEL:	// Delete file from volume
				delete();
				break;
			case OPT_SETF:	// Set free space after volume contents
				setfree();
				break;
			case OPT_GEN:	// Generate volume
				generate();
				break;
			case OPT_EXIT:
				if (!confirm("Volume will be lost"))	opt = OPT_NONE;	// in case we stay
				break;
			default:
				printf("\n * * * ERROR! * * *\n");
				opt = OPT_NONE;
		}
	}
	bye();					// Clean up
	printf("Bye!\n");

	return	0;
}

/* ** Function definitions ** */
void init(void) {			// Init stuff
	int		i;

	used =	0;				// empty array, nothing stored in heap
	for (i=0;i<MAXFILES;i++) {
		ptr[i] =	NULL;	// reset all empty pointers
	} 
}

void bye(void) {			// Release heap memory * * * VERY IMPORTANT * * *
	int		i;

	for (i=0; i<MAXFILES; i++) {
		if (ptr[i] != NULL)		free(ptr[i]);		// release this block
		ptr[i] =	NULL;	// EEEEEEK
	}
	used = 0;				// all clear
}

int		menu(void) {		// Show menu and choose action
	int		opt;

	printf("\n1.Open volume\n");
	printf("2.List volume contents\n");
	printf("3.Add file to volume\n");
	printf("4.Extract file from volume\n");
	printf("5.Remove file from volume\n");
	printf("6.Set free space to append after volume contents\n");
	printf("7.Generate volume (with %d K of free space)\n",space/4);
	printf("==========================\n");
	printf("9.EXIT\n\n");
	printf("Choose option: ");
	scanf("%d", &opt);

	return	opt;
}

void	open(void) {					// Open volume
	char			volume[VOL_NLEN];	// volume filename
	FILE*			file;
	byte			buffer[HD_BYTES];	// temporary header fits into a full page
	struct header	h;					// metadata storage

	if (used) {	// there's another volume in use...
		if (!confirm("Current volume will be lost"))	return;
	}
	printf("Volume name (usually 'durango.av'): ");
	scanf("%s", volume);
	printf("Opening %s...", volume);
	if ((file = fopen(volume, "rb")) == NULL) {
		printf(" *** NOT found ***\n");
		return;
	}
	printf(" OK\nReading headers...");
	bye();					// free up dynamic memory
	while (!feof(file)) {
		if (fread(buffer, HD_BYTES, 1, file) != 1)	break;		// get header into buffer
		if (!getheader(buffer, &h)) {							// check header and get metadata
			printf("\n\t* Bad header *\n");
			break;
		}
		if (signature(&h) == SIG_FREE) {
			printf("\n(Skipping free space)");
			fseek(file, h.size-HD_BYTES, SEEK_CUR);				// just skip free space!
			continue;											// EEEEEEEK
		}
		printf("\nFound %s (%-5.2f KiB): Allocating", h.name, h.size/1024.0);
		printf("[%x]",used);									// entry to be allocated
		if (h.size & 511) {	// uneven size in header, must be rounded up as was padded in volume BEFORE ALLOCATING EEEEEEEEEEEEEEEEKKKKKKKK
			h.size = (h.size + 512) & 0xFFFFFE00;				// sector-aligned size
		}
		if ((ptr[used] = malloc(h.size)) == NULL) {				// Allocate dynamic memory
			printf("\n\t*** Out of memory! ***\n");
			fclose(file);				// eeek
			return;
		}
		printf(", Header");
		memcpy(ptr[used], buffer, HD_BYTES);					// copy preloaded header
//		for (i=0; i<HD_BYTES; i++)		ptr[used][i] = buffer[i];	// * * * B A D * * * EEEEK
		if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf(", Code");
		else																printf(", Data");
		if (fread(ptr[used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {		// read remaining bytes 
			printf("... *** ERROR! ***");
			free(ptr[used]);
			ptr[used] = NULL;			// eeeeek
		} else {
			printf(" OK");
			used++;			// another file into volume
		}
	}
	fclose(file);
	printf("\n\nDone!\n");
}

void	list(void) {		// List volume contents
	int				i;
	struct header	h;

	if (empty())	return;
	for (i=0; i<used; i++) {			// scan thru all stored headers
		getheader(ptr[i], &h);			// get surely loaded header into local storage 
		printf("%d: ", i+1);			// entry number (1-based)
		info(&h);						// display all info about the file
		printf("\n--------\n");
	}
}

void	add(void) {			// Add file to volume
	char			name[VOL_NLEN];		// filename
	FILE*			file;
	byte			buffer[HD_BYTES];	// temporary header fits into a full page
	struct header	h;					// metadata storage
/* optional variables for timestamp fetching */
	struct tm*		stamp;
	struct stat		attrib;
/* ***************************************** */
	if (used >= MAXFILES) {
		printf("\tVolume is full!\n");
		return;
	}
	printf("File to add into volume: ");
	scanf("%s", name);
	printf("Opening %s... ", name);
	if ((file = fopen(name, "rb")) == NULL) {
		printf(" NOT found\n");
		return;
	}
	printf("OK\nReading header... ");
	if (fread(buffer, HD_BYTES, 1, file) != 1) {		// get header into buffer
		if (!ftell(file)) {								// if it was a generic file, could be shorter than HD_BYTES
			printf("is EMPTY!\n");						// otherwise it's an empty file!
			fclose(file);
			return;
		}
	}
	if (!getheader(buffer, &h)) {						// check header and get metadata
		printf("GENERIC file");
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
		makeheader(buffer, &h);			// transfer header struct back into buffer
//		h.size -= HD_BYTES;				// eeeek
	}
	printf("\nAdding %s (%-5.2f KiB): Allocating[%d]", h.name, h.size/1024.0, used);
	if ((ptr[used] = malloc(h.size)) == NULL) {			// Allocate dynamic memory
		printf("\n\t*** Out of memory! ***\n");
		fclose(file);
		return;
	}
	printf(", Header");
	memcpy(ptr[used], buffer, HD_BYTES);				// copy preloaded header
	if ((signature(&h) == SIG_ROM) && (h.size & 511)) {	// check for misaligned ROM images
		printf(" *** Misaligned ROM image *** Aborting...\n\n");		// simply not accepted!
		free(ptr[used]);
		ptr[used] = NULL;								// unlikely to be a problem, but...
		fclose(file);
		return;
	}
	if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf(", Code");
	else																printf(", Data");
	if (fread(ptr[used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {	// read remaining bytes after header (computed or preloaded)
		printf("... ERROR!\n");
		free(ptr[used]);
		ptr[used] = NULL;				// eeeeek
	} else {
		printf(" OK\n");
		used++;							// another file into volume
	}
	fclose(file);
}

void	extract(void) {		// Extract file from volume
	int				i, ext, skip;
	struct header	h;
	FILE*			file;

	if (empty())	return;
	ext = choose("to extract");
	if (ext < 0)	return;				// invalid selection
	getheader(ptr[ext], &h);			// get info for candidate
	info(&h);
	if (signature(&h) == SIG_FILE)		skip = HD_BYTES;		// generic files trim headers
	else								skip = 0;
	printf("\nWriting to file %s... ", h.name);
	if ((file = fopen(h.name, "wb")) == NULL) {
		printf("*** Can't create ***\n");
		return;
	}
	if (fwrite(ptr[ext]+skip, h.size-skip, 1, file) != 1) {		// note header removal option
		printf("*** I/O error ***\n");
	} else {
		printf(" Done!\n");	// finish without padding
	}
	fclose(file);
}

void	delete(void) {		// Delete file from volume
	int				i, del;
	struct header	h;

	if (empty())	return;
	del = choose("to be REMOVED from volume");
	if (del < 0)	return;				// invalid selection
	getheader(ptr[del], &h);			// get info for candidate
	info(&h);							// display properties
	printf("\n");
	if (!confirm("Will REMOVE this file from volume"))	return;	// make sure
	// If arrived here, proceed to removal
	free(ptr[del]);			// actual removal
	used--;					// one less file!
	for (i=del; i<used; i++)		ptr[i] = ptr[i+1];			// shift down all remainin entries after deleted one
	ptr[i] = NULL;			// extra safety!
}

void	setfree(void) {		// Select free space to be appended
	int		req;

	printf("\n\tSET FREE SPACE\n");
	printf("1=> 64 KiB\n");
	printf("2=> 256 KiB\n");
	printf("3=> 1 MiB\n");
	printf("4=> 4 MiB\n");
	printf("5=> 16 MiB\n");
	printf("\n0=> Don't append any free space\n\n");
	printf("Choose value: ");
	scanf("%d", &req);
	switch(req) {
		case 1:
			space = 256;	// 64K
			break;
		case 2:
			space = 1024;	// 256K
			break;
		case 3:
			space = 4096;	// 1M
			break;
		case 4:
			space = 16384;	// 4M
			break;
		case 5:
			space = 65534;	// 16M minus one sector!
			break;
		default:
			space = 0;		// do not append anything
	}
}

void	generate(void) {	// Generate volume
	const byte		pad = 0xFF;				// padding byte
	char			volume[VOL_NLEN];		// filename
	FILE*			file;
	byte			buffer[HD_BYTES];		// temporary header storage
	struct header	h;
	int				i, err;

	if (empty())	return;
	printf("Volume name (usually 'durango.av'): ");
	scanf("%s", volume);
	printf("Writing to %s...", volume);
	if ((file = fopen(volume, "wb")) == NULL) {
		printf(" *** cannot ***\n");
		return;
	}
	printf(" OK\nLinking files...\n");
	for (i=0; i<used; i++) {
		err = 0;
		getheader(ptr[i], &h);			// info about file to be added
		printf("%s: ", h.name);
		if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf("Code");
		else																printf("Data");
		if (fwrite(ptr[i], h.size, 1, file) != 1) {				// attempt to write whole file
			printf(" *** FAIL ***");
			err++;
		}
		if (h.size & 511) {				// non-multiple of 512 need padding
			printf(", Padding");
			while (h.size++ & 511) {							// pad with $FF until end of sector
				if (fwrite(&pad, 1, 1, file) != 1)	{
					printf(" *** FAIL ***");
					err++;
					break;
				}
			}
		}
		if (!err)	printf(" OK");
		else {
			fclose(file);
			return;
		}
		printf("\n");
	}
	if (space) {
		printf("Free space: ");
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
		if (fwrite(buffer, HD_BYTES, 1, file) != 1)		printf("Error! ");		// hopefully with no errors!
		printf("Appending... ");
		err = 0;
		for (i=HD_BYTES; i<(space<<8); i++)
			if (fwrite(&pad, 1, 1, file) != 1)	err++;			// hopefully with no errors!
		if (!err)	printf("OK");
		else		printf("*** FAIL *** Do NOT use free space!!");
	}
	for (i=0; i<HD_BYTES; i++)
		fwrite(&pad, 1, 1, file);				// make best effort to add an invalid 'header' at the end
	fclose(file);
	printf("\nDone!\n");
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

void	makeheader(byte* p, struct header* h) {		// Generate header from struct
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
		printf("\nUser field #1: ");
		for (i=0; i<8; i++)		printf("%c", h->commit[i]);						// Main commit string
		printf(", #2: ");
		for (i=0; i<8; i++)		printf("%c", h->lib[i]);						// Lib commit string
		if (h->comment[0] != '\0')		printf("\nComment: %s", h->comment);	// optional comment
	}
}

int		choose(char* msg) {		// Choose file from list
	int		i, sel;

	for (i=0; i<used; i++) {
		printf("%d) %s\n", i+1, ptr[i]+H_NAME);		// display list of contents
	}
	printf("\nNumber of file %s? (0=none) ", msg);
	scanf("%d", &sel);
	if (sel<1 || sel>used) {
		printf("\tBad index *** Aborted ***\n");
		return -1;			// invalid index
	}
	return	sel-1;			// make this 0-based...
}

int		confirm(char* msg) {			// Request confirmation for dangerous actions, returns 0 if rejected
	char	pass[80];

	printf("\t%s. Proceed? (Y/N) ", msg);
	scanf("%s", pass);					// just getting confirmation
	if ((pass[0]|32) != 'y') {			// either case
		printf("*** ABORTED ***\n");
		return 0;
	}

	return 1;				// if not aborted, proceed
}

int		empty(void) {		// returns 0 unless it's empty
	if (!used) {
		printf("\tVolume is empty!\n");
		return	-1;
	}

	return	0;				// found some stored headers, thus not empty
}
