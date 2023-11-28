/* Durango Imager - CLI version
 * (C)2023 Carlos J. Santisteban
 * last modified 20231128-0101
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>

/* Constants */
// Max number of files into volume
#define		MAXFILES	100
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
	byte	version;		// [246-247]
	byte	revision;
	char	phase;			// a-b-c-f
	byte	build;
	byte	hour;			// [248-249]
	byte	minute;
	byte	second;
	byte	year;			// [250-251]
	byte	month;
	byte	day;
	dword	size;			// [252-254]
};

/* Global variables */
byte*	ptr_h[MAXFILES];	// pointer to dynamically stored header (and file)
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
int		getheader(byte* p, struct header* h);		// Extract header specs, return 0 if not valid

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
		ptr_h[i] =	NULL;	// reset all empty pointers
	} 
}

void bye(void) {			// Release heap memory * * * VERY IMPORTANT * * *
	int		i =	0;

	while(ptr_h[i]!=NULL) {
		free(ptr_h[i++]);	// release this block
	}
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
	char	volume[80];		// volume filename
	FILE*	file;
	byte	buffer[256];	// temporary header fits into a full page
	struct header	h;		// metadata storage

	if (used) {	// there's another volume in use...
		printf("\t* Current volume will be lost. Proceed? (Y/N) * ");
		scanf("%s", volume);			// just getting confirmation
		if ((volume[0]|32) != 'y') {	// either case
			printf("*** ABORTED ***\n");
			return;
		}
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
	}
	fclose(file);
}

void	list(void) {		// List volume contents
}

void	add(void) {			// Add file to volume
}

void	extract(void) {		// Extract file from volume
}

void	delete(void) {		// Delete file from volume
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
}

int		getheader(byte* p, struct header* h) {			// Extract header specs, return 0 if not valid
	static char phasevec[4] = {'a', 'b', 'R', 'f'};
	int		src, dest;

	if ((p[0] != 0) && (p[7] != 13) && (p[255] != 0))	return	0;	// invalid header
// otherwise extract header data
	h->signature[0] =	p[1];
	h->signature[1] =	p[2];
	h->ld_addr	=		p[3] | p[4]<<8;
	h->ex_addr	=		p[5] | p[6]<<8;
	src = 8;
	dest = 0;
	while (p[src])		h->name[dest++] = p[src++];		// copy filename
	src++;												// skip terminator
	dest = 0;
	while (p[src])		h->comment[dest++] = p[src++];		// copy comment
	h->version	=		p[246]>>4;
	h->revision	=		(p[246] & 0xF) | (p[247] & 0x30);
	h->phase	=		phasevec[p[247]>>6];
	h->build	=		p[247] & 0xF;
	h->hour		=		p[248]>>3;
	h->minute	=		(p[248] & 0x7)<<3 | p[249]>>5;
	h->second	=		(p[249] & 0x1F)<<1;
	h->year		=		p[250]>>1;		// add 1980
	h->month	=		p[250]<<4 | p[251]>>5;
	h->day		=		p[251] & 0x1F;
	h->size		=		p[252] | p[253]<<8 | p[254]<<16;

	return	1;				// all OK
}
