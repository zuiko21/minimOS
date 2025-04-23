/* Durango Imager - CLI, non-interactive version
 * (C) 2023-2025 Carlos J. Santisteban
 * last modified 20250423-1329
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<stdbool.h>
/* optional libraries for timestamp fetching */
#include	<sys/stat.h>
#include	<unistd.h>
#include	<time.h>
/* ***************************************** */

/* Constants */
// Max number of files into volume -- arbitrary limitation
#define		MAXFILES	100
// bytes per header/page
#define		HD_BYTES	256
// Max volume name length -- current filesystem space
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
#define		MISALIGNED	-7
#define		BAD_SELECT	-8
#define		NO_CREATE	-9
#define		ABORTED		-10
#define		FREE_ERR	-11
#define		BAD_HEAD	-12
// Listing mode
#define		SIMPLE_LIST	0
#define		DETAIL_LIST	1
// For the sake of it...
#define		TRUE	true
#define		FALSE	false

/* Custom types */
typedef	u_int8_t		byte;
typedef	u_int16_t		word;
typedef u_int32_t		dword;

// Custom contents struct instead of global variables
struct cont {
	byte*	ptr[MAXFILES];		// pointer to dynamically stored header (and file)
	int		used;				// actual number of files
// free space after contents (in 256-byte pages) already into pre-fetched parameters
// flag needed for message display already into pre-fetched parameters
// ask for confirmation already into pre-fetched parameters
};

// Custom CLI parameter list for pre-fetching
struct param {
	char	invol[VOL_NLEN];	// -i input volume
	char	outvol[VOL_NLEN];	// -o output volume (default: durango.av)
	bool	verbose;			// -v verbose mode flag
	bool	force;				// -y confirm deletions by default
	bool	list;				// -l request volume directory
	bool	detailed;			// -m request detailed volume directory (overrides -l)
	bool	extract;			// -x fetch list of files to be extracted
	bool	remove;				// -d fetch list of files to be removed
	dword	space;				// -f add free space at the end of the volume
	char	dir[MAXFILES][VOL_NLEN];	// list of filenames to be extracted/removed/added (-x/d/a)
};

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
void	init(struct cont* v, struct param* cli);				// Init stuff
void	bye(struct cont* v);									// Clean up
int		open(char* volume, struct cont* v, struct param* cli);	// Open volume
int		list(char* result, int mode, struct cont* v, struct param* cli);			// List volume contents
int		add(char* name, struct cont* v, struct param* cli);		// Add file to volume
int		extract(char* name, struct cont* v, struct param* cli);	// Extract file from volume
int		rmfile(char* name, struct cont* v, struct param* cli);	// Delete file from volume
int		setfree(int kb, struct cont* v, struct param* cli);		// Select free space to be appended
int		generate(char* volume, struct cont* v, struct param* cli);					// Generate volume
int		getheader(byte* p, struct header* h);	// Extract header specs, returns BAD_HEAD if not valid
void	makeheader(byte* p, struct header* h);	// Generate header from struct
int		signature(struct header* h);			// Return file type from coded signature
void	info(struct header* h, char* result);	// Display info about header
int		choose(char* name);						// Choose file from list
int		confirm(char* name);					// Request confirmation for dangerous actions, returns ABORTED if rejected
int		empty(struct cont* v);					// Returns 0 unless it's empty **** REMOVE
void	display(int err);						// Display error text

