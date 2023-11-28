/* Durango Imager - CLI version
 * (C)2023 Carlos J. Santisteban
 * last modified 20231128-1339
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>

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
byte*	ptr[MAXFILES];	// pointer to dynamically stored header (and file)
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
dword	setfree(void);		// Select free space to be appended
void	generate(void);		// Generate volume
int		getheader(byte* p, struct header* h);		// Extract header specs, returns 0 if not valid
void	signature(struct header* h);				// Display file type from coded signature
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
				space = setfree();
				break;
			case OPT_GEN:	// Generate volume
				generate();
				break;
			case OPT_EXIT:
				printf("Bye!\n");
				break;		// just EXIT
			default:
				printf("\n * * * ERROR! * * *\n");
				opt = OPT_NONE;
		}
	}
	bye();					// Clean up

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
	int		i =	0;

	while(ptr[i]!=NULL) {
		free(ptr[i++]);		// release this block
	}
	used = 0;				// all clear
}

int		menu(void) {		// Show menu and choose action
	int		opt;

	printf("\n1.Open volume\n");
	printf("2.List volume contents\n");
	printf("3.Add file to volume\n");
	printf("4.Extract file from volume\n");
	printf("5.Delete file from volume\n");
	printf("6.Set free space to append after volume contents\n");
	printf("7.Generate volume (with %d K of free space)\n",space/4);
	printf("==========================\n");
	printf("9.EXIT\n\n");
	printf("Choose option: ");
	scanf("%d", &opt);

	return	opt;
}

void	open(void) {		// Open volume
	char	volume[VOL_NLEN];			// volume filename
	FILE*	file;
	byte	buffer[HD_BYTES];			// temporary header fits into a full page
	struct header	h;		// metadata storage

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
	printf("OK\nReading headers...");
	bye();					// free up dynamic memory
	while(!feof(file)) {
		fread(buffer,256,1,file);
// ...and do actual things
		used++;				// another file into volume
	}
	fclose(file);
}

void	list(void) {		// List volume contents
	int				i;
	struct header	h;

	if (empty())	return;
	for (i=0; i<used; i++) {			// scan thru all stored headers
		getheader(ptr[i], &h);			// get surely loaded header into local storage 
		printf("%d. %s (%4.2f KiB)\n", i+1, h.name, h.size/1024.0);				// Name and size
		printf("\n v%d.%d%c%d, ", h->version, h->revision, h->phase, h->build);	// Version
		printf("last modified: %d-%d-%d, %d:%d:%d", h->year, h->month, h->day, h->hour, h->minute, h->second);	// Last modified
		printf("\nMain commit ");
		for (i=0; i<8; i++)		printf("%c", h->commit[i]);						// Main commit string
		printf(", Lib commit ");
		for (i=0; i<8; i++)		printf("%c", h->lib[i]);						// Lib commit string
		if (h->comment[0] != '\0')		printf("\nComment: %s", h->comment);	// optional comment
		print("\n--------n");
	}
}

void	add(void) {			// Add file to volume
	if (used >= MAXFILES) {
		printf("\tVolume is full!\n");
		return;
	}
// Do things
	used++;					// another file into volume
}

void	extract(void) {		// Extract file from volume
	if (empty())	return;
	
}

void	delete(void) {		// Delete file from volume
	if (empty())	return;
	
}

dword	setfree(void) {		// Select free space to be appended
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
			return	256;	// 64K
		case 2:
			return	1024;	// 256K
		case 3:
			return	4096;	// 1M
		case 4:
			return	16384;	// 4M
		case 5:
			return	65536;	// 16M
		default:
			return	0;
	}
}

void	generate(void) {	// Generate volume
	if (empty())	return;
	
}

int		getheader(byte* p, struct header* h) {			// Extract header specs, return 0 if not valid
	static char phasevec[4] = {'a', 'b', 'R', 'f'};
	int		src, dest;

	if ((p[H_MAGIC1] != 0) && (p[H_MAGIC2] != 13) && (p[H_MAGIC3] != 0))	return	0;	// invalid header
// otherwise extract header data
	h->signature[0] =	p[H_SIGNATURE];
	h->signature[1] =	p[H_SIGNATURE+1];
	h->ld_addr	=		p[H_LOAD] | p[H_LOAD+1]<<8;
	h->ex_addr	=		p[H_EXECUTE] | p[H_EXECUTE]<<8;
	src = H_NAME;										// filename offset
	dest = 0;
	while (p[src])		h->name[dest++] = p[src++];		// copy filename
	src++;												// skip terminator
	dest = 0;
	while (p[src])		h->comment[dest++] = p[src++];	// copy comment
	src = H_LIB;												// library commit offset
	for (dest=0;dest<8;dest++)		h->lib[dest] = p[src++];	// copy library commit
//	src = H_COMMIT;												// main commit offset (already there)
	for (dest=0;dest<8;dest++)		h->commit[dest] = p[src++];	// copy main commit afterwards
	h->version	=		p[H_VERSION]>>4;
	h->revision	=		(p[H_VERSION] & 0xF) | (p[H_VERSION+1] & 0x30);
	h->phase	=		phasevec[p[H_VERSION+1]>>6];
	h->build	=		p[H_VERSION+1] & 0xF;
	h->hour		=		p[H_TIME]>>3;
	h->minute	=		(p[H_TIME] & 0x7)<<3 | p[H_TIME+1]>>5;
	h->second	=		(p[H_TIME+1] & 0x1F)<<1;
	h->year		=		p[H_DATE]>>1;		// add 1980
	h->month	=		p[H_DATE]<<4 | p[H_DATE+1]>>5;
	h->day		=		p[H_DATE+1] & 0x1F;
	h->size		=		p[H_SIZE] | p[H_SIZE+1]<<8 | p[H_SIZE+2]<<16;

	return	1;				// all OK
}

void	signature(struct header* h) {	// Display file type from coded signature
	if (h->signature[0] == 'p') {		// pX Pocket executable should be the only possibility so far
		if (h->signature[1] == 'X') {
			printf("Pocket executable [LOAD:$%04X, EXEC:$04X]", h->ld_addr, h->ex_addr);
		} else {
			printf("* UNKNOWN (p%c) *", h->signature[1]);		// otherwise unsupported
		}
	} else if (h->signature[0] == 'd') {						// Standard Durango signature type
		switch (h->signature[1]) {
			case 'X':
				printf("ROM image");
				break;
			case 'A':
				printf("Generic file");
				break;
			case 'R':
				printf("HIRES screen dump");
				break;
			case 'S':
				printf("Colour screen dump");
				break;
			case 'r':
				printf("RLE-compressed HIRES screen dump");
				break;
			case 's':
				printf("RLE-compressed colour screen dump");
				break;
			case 'L':
				printf("* Free space *");						// should never be loaded!
				break;
			default:
				printf("* UNKNOWN (d%c) *", h->signature[1]);					// Unsupported signature
		}
	} else printf("* UNKNOWN (%c%c) *", h->signature[0], h->signature[1]);		// Totally unknown signature
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
