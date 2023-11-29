/* Durango Imager - CLI version
 * (C)2023 Carlos J. Santisteban
 * last modified 20231128-1802
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
int		signature(struct header* h);				// Return file type from coded signature
void	info(struct header* h);						// Display info about header
int		choose(char *msg);	// Choose file from list
int		confirm(char* msg);	// Request confirmation for dangerous actions, returns 0 if rejected
int		empty(void);		// Returns 0 unless it's empty

/* ** main code ** */
int main (void) {
	int		opt =	OPT_NONE;

	init();					// Init things
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
	int		i = 0;

	while (ptr[i] != NULL) {
		free(ptr[i]);		// release this block
		ptr[i++] = NULL;	// EEEEEEK
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
		printf(" *** Error ***\n");
		return;
	}
	printf(" OK\nReading headers...");
	bye();					// free up dynamic memory
	while(!feof(file)) {
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
		printf("\nFound %s (%5.2f KiB): Allocating", h.name, h.size/1024.0);
		printf("[%d]",used);									// entry to be allocated
		if ((ptr[used] = malloc(h.size)) == NULL) {				// Allocate dynamic memory
			printf("\n\t*** Out of memory! ***\n");
			return;
		}
		printf(", Header");
		memcpy(ptr[used], buffer, HD_BYTES);					// copy preloaded header
//		for (i=0; i<HD_BYTES; i++)		ptr[used][i] = buffer[i];	// * * * B A D * * * EEEEK
		printf(", Code");
		if (fread(ptr[used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {		// read remaining bytes 
			printf("... ERROR!");
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
printf("\n\n\n* * * D O   N O T   U S E * * *\n\n\n");
	if (used >= MAXFILES) {
		printf("\tVolume is full!\n");
		return;
	}
	printf("File to add into volume: ");
	scanf("%s", name);
	printf("Opening %s... ", name);
	if ((file = fopen(name, "rb")) == NULL) {
		printf("NOT found\n");
		return;
	}
	printf("OK\nReading header... ");
	if (fread(buffer, HD_BYTES, 1, file) != 1) {		// get header into buffer
		printf("*** I/O error ***\n");
		fclose(file);
		return;											// couldn't even load header, something's VERY wrong
	}
	if (!getheader(buffer, &h)) {						// check header and get metadata
		printf("GENERIC file\n");
		strcpy(&(h.name[0]), name);						// place supplied filename
		fseek(file, 0, SEEK_END);
		h.size			= ftell(file);					// check actual file length
		fseek(file, HD_BYTES, SEEK_SET);
		h.signature[0]	= 'd';
		h.signature[1]	= 'A';							// generic file signature
		h.version		= 1;
		h.revision		= 0;
		h.phase			= 'a';
		h.build			= 0;							// generic 1.0a0 version
/* timestamp fetching (don't know if it's portable) */
		stat(name, &attrib);
		stamp = gmtime(&(attrib.st_mtime));
		h.year			= stamp->tm_year;
		h.month			= stamp->tm_mon;
		h.day			= stamp->tm_mday;
		h.hour			= stamp->tm_hour;
		h.minute		= stamp->tm_min;
		h.second		= stamp->tm_sec;	// is this OK?
/* ************************************************ */
	}
	
	
	printf("\nAdding %s (%5.2f KiB): Allocating[%d]", h.name, h.size/1024.0, used);
	if ((ptr[used] = malloc(h.size)) == NULL) {				// Allocate dynamic memory
		printf("\n\t*** Out of memory! ***\n");
		return;
	}


	printf(", Header");
	memcpy(ptr[used], buffer, HD_BYTES);					// copy preloaded header
//		for (i=0; i<HD_BYTES; i++)		ptr[used][i] = buffer[i];	// * * * B A D * * * EEEEK
	printf(", Code");
	if (fread(ptr[used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {		// read remaining bytes 
		printf("... ERROR!");
		free(ptr[used]);
		ptr[used] = NULL;			// eeeeek
	} else {
		printf(" OK");
		used++;			// another file into volume
	}

	fclose(file);
	printf("\n\nDone!\n");


	used++;					// another file into volume
}

void	extract(void) {		// Extract file from volume
	int				i, ext, skip;
	struct header	h;
	FILE*			file;

	if (empty())	return;
	ext = choose("to extract");
	if (ext < 0)	return;		// invalid selection
	getheader(ptr[ext], &h);	// get info for candidate
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
		printf(" OK!\n");	// finish without padding
	}
	fclose(file);
}

void	delete(void) {		// Delete file from volume
	int				i, del;
	struct header	h;

	if (empty())	return;
	del = choose("to be REMOVED from volume");
	if (del < 0)	return;		// invalid selection
	getheader(ptr[del], &h);	// get info for candidate
	info(&h);					// display properties
	printf("\n");
	if (!confirm("Will REMOVE this file from volume"))	return;		// make sure
	// If arrived here, proceed to removal
	free(ptr[del]);			// actual removal
	used--;					// one less file!
	for (i=del; i<used; i++)		ptr[i] = ptr[i+1];				// shift down all remainin entries after deleted one
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
			space = 65536;	// 16M
			break;
		default:
			space = 0;		// do not append anything
	}
}

void	generate(void) {	// Generate volume
	if (empty())	return;
printf("\n\n\n* * * D O   N O T   U S E * * *\n\n\n");
	
}

int		getheader(byte* p, struct header* h) {			// Extract header specs, return 0 if not valid
	static char	phasevec[4] = {'a', 'b', 'R', 'f'};
	int			src, dest;

	if ((p[H_MAGIC1] != 0) && (p[H_MAGIC2] != 13) && (p[H_MAGIC3] != 0))	return	0;	// invalid header
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
	h->revision	=		(p[H_VERSION+1] & 0xF) | (p[H_VERSION] & 0x30);
	h->phase	=		phasevec[p[H_VERSION]>>6];
	h->build	=		p[H_VERSION] & 0xF;
	h->hour		=		p[H_TIME+1]>>3;
	h->minute	=		(p[H_TIME+1] & 0x7)<<3 | p[H_TIME]>>5;
	h->second	=		(p[H_TIME] & 0x1F)<<1;
	h->year		=		p[H_DATE+1]>>1;	// add 1980
	h->month	=		(p[H_DATE+1] & 1)<<3 | p[H_DATE]>>5;
	h->day		=		p[H_DATE] & 0x1F;
	h->size		=		p[H_SIZE] | p[H_SIZE+1]<<8 | p[H_SIZE+2]<<16;

	return	1;				// all OK
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

	printf("%s (%5.2f KiB)", h->name, h->size/1024.0);			// Name and size
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
	printf("\nv%d.%d%c%d, ", h->version, h->revision, h->phase, h->build);	// Version
	printf("last modified: %d/%d/%d, %02d:%02d", 1980+h->year, h->month, h->day, h->hour, h->minute);	// Last modified
	printf("\nMain commit ");
	for (i=0; i<8; i++)		printf("%c", h->commit[i]);						// Main commit string
	printf(", Lib commit ");
	for (i=0; i<8; i++)		printf("%c", h->lib[i]);						// Lib commit string
	if (h->comment[0] != '\0')		printf("\nComment: %s", h->comment);	// optional comment
}

int		choose(char* msg) {		// Choose file from list
	int		i, sel;

	for (i=0; i<used; i++) {
		printf("%d) %s\n", i+1, ptr[i]+8);		// display list of contents
	}
	printf("\nNumber of file %s? ", msg);
	scanf("%d", &sel);
	if (sel<1 || sel>used) {
		printf("\tWrong index *** Aborted ***\n");
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