/* ** main code ** */
int main (int argc, char** argv) {
	int		err, c, i, line=0;
//	char	name[VOL_NLEN];		// file name storage CHECK SIZE!
//	char	volume[VOL_NLEN];	// volume name storage, must be kept CHECK SIZE!
	char	string[2000];
	struct param	cli;		// pre-fetched parameter block
	struct cont		status;		// global status

	init();						// ** Init things **
// First of all, pre-fetch parameters
	while ((c = getopt(argc, argv, "i:o:vylmx:d:f:")) != -1) {
		switch (c) {
			case 'i':
				strcpy(cli.invol, optarg);
				break;
			case 'o':
				strcpy(cli.outvol, optarg);
				break;
			case 'v':
				cli.verbose	= TRUE;
				break;
			case 'y':
				cli.force	= TRUE;
				break;
			case 'l':
				cli.list	= TRUE;
				cli.detailed = FALSE;
				break;
			case 'm':
				cli.list	= FALSE;
				cli.detailed = TRUE;
				break;
			case 'x':
				if (cli.remove) {
					printf("\n*** Cannot extract while removing ***\n");
					return ABORTED;
				}
				cli.extract	= TRUE;
				strcpy(cli.dir[line++], optarg);
				break;
			case 'd':
				if (cli.extract) {
					printf("\n*** Cannot remove while extracting ***\n");
					return ABORTED;
				}
				cli.remove	= TRUE;
				strcpy(cli.dir[line++], optarg);
				break;
			case 'f':
				cli.space	= (dword)strtol(optarg, NULL, 0);
				break;
			case '?':
				printf("\n*** Bad param ***\n");
				return ABORTED;
		}
	}
// flags are set, now take all spare filenames into array to be added
// as long as no -x or -d were enabled
	if (optind<argc) {			// some filenames remain
		if (!cli.extract && !cli.remove) {
			while (optind<argc) {
				if (cli.verbose)	printf("Will add %s\n", argv[optind]);
				strcpy(cli.dir[line++], argv[optind++]);
			}
			if (cli.verbose)		printf("...into %s\n", cli.outvol);
		} else {
			printf("\n*** Cannot add while extracting or removing ***\n");
			return ABORTED;
		}
	}

// now execute code according to enabled options
	if (cli.verbose) {			// ** both verbose mode and version display **
		printf("\nDurango-X volume creator, v1.1b2 by @zuiko21\n");
	}
	if (cli.invol[0] != '\0') {	// ** open volume by name, otherwise was new volume **
		err = open(cli.invol);
		display(err);
		if (err == NO_VOLUME)	return err;	// if specified, input volume MUST exist; other errors may continue
	}
	if (cli.list) {				// ** list existing files into volume (and finish) **
		err = list(string, SIMPLE_LIST);
		if (!err)				printf("\n%s\n", string);
		return	err;			// list and exit
	}
	if (cli.detailed) {			// ** DETAIL existing files into volume (and finish) **
		err = list(string, DETAIL_LIST);
		if (!err)				printf("\n%s\n", string);
		return	err;			// list and exit
	}
	if (cli.extract) {			// ** fetch name and extract that file if exists **
		i = 0;					// reset file list cursor
		while (cli.dir[i][0] != '\0') {
			err = extract(cli.dir[i++]);
			if (cli.verbose && err)		display(err);	// tell if file extraction fails
		}
		return	0;
	}
// **** The following options do modify a volume ****
	if (cli.remove) {			// fetch name and remove it from volume (could add something afterwards)
		i = 0;					// reset file list cursor
		while (cli.dir[i][0] != '\0') {
			err = rmfile(cli.dir[i++]);
			if (cli.verbose && err)		display(err);	// tell if file deletion fails
		}
// no need to return, as the volume file will be saved anyways
	}
// for each loose file, fetch name and add that file EEEEEK
	i = 0;
	while (cli.dir[i][0] != '\0') {
		add(cli.dir[i]);
		if (++i >= MAXFILES)	break;
	}
// **** generate the volume file with new/modified contents ****
	generate(cli.outvol);		// maybe if NOT empty? eeeek
	bye();						// Clean up
	if (cli.verbose)			printf("Bye!\n");

	return	0;
}

/* ** Function definitions ** */
void	init(struct cont* v, struct param* p) {			// Init stuff
	int		i;

	v->used			= 0;		// empty array, nothing stored in heap
	for (i=0; i<MAXFILES; i++) {
		v->ptr[i]	= NULL;		// reset all empty pointers
		p->dir[i][0]='\0';		// reset fetched file list
	}
	p->invol[0]		= '\0';		// create new volume by default
	strcpy(p->outvol, "durango.av\0");	// default output file!
	p->verbose		= FALSE;	// quiet mode by default
	p->force		= FALSE;	// ask for deletion confirmation!
	p->list			= FALSE;	// do not list until asked
	p->detailed		= FALSE;	// ditto for details
	p->extract		= FALSE;	// default is add, not extract
	p->remove		= FALSE;	// much less file deletion!
	p->space		= 0;		// no extra space unless specified
}

void	bye(struct cont* v) {		// Release heap memory * * * VERY IMPORTANT * * *
	int		i;

	for (i=0; i<MAXFILES; i++) {
		if (v->ptr[i] != NULL)		free(v->ptr[i]);	// release this block
//		v->ptr[i] =	NULL;			// no need as this function will shut down
	}
	v->used = 0;					// all clear
}

int		open(char* volume, struct cont* v, bool verbose) {					// Open volume
	FILE*			file;
	byte			buffer[HD_BYTES];			// temporary header fits into a full page
	struct header	h;							// metadata storage

	if (verbose)			printf("Opening %s...", volume);
	if ((file = fopen(volume, "rb")) == NULL) 		return NO_VOLUME;	// ERROR -1: source volume not found
	if (verbose)			printf(" OK\nReading headers...");
	while (!feof(file)) {
		if (fread(buffer, HD_BYTES, 1, file) != 1)	break;				// get header into buffer
		if (getheader(buffer, &h)) {									// check header and get metadata
			fclose(file);												// bad header will abort volume read
			return	BAD_HEAD;
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
		if ((v->ptr[v->used] = malloc(h.size)) == NULL) {						// Allocate dynamic memory
			fclose(file);												// eeek
			return OUT_MEMORY;											// ERROR -2: out of memory
		}
		if (verbose)		printf(", Header");
		memcpy(v->ptr[v->used], buffer, HD_BYTES);							// copy preloaded header
//		for (i=0; i<HD_BYTES; i++)		v->ptr[v->used][i] = buffer[i];	// * * * B A D * * * EEEEK
		if (verbose)
			if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf(", Code");
			else																printf(", Data");
		if (fread(v->ptr[v->used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {			// read remaining bytes 
			printf("\n [ READ ERROR! ]\n");
			free(v->ptr[v->used]);
			v->ptr[v->used] = NULL;			// eeeeek
		} else {
			if (verbose)		printf(" OK");
			v->used++;						// another file into volume
		}
	}
	fclose(file);
	if (verbose)			printf("\n\nDone!\n");

	return	0;
}

int		list(char* result, int mode, struct cont* v) {	// List volume contents
	int				i;
	struct header	h;

	result[0]='\0';
	if (!(v->used))	return EMPTY_VOL;	// ERROR -3: empty volume
	for (i=0; i < v->used; i++) {			// scan thru all stored headers
		if (mode == DETAIL_LIST) {		// maybe use an specific flag?
			getheader(v->ptr[i], &h);		// get surely loaded header into local storage 
			sprintf(result+strlen(result), "%d: ", i+1);		// entry number (1-based)
			info(&h, result);			// display all info about the file
			sprintf(result+strlen(result), "\n--------\n");			// append extra
		} else {
			sprintf(result+strlen(result), "%d) %s\n", i+1, v->ptr[i]+H_NAME);		// display SIMPLIFIED list of contents
		}
	}

	return	0;
}

int		add(char* name, struct cont* v, bool verbose) {				// Add file to volume
	FILE*			file;
	byte			buffer[HD_BYTES];	// temporary header fits into a full page
	struct header	h;					// metadata storage
/* optional variables for timestamp fetching */
	struct tm*		stamp;
	struct stat		attrib;
/* ***************************************** */
	if (v->used >= MAXFILES) {
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
	if (getheader(buffer, &h)) {						// check header and get metadata
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
	if ((v->ptr[v->used] = malloc(h.size)) == NULL) {			// Allocate dynamic memory
		fclose(file);
		return OUT_MEMORY;								// out of memory error
	}
	if (verbose)				printf(", Header");
	memcpy(v->ptr[v->used], buffer, HD_BYTES);				// copy preloaded header
	if ((signature(&h) == SIG_ROM) && (h.size & 511)) {	// check for misaligned ROM images
		free(v->ptr[v->used]);
		v->ptr[v->used] = NULL;							// unlikely to be a problem, but...
		fclose(file);
		return MISALIGNED;								// ERROR -7: misaligned ROM image
	}
	if (verbose)
		if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf(", Code");
		else																printf(", Data");
	if (fread(v->ptr[v->used]+HD_BYTES, h.size-HD_BYTES, 1, file) != 1) {	// read remaining bytes after header (computed or preloaded)
		printf("\n [ READ ERROR! ]\n");
		free(v->ptr[v->used]);
		v->ptr[v->used] = NULL;				// eeeeek
	} else {
		if (verbose)		printf(" OK\n");
		v->used++;							// another file into volume
	}
	fclose(file);

	return	0;
}

int		extract(char* name, struct cont* v, bool verbose) {			// Extract file from volume
	int				i, ext, skip;
	struct header	h;
	FILE*			file;
	char			string[2000];		// local storage in case of verbose mode

	string[0] = '\0';
	if (!(v->used))		return EMPTY_VOL;						// empty volume error
	ext = choose(name);
	if (ext < 0)		return BAD_SELECT;						// ERROR -8: invalid selection
	getheader(v->ptr[ext], &h);									// get info for candidate
	if (verbose) {
		info(&h, string);
		printf("%s", string);
	}
	if (signature(&h) == SIG_FILE)		skip = HD_BYTES;		// generic files trim headers
	else								skip = 0;
	if (verbose)		printf("\nWriting to file %s... ", h.name);
	if ((file = fopen(h.name, "wb")) == NULL) {
		return NO_CREATE;										// ERROR -9: can't create file
	}
	if (fwrite(v->ptr[ext]+skip, h.size-skip, 1, file) != 1) {		// note header removal option
		if (verbose)	printf("\n [ I/O error ]\n");
	} else {
		if (verbose)	printf(" Done!\n");	// finish without padding
	}
	fclose(file);

	return	0;
}

int		rmfile(char* name, struct cont* v, bool verbose) {			// Delete file from volume
	int				i, del;
	struct header	h;
	char			string[2000];		// local storage in case of verbose mode

	string[0] = '\0';
	if (!(v->used))	return EMPTY_VOL;	// empty volume error
	del = choose(name);
	if (del < 0)	return BAD_SELECT;	// invalid selection error
	if (verbose) {
		getheader(v->ptr[del], &h);		// get info for candidate
		info(&h, string);				// display extended info
		printf("%s\n", string);
	}
	if (confirm("Will REMOVE this file from volume"))	return ABORTED;	// make sure or ERROR -10: aborted operation
	// If arrived here, proceed to removal
	free(v->ptr[del]);						// actual removal
	v->used--;								// one less file!
	for (i=del; i < v->used; i++)			ptr[i] = ptr[i+1];				// shift down all remainin entries after deleted one
	v->ptr[i] = NULL;						// extra safety!

	return	0;
}

int		setfree(int kb, struct param* p) {				// Select free space to be appended
	int		req;

	if (kb > 16384)		return FREE_ERR;		// ERROR -11: invalid free size
	req = kb << 2;						// times four
	req--;								// minus header page
	p->space = req;

	return	0;
}

int		generate(char* volume, struct cont* v, int space, bool verbose) {		// Generate volume
	const byte		pad = 0xFF;			// padding byte
	FILE*			file;
	byte			buffer[HD_BYTES];	// temporary header storage
	struct header	h;
	int				i, err;

//	if (!(v->used))		return EMPTY_VOL;		// empty volume error
	if (volume[0] != '\0')	printf("Writing to volume %s...", volume);
	if ((file = fopen(volume, "wb")) == NULL) {
		return NO_CREATE;						// error creating file
	}
	if (verbose)		printf(" OK\nLinking files...\n");
	for (i=0; i < v->used; i++) {
		err = 0;
		getheader(v->ptr[i], &h);					// info about file to be added
		if (verbose) {
			printf("%s: ", h.name);
			if ((signature(&h) == SIG_ROM) || (signature(&h) == SIG_POCKET))	printf("Code");
			else																printf("Data");
		}
		if (fwrite(v->ptr[i], h.size, 1, file) != 1) {				// attempt to write whole file
			printf("\n [ WRITE FAIL ]\n");
			err++;
		}
		if (h.size & 511) {						// non-multiple of 512 needs padding
			if (verbose)				printf(", Padding");
			while (h.size++ & 511) {							// pad with $FF until end of sector
				if (fwrite(&pad, 1, 1, file) != 1)	{
					printf("\n [ PADDING FAIL ]\n");
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
		h.size			= p->space << 8;
		makeheader(buffer, &h);					// create free space header
		if (fwrite(buffer, HD_BYTES, 1, file) != 1)	
			if (verbose)	printf("Error! ");	// hopefully with no errors!
		if (verbose)		printf("Appending... ");
		err = 0;
		for (i=HD_BYTES; i < (space<<8); i++)
			if (fwrite(&pad, 1, 1, file) != 1)	err++;	// hopefully with no errors!
		if (!err)	if (verbose)	printf("OK");
		else 		printf(" [ FAIL *** Do NOT use free space!! ]");
	}
//	for (i=0; i<HD_BYTES; i++)
//		fwrite(&pad, 1, 1, file);				// make best effort to add an invalid 'header' at the end
	fclose(file);
	printf("\nDone!\n");

	return 0;
}

int		getheader(byte* p, struct header* h) {			// Extract header specs, return BAD_HEAD if not valid
	static char	phasevec[4] = {'a', 'b', 'R', 'f'};
	int			src, dest;

	if ((p[H_MAGIC1] != 0) || (p[H_MAGIC2] != 13) || (p[H_MAGIC3] != 0))	return BAD_HEAD;	// invalid header
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

	return	0;				// header is valid
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

void	info(struct header* h, char* result) {					// Display info about header
	int		i;
	char*	pos;

	sprintf(result+strlen(result), "%s (%-5.2f KiB)", h->name, h->size/1024.0);			// Name and size
	sprintf(result+strlen(result), "\nType: ");
	pos	= result+strlen(result);
	switch(signature(h)) {
		case SIG_FREE:		// dL
			sprintf(pos, "* Free space *");							// should never be loaded!
			break;
		case SIG_ROM:		// dX
			sprintf(pos, "ROM image");
			break;
		case SIG_POCKET:	// pX
			sprintf(pos, "Pocket executable [LOAD:$%04X, EXEC:$%04X]", h->ld_addr, h->ex_addr);
			break;
		case SIG_FILE:		// dA
			sprintf(pos, "Generic file");
			break;
		case SIG_HIRES:		// dR
			sprintf(pos, "HIRES screen dump");
			break;
		case SIG_COLOUR:	// dS
			sprintf(pos, "Colour screen dump");
			break;
		case SIG_H_RLE:		// dr
			sprintf(pos, "RLE-compressed HIRES screen dump");
			break;
		case SIG_C_RLE:		// ds
			sprintf(pos, "RLE-compressed colour screen dump");
			break;
		default:
			sprintf(pos, "* UNKNOWN (%c%c) *", h->signature[0], h->signature[1]);
	}
	sprintf(result+strlen(result), "\nLast modified: %d/%d/%d, %02d:%02d", 1980+h->year, h->month, h->day, h->hour, h->minute);	// Last modified
	if (signature(h) != SIG_FILE) {
		sprintf(result+strlen(result), " (v%d.%d%c%d)", h->version, h->revision, h->phase, h->build);	// Version
		sprintf(result+strlen(result), "\nUser field #1: ");
		for (i=0; i<8; i++)		sprintf(result+strlen(result), "%c", h->commit[i]);						// Main commit string
		sprintf(result+strlen(result), ", #2: ");
		for (i=0; i<8; i++)		sprintf(result+strlen(result), "%c", h->lib[i]);						// Lib commit string
		if (h->comment[0] != '\0')		sprintf(result+strlen(result), "\nComment: %s", h->comment);	// optional comment
	}
}

int		choose(char* name, struct cont* v) {	// Locate file by name
	int		i;

	i = 0;						// try from first loaded file
	while (i < v->used) {		// do not look any further
		if (!strcmp(v->ptr[i]+H_NAME, name))	break;		// found file...
		i++;					// ... or try next
	}
	if (i >= v->used)				return	NO_FILE;

	return	i;					// make this 0-based...
}

int		confirm(char* msg, bool force) {	// Request confirmation for dangerous actions, returns ABORTED if rejected
	char	pass[80];

	if (force)	return 0;		// assume yes if -y

	printf("\t%s. Proceed? (Y/N) ", msg);
	scanf("%s", pass);			// just getting confirmation
	if ((pass[0]|32) != 'y') {	// either case
		return ABORTED;
	}

	return	0;					// if not aborted, proceed
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
		case BAD_HEAD:
			printf("BAD HEADER");
			break;
		default:
			printf("- - -UNKNOWN ERROR- - -");
	}
	printf(" ***\n\n");
}
